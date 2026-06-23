import cv2
import pytesseract

# Ruta correcta de Tesseract
pytesseract.pytesseract.tesseract_cmd = r"C:\Users\Roger.Cornejo\AppData\Local\Programs\Tesseract-OCR\tesseract.exe"

# Abrir cámara USB
# Si no funciona con 0, prueba con 1 o 2
cap = cv2.VideoCapture(1, cv2.CAP_DSHOW)

if not cap.isOpened():
    print("Error: no se pudo abrir la cámara USB.")
    exit()

while True:
    ret, image = cap.read()

    if not ret:
        print("Error: no se pudo capturar el frame.")
        break

    # Copia para mostrar resultados
    frame_resultado = image.copy()

    # Procesamiento
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    gray = cv2.blur(gray, (3, 3))
    canny = cv2.Canny(gray, 150, 200)
    canny = cv2.dilate(canny, None, iterations=1)

    cnts, _ = cv2.findContours(canny, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)

    for c in cnts:
        area = cv2.contourArea(c)
        x, y, w, h = cv2.boundingRect(c)
        epsilon = 0.09 * cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, epsilon, True)

        if len(approx) == 4 and area > 9000:
            aspect_ratio = float(w) / h

            if aspect_ratio > 2.4:
                placa = gray[y:y + h, x:x + w]

                # OCR
                text = pytesseract.image_to_string(placa, config='--psm 11')
                text = text.strip()

                print("PLACA:", text)

                # Mostrar la región detectada
                cv2.imshow('PLACA', placa)
                cv2.moveWindow('PLACA', 780, 10)

                # Dibujar rectángulo y texto en el frame
                cv2.rectangle(frame_resultado, (x, y), (x + w, y + h), (0, 255, 0), 3)
                cv2.putText(frame_resultado, text, (x, y - 10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

    # Mostrar ventanas
    cv2.imshow('Image', frame_resultado)
    cv2.moveWindow('Image', 45, 10)

    cv2.imshow('Canny', canny)

    # Salir con la tecla q
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()