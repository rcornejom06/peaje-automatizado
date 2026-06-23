import os
import time
import logging
import platform
import atexit
from datetime import datetime
from threading import Lock, Thread
import re

import cv2
import numpy as np
import pytesseract
from flask import Flask, Response, jsonify, send_from_directory

# ==========================================================
# CONFIGURACIÓN GENERAL
# ==========================================================

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

pytesseract.pytesseract.tesseract_cmd = r"C:\Users\Roger.Cornejo\AppData\Local\Programs\Tesseract-OCR\tesseract.exe"

CAMERA_INDEX = int(os.environ.get("CAMERA_INDEX", "1"))

captura = None
capture_lock = Lock()

ultimo_frame = None
frame_lock = Lock()

capturando = False
capture_thread = None

ultima_deteccion = None
historial_detecciones = []

ultimo_ocr_lpr = 0
ultimo_registro_lpr = 0
ultima_placa_ocr = ""
DEBUG_GUARDAR_RECORTES = True
CARPETA_DEBUG_PLACAS = os.path.join(os.getcwd(), "debug_placas")
ultima_imagen_placa = None

os.makedirs(CARPETA_DEBUG_PLACAS, exist_ok=True)
lpr_lock = Lock()

# Variables para procesamiento asincrónico de OCR
frame_a_procesar = None
procesamiento_lock = Lock()


# ==========================================================
# CORS SIMPLE PARA REACT
# ==========================================================

@app.after_request
def agregar_headers_cors(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return response


# ==========================================================
# UTILIDADES DE CÁMARA
# ==========================================================

def obtener_backend_optimo():
    sistema = platform.system()

    if sistema == "Windows":
        return [
            ("DSHOW", cv2.CAP_DSHOW),
            ("MSMF", cv2.CAP_MSMF),
            ("ANY", cv2.CAP_ANY),
        ]

    return [("ANY", cv2.CAP_ANY)]


def detectar_camaras_disponibles():
    camaras_disponibles = []

    for indice in range(10):
        camara = None
        try:
            camara = cv2.VideoCapture(indice)

            if camara.isOpened():
                ret, frame = camara.read()

                if ret and frame is not None:
                    ancho = int(camara.get(cv2.CAP_PROP_FRAME_WIDTH))
                    alto = int(camara.get(cv2.CAP_PROP_FRAME_HEIGHT))
                    fps = int(camara.get(cv2.CAP_PROP_FPS))

                    camaras_disponibles.append({
                        "indice": indice,
                        "resolucion": f"{ancho}x{alto}",
                        "fps": fps
                    })

                    logger.info(
                        f"Cámara encontrada en índice {indice}: {ancho}x{alto} @ {fps} fps"
                    )

        except Exception as e:
            logger.warning(f"No se pudo probar cámara {indice}: {e}")

        finally:
            if camara is not None:
                camara.release()

    return camaras_disponibles


def abrir_camara():
    logger.info(f"Intentando abrir cámara con índice {CAMERA_INDEX}")

    for nombre_backend, backend in obtener_backend_optimo():
        camara = None

        try:
            logger.info(f"Probando backend {nombre_backend}")

            camara = cv2.VideoCapture(CAMERA_INDEX, backend)
            time.sleep(0.5)

            if not camara.isOpened():
                logger.warning(f"Backend {nombre_backend} no abrió la cámara")
                if camara is not None:
                    camara.release()
                continue

            ret, frame = camara.read()

            if not ret or frame is None:
                logger.warning(f"Backend {nombre_backend} abrió, pero no entregó frames")
                camara.release()
                continue

            camara.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
            camara.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
            camara.set(cv2.CAP_PROP_FPS, 30)

            ancho = int(camara.get(cv2.CAP_PROP_FRAME_WIDTH))
            alto = int(camara.get(cv2.CAP_PROP_FRAME_HEIGHT))
            fps = int(camara.get(cv2.CAP_PROP_FPS))

            logger.info(
                f"Cámara abierta correctamente con {nombre_backend}: {ancho}x{alto} @ {fps} fps"
            )

            return camara

        except Exception as e:
            logger.error(f"Error usando backend {nombre_backend}: {e}")
            if camara is not None:
                camara.release()

    logger.error(f"No se pudo abrir la cámara con índice {CAMERA_INDEX}")
    return None


def obtener_camara():
    global captura

    with capture_lock:
        if captura is not None and captura.isOpened():
            return captura

        captura = abrir_camara()
        return captura


def reiniciar_camara():
    global captura
    global ultimo_frame

    try:
        with capture_lock:
            if captura is not None:
                captura.release()
            captura = None

        with frame_lock:
            ultimo_frame = None

        logger.info("Cámara reiniciada correctamente")

    except Exception as e:
        logger.error(f"Error reiniciando cámara: {e}")


def liberar_camara():
    global captura
    global capturando

    capturando = False

    try:
        with capture_lock:
            if captura is not None:
                captura.release()
                captura = None
                logger.info("Cámara liberada correctamente")

    except Exception as e:
        logger.error(f"Error liberando cámara: {e}")


atexit.register(liberar_camara)


# ==========================================================
# HILO ÚNICO DE CAPTURA - OPTIMIZADO
# ==========================================================

def hilo_captura_camara():
    """
    Este hilo es el único que lee la cámara.
    Solo captura frames sin procesamiento pesado.
    """
    global ultimo_frame
    global capturando
    global frame_a_procesar

    camara = obtener_camara()

    if camara is None or not camara.isOpened():
        logger.error("No se pudo iniciar el hilo de captura: cámara no disponible")
        capturando = False
        return

    logger.info("Hilo de captura iniciado correctamente")
    errores = 0

    while capturando:
        try:
            with capture_lock:
                if captura is None or not captura.isOpened():
                    raise Exception("La cámara no está abierta")

                ret, frame = captura.read()

            if not ret or frame is None:
                errores += 1
                logger.warning(f"No se pudo leer frame en hilo de captura #{errores}")

                if errores >= 10:
                    logger.error("Reiniciando cámara desde hilo de captura")
                    reiniciar_camara()
                    obtener_camara()
                    errores = 0

                time.sleep(0.05)
                continue

            errores = 0

            # Actualizar frame para visualización
            with frame_lock:
                ultimo_frame = frame.copy()

            # Enviar frame para procesamiento asincrónico sin bloquear
            with procesamiento_lock:
                frame_a_procesar = frame.copy()

            time.sleep(0.01)  # ~100 fps lectura

        except Exception as e:
            logger.error(f"Error en hilo de captura: {type(e).__name__}: {e}")
            errores += 1

            if errores >= 10:
                reiniciar_camara()
                obtener_camara()
                errores = 0

            time.sleep(0.05)

    logger.info("Hilo de captura detenido")


# ==========================================================
# HILO DE PROCESAMIENTO OCR - SEPARADO
# ==========================================================

def hilo_procesamiento_ocr():
    """
    Hilo independiente que procesa OCR sin afectar el stream.
    """
    global frame_a_procesar
    global ultimo_ocr_lpr
    global ultimo_registro_lpr
    global ultima_placa_ocr

    logger.info("Hilo de procesamiento OCR iniciado")

    while capturando:
        try:
            frame_local = None

            with procesamiento_lock:
                if frame_a_procesar is not None:
                    frame_local = frame_a_procesar.copy()

            if frame_local is None:
                time.sleep(0.05)
                continue

            ahora = time.time()

            if ahora - ultimo_ocr_lpr >= 1.0:
                region = detectar_region_placa(frame_local)

                if region:
                    with lpr_lock:
                        texto_placa = leer_placa_ocr(frame_local, region)

                    ultimo_ocr_lpr = ahora

                    if texto_placa and placa_valida(texto_placa):
                        ultima_placa_ocr = texto_placa

                        if ahora - ultimo_registro_lpr >= 3.0:
                            confianza = calcular_confianza_placa(texto_placa)
                            registrar_deteccion(
                                placa=texto_placa,
                                confianza=confianza,
                                tipo="ocr_placa"
                            )
                            ultimo_registro_lpr = ahora

            time.sleep(0.02)

        except Exception as e:
            logger.error(f"Error en procesamiento OCR: {e}")
            time.sleep(0.05)

    logger.info("Hilo de procesamiento OCR detenido")


# ==========================================================
# DETECCIÓN Y OCR DE PLACAS
# ==========================================================

def limpiar_texto_placa(texto):
    if not texto:
        return ""

    texto = texto.upper()
    texto = texto.replace(" ", "").replace("-", "").replace("_", "").replace(".", "")
    texto = texto.replace(":", "").replace(";", "").replace("\n", "").replace("\r", "")
    texto = re.sub(r"[^A-Z0-9]", "", texto)

    return texto


def corregir_errores_comunes_ocr(texto):
    """
    Corrige errores comunes según el formato esperado ABC123 o ABC1234.
    """
    texto = limpiar_texto_placa(texto)

    if len(texto) < 5:
        return texto

    caracteres = list(texto)

    for i in range(min(3, len(caracteres))):
        if caracteres[i] == "0":
            caracteres[i] = "O"
        elif caracteres[i] == "1":
            caracteres[i] = "I"
        elif caracteres[i] == "5":
            caracteres[i] = "S"
        elif caracteres[i] == "8":
            caracteres[i] = "B"
        elif caracteres[i] == "2":
            caracteres[i] = "Z"

    for i in range(3, len(caracteres)):
        if caracteres[i] == "O":
            caracteres[i] = "0"
        elif caracteres[i] == "I":
            caracteres[i] = "1"
        elif caracteres[i] == "L":
            caracteres[i] = "1"
        elif caracteres[i] == "S":
            caracteres[i] = "5"
        elif caracteres[i] == "B":
            caracteres[i] = "8"
        elif caracteres[i] == "Z":
            caracteres[i] = "2"

    return "".join(caracteres)


def placa_valida(texto):
    texto = corregir_errores_comunes_ocr(texto)
    return bool(re.match(r"^[A-Z]{3}[0-9]{3,4}$", texto))


def calcular_confianza_placa(texto):
    texto = corregir_errores_comunes_ocr(texto)

    if re.match(r"^[A-Z]{3}[0-9]{4}$", texto):
        return 95
    if re.match(r"^[A-Z]{3}[0-9]{3}$", texto):
        return 90

    return 60


def registrar_deteccion(placa, confianza, tipo="ocr_placa"):
    global ultima_deteccion
    global historial_detecciones
    global ultima_imagen_placa

    placa = limpiar_texto_placa(placa)

    deteccion = {
        "placa": placa,
        "confianza": confianza,
        "tipo": tipo,
        "fecha_hora": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "estado_pago": "pendiente",
        "estado_vehiculo": "sin_novedades",
        "imagen_placa": ultima_imagen_placa
    }

    ultima_deteccion = deteccion
    historial_detecciones.append(deteccion)

    if len(historial_detecciones) > 50:
        historial_detecciones = historial_detecciones[-50:]

    logger.info(f"Placa detectada: {placa} ({confianza}%)")


def detectar_region_placa(frame):
    try:
        alto_frame, ancho_frame = frame.shape[:2]

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray = cv2.blur(gray, (3, 3))

        canny = cv2.Canny(gray, 80, 200)
        canny = cv2.dilate(canny, None, iterations=1)

        cnts, _ = cv2.findContours(
            canny,
            cv2.RETR_LIST,
            cv2.CHAIN_APPROX_SIMPLE
        )

        mejor_region = None
        mayor_puntaje = 0

        for c in cnts:
            area = cv2.contourArea(c)

            if area < 2500:
                continue

            x, y, w, h = cv2.boundingRect(c)

            if h == 0 or w == 0:
                continue

            aspect_ratio = float(w) / h

            if aspect_ratio < 2.0 or aspect_ratio > 6.8:
                continue

            if w < 90 or h < 25:
                continue

            if w > ancho_frame * 0.65 or h > alto_frame * 0.35:
                continue

            epsilon = 0.06 * cv2.arcLength(c, True)
            approx = cv2.approxPolyDP(c, epsilon, True)

            if len(approx) < 4:
                continue

            centro_x = x + w / 2
            centro_y = y + h / 2

            distancia_centro = abs(centro_x - ancho_frame / 2) + abs(centro_y - alto_frame / 2)

            puntaje = area * aspect_ratio - distancia_centro

            if puntaje > mayor_puntaje:
                mayor_puntaje = puntaje
                mejor_region = {
                    "x": x,
                    "y": y,
                    "w": w,
                    "h": h,
                    "area": area,
                    "aspect_ratio": aspect_ratio
                }

        return mejor_region

    except Exception as e:
        logger.error(f"Error detectando región de placa: {e}")
        return None


def guardar_recorte_debug(nombre, imagen):
    """
    Guarda imágenes de depuración para revisar qué está leyendo Tesseract.
    """
    if not DEBUG_GUARDAR_RECORTES:
        return None

    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        nombre_archivo = f"{timestamp}_{nombre}.jpg"
        ruta = os.path.join(CARPETA_DEBUG_PLACAS, nombre_archivo)

        cv2.imwrite(ruta, imagen)
        return nombre_archivo

    except Exception as e:
        logger.error(f"Error guardando recorte debug: {e}")
        return None


def leer_placa_ocr(frame, region):
    global ultima_imagen_placa

    try:
        x = region["x"]
        y = region["y"]
        w = region["w"]
        h = region["h"]

        alto_frame, ancho_frame = frame.shape[:2]

        margen_x = int(w * 0.08)
        margen_y = int(h * 0.18)

        x1 = max(x - margen_x, 0)
        y1 = max(y - margen_y, 0)
        x2 = min(x + w + margen_x, ancho_frame)
        y2 = min(y + h + margen_y, alto_frame)

        roi = frame[y1:y2, x1:x2]

        if roi is None or roi.size == 0:
            return ""

        archivo_original = guardar_recorte_debug("01_original", roi)

        if archivo_original:
            ultima_imagen_placa = f"/debug_placas/{archivo_original}"

        roi = cv2.resize(roi, None, fx=4, fy=4, interpolation=cv2.INTER_CUBIC)
        guardar_recorte_debug("02_ampliada", roi)

        gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
        gray = cv2.bilateralFilter(gray, 9, 75, 75)

        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        gray = clahe.apply(gray)

        guardar_recorte_debug("03_gris_contraste", gray)

        versiones = []
        versiones.append(("gris", gray))

        _, otsu = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        versiones.append(("otsu", otsu))
        guardar_recorte_debug("04_otsu", otsu)

        invertida = cv2.bitwise_not(otsu)
        versiones.append(("invertida", invertida))
        guardar_recorte_debug("05_invertida", invertida)

        adaptativa = cv2.adaptiveThreshold(
            gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 31, 5
        )
        versiones.append(("adaptativa", adaptativa))
        guardar_recorte_debug("06_adaptativa", adaptativa)

        configs = [
            "--oem 3 --psm 7 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
            "--oem 3 --psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
            "--oem 3 --psm 11 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
        ]

        candidatos = []

        for nombre_version, imagen in versiones:
            for config in configs:
                texto = pytesseract.image_to_string(imagen, config=config)
                texto_limpio = limpiar_texto_placa(texto)
                texto_corregido = corregir_errores_comunes_ocr(texto_limpio)

                if texto_limpio:
                    logger.info(
                        f"OCR [{nombre_version}] bruto: {repr(texto)} | "
                        f"limpio: {texto_limpio} | corregido: {texto_corregido}"
                    )

                if placa_valida(texto_corregido):
                    candidatos.append(texto_corregido)

        if not candidatos:
            return ""

        conteo = {}
        for candidato in candidatos:
            conteo[candidato] = conteo.get(candidato, 0) + 1

        mejor_texto = max(conteo, key=conteo.get)
        return mejor_texto

    except Exception as e:
        logger.error(f"Error OCR leyendo placa: {e}")
        return ""


def procesar_frame_para_visualizacion(frame):
    """
    Dibuja información sin hacer OCR pesado. El OCR se hace en otro hilo.
    """
    try:
        alto, ancho = frame.shape[:2]

        cv2.rectangle(frame, (15, 15), (310, 55), (0, 150, 0), -1)

        cv2.putText(
            frame,
            "SISTEMA LPR ACTIVO",
            (25, 45),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (255, 255, 255),
            2
        )

        cv2.putText(
            frame,
            datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            (20, alto - 25),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (255, 255, 255),
            2
        )

        region = detectar_region_placa(frame)

        if region:
            x = region["x"]
            y = region["y"]
            w = region["w"]
            h = region["h"]

            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 3)

            texto_mostrar = ultima_placa_ocr if ultima_placa_ocr else "ESCANEANDO..."

            cv2.putText(
                frame,
                texto_mostrar,
                (x, max(y - 10, 30)),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.9,
                (0, 255, 0),
                2
            )

        return frame

    except Exception as e:
        logger.error(f"Error procesando frame para visualización: {e}")
        return frame


# ==========================================================
# STREAM MJPEG
# ==========================================================

def crear_frame_mensaje(mensaje):
    frame = np.ones((480, 800, 3), dtype=np.uint8) * 255

    cv2.putText(
        frame,
        mensaje,
        (60, 240),
        cv2.FONT_HERSHEY_SIMPLEX,
        1,
        (0, 0, 0),
        2
    )

    ret, buffer = cv2.imencode(".jpg", frame)

    if not ret:
        return None

    return buffer.tobytes()


def generar_respuesta_frame(frame_bytes):
    return (
        b"--frame\r\n"
        b"Content-Type: image/jpeg\r\n"
        b"Content-Length: " + str(len(frame_bytes)).encode() + b"\r\n\r\n" +
        frame_bytes +
        b"\r\n"
    )


def generar_frames():
    iniciar_captura_si_no_existe()

    while True:
        try:
            with frame_lock:
                if ultimo_frame is None:
                    frame = None
                else:
                    frame = ultimo_frame.copy()

            if frame is None:
                frame_error = crear_frame_mensaje("ESPERANDO CAMARA")

                if frame_error:
                    yield generar_respuesta_frame(frame_error)

                time.sleep(0.1)
                continue

            # Solo dibuja información, OCR en otro hilo
            frame = procesar_frame_para_visualizacion(frame)

            ret_jpg, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 80])

            if not ret_jpg:
                logger.warning("No se pudo convertir frame a JPG")
                time.sleep(0.01)
                continue

            frame_bytes = buffer.tobytes()

            yield generar_respuesta_frame(frame_bytes)

            time.sleep(0.016)  # ~60 fps visualización

        except GeneratorExit:
            logger.info("Cliente desconectado del stream")
            break

        except Exception as e:
            logger.error(f"Error generando frame: {type(e).__name__}: {e}")
            time.sleep(0.05)


# ==========================================================
# MANEJO DE HILOS DE CAPTURA
# ==========================================================

def iniciar_captura_si_no_existe():
    global capturando
    global capture_thread

    if capturando and capture_thread is not None and capture_thread.is_alive():
        return

    capturando = True

    capture_thread = Thread(target=hilo_captura_camara, daemon=True)
    capture_thread.start()

    # Iniciar hilo de procesamiento OCR
    ocr_thread = Thread(target=hilo_procesamiento_ocr, daemon=True)
    ocr_thread.start()


# ==========================================================
# ENDPOINTS
# ==========================================================

@app.route("/")
def index():
    return jsonify({
        "mensaje": "Servidor de cámara USB activo",
        "camera_index_actual": CAMERA_INDEX,
        "endpoints": {
            "video_feed": "/video_feed",
            "health": "/health",
            "camaras": "/camaras",
            "last_detection": "/last_detection",
            "detections": "/detections",
            "reset_camera": "/reset_camera"
        }
    })


@app.route("/video_feed")
def video_feed():
    return Response(
        generar_frames(),
        mimetype="multipart/x-mixed-replace; boundary=frame"
    )


@app.route("/last_detection")
def last_detection():
    if ultima_deteccion is None:
        return jsonify({
            "detectado": False,
            "mensaje": "Esperando detección real de placa"
        })

    return jsonify({
        "detectado": True,
        "deteccion": ultima_deteccion
    })


@app.route("/detections")
def detections():
    return jsonify({
        "total": len(historial_detecciones),
        "detecciones": historial_detecciones[-10:]
    })


@app.route("/health")
def health():
    estado = "ok" if ultimo_frame is not None else "esperando_frame"

    return jsonify({
        "estado": estado,
        "camera_index": CAMERA_INDEX,
        "ultima_deteccion": ultima_deteccion,
        "capturando": capturando
    })


@app.route("/camaras")
def listar_camaras():
    camaras = detectar_camaras_disponibles()

    return jsonify({
        "total": len(camaras),
        "camaras_disponibles": camaras
    })


@app.route("/reset_camera")
def reset_camera():
    reiniciar_camara()

    return jsonify({
        "mensaje": "Cámara reiniciada correctamente"
    })


@app.route("/debug_placas")
def listar_debug_placas():
    try:
        archivos = [
            archivo for archivo in os.listdir(CARPETA_DEBUG_PLACAS)
            if archivo.lower().endswith((".jpg", ".jpeg", ".png"))
        ]

        archivos = sorted(archivos, reverse=True)[:30]

        return jsonify({
            "total": len(archivos),
            "archivos": [
                {
                    "nombre": archivo,
                    "url": f"/debug_placas/{archivo}"
                }
                for archivo in archivos
            ]
        })

    except Exception as e:
        logger.error(f"Error listando debug placas: {e}")
        return jsonify({
            "total": 0,
            "archivos": []
        })


@app.route("/debug_placas/<path:nombre_archivo>")
def ver_debug_placa(nombre_archivo):
    return send_from_directory(CARPETA_DEBUG_PLACAS, nombre_archivo)


# ==========================================================
# INICIO
# ==========================================================

if __name__ == "__main__":
    logger.info(f"Sistema operativo: {platform.system()}")
    logger.info(f"Índice de cámara configurado: {CAMERA_INDEX}")
    logger.info("Iniciando servidor Flask en puerto 5001")

    iniciar_captura_si_no_existe()

    app.run(
        host="0.0.0.0",
        port=5001,
        debug=False,
        threaded=True
    )