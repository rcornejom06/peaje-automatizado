from datetime import timedelta
from decimal import Decimal
from django.http import StreamingHttpResponse
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from django.utils import timezone
from .models import Peaje, Camara, PasoPeaje
from .serializers import PeajeSerializer, CamaraSerializer, PasoPeajeSerializer
from ..usuarios.permissions import obtener_rol_usuario
from ..vehiculos.models import Vehiculo
from ..pagos.models import Transaccion, Billetera
from ..membresias.models import Membresia
from ..auditoria.utils import registrar_historial
from ..seguridad.models import AvisoVehiculoRobado, AlertaSeguridad, UbicacionDeteccion
from rest_framework_simplejwt.authentication import JWTAuthentication
import time
import cv2


def validar_token_stream(request):
    if request.user and request.user.is_authenticated:
        return True

    token = request.GET.get("token")

    if not token:
        return False

    try:
        request.META["HTTP_AUTHORIZATION"] = f"Bearer {token}"

        jwt_authenticator = JWTAuthentication()
        resultado = jwt_authenticator.authenticate(request)

        if resultado is None:
            print("JWTAuthentication no devolvió usuario")
            return False

        user, validated_token = resultado

        request.user = user
        request.auth = validated_token

        return True

    except Exception as e:
        print("Error validando token stream:", repr(e))
        return False


def obtener_fuente_camara(camara):
    """
    Convierte la fuente guardada en la cámara a un valor entendible por OpenCV.
    """

    if camara.tipo_fuente == "usb":
        try:
            return int(camara.stream_url or 0)
        except ValueError:
            return 0

    return camara.stream_url


def generar_frames_camara(captura):
    """
    Genera frames MJPEG para enviar al navegador.
    """

    try:
        while True:
            exito, frame = captura.read()

            if not exito:
                break

            exito_jpg, buffer = cv2.imencode(".jpg", frame)

            if not exito_jpg:
                continue

            frame_bytes = buffer.tobytes()

            yield (
                    b"--frame\r\n"
                    b"Content-Type: image/jpeg\r\n\r\n" +
                    frame_bytes +
                    b"\r\n"
            )

            time.sleep(0.03)

    finally:
        captura.release()


class PeajeViewSet(viewsets.ModelViewSet):
    serializer_class = PeajeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Peaje.objects.all().order_by("nombre")

    def create(self, request, *args, **kwargs):
        if obtener_rol_usuario(self.request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede crear peajes."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede actualizar peajes."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede eliminar peajes."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().destroy(request, *args, **kwargs)

    def procesar_pago_automatico(self, paso, vehiculo, tarifa_aplicada):

        if not vehiculo:
            paso.estado_pago = "pendiente"
            paso.observacion = (
                f"{paso.observacion or ''} Vehículo no registrado en el sistema."
            )
            paso.save()
            return {
                "estado_pago": paso.estado_pago,
                "metodo": "sin_vehiculo",
                "mensaje": "Vehículo no registrado. Paso queda pendiente."
            }

        usuario = vehiculo.usuario

        hoy = timezone.now().date()

        estado_activa = getattr(Membresia.Estado, "ACTIVA", "activa")

        membresia = Membresia.objects.filter(
            usuario=usuario,
            estado=estado_activa,
            fecha_inicio__lte=hoy,
            fecha_fin__gte=hoy,
            pases_restantes__gt=0
        ).order_by("-fecha_inicio").first()

        if membresia:
            membresia.consumir_pase()

            paso.estado_pago = "membresia"
            paso.membresia_utilizada = membresia
            paso.save()

            Transaccion.objects.create(
                billetera=getattr(usuario, "billetera", None),
                paso_peaje=paso,
                membresia=membresia,
                monto=Decimal("0.00"),
                tipo_transaccion=Transaccion.Tipo.USO_MEMBRESIA,
                metodo_pago="membresia",
                referencia_pago=f"MEMBRESIA-{membresia.id}-PASO-{paso.id}",
                estado="aprobada"
            )

            return {
                "estado_pago": paso.estado_pago,
                "metodo": "membresia",
                "mensaje": "Pago cubierto con membresía.",
                "membresia_id": membresia.id,
                "pases_restantes": membresia.pases_restantes
            }

        try:
            billetera = Billetera.objects.get(usuario=usuario)
        except Billetera.DoesNotExist:
            paso.estado_pago = "pendiente"
            paso.observacion = (
                f"{paso.observacion or ''} Usuario sin billetera activa."
            )
            paso.save()

            return {
                "estado_pago": paso.estado_pago,
                "metodo": "sin_billetera",
                "mensaje": "El usuario no tiene billetera. Paso queda pendiente."
            }

        if billetera.saldo >= tarifa_aplicada:
            billetera.saldo -= tarifa_aplicada
            billetera.save()

            paso.estado_pago = "pagado"
            paso.save()

            Transaccion.objects.create(
                billetera=billetera,
                paso_peaje=paso,
                monto=tarifa_aplicada,
                tipo_transaccion=Transaccion.Tipo.PAGO_PEAJE,
                metodo_pago="billetera",
                referencia_pago=f"BILLETERA-{billetera.id}-PASO-{paso.id}",
                estado="aprobada"
            )

            return {
                "estado_pago": paso.estado_pago,
                "metodo": "billetera",
                "mensaje": "Pago debitado correctamente de la billetera.",
                "saldo_restante": str(billetera.saldo)
            }

        paso.estado_pago = "pendiente"
        paso.observacion = (
            f"{paso.observacion or ''} Saldo insuficiente en billetera."
        )
        paso.save()

        Transaccion.objects.create(
            billetera=billetera,
            paso_peaje=paso,
            monto=tarifa_aplicada,
            tipo_transaccion=Transaccion.Tipo.PAGO_PEAJE,
            metodo_pago="billetera",
            referencia_pago=f"BILLETERA-{billetera.id}-PASO-{paso.id}-SALDO-INSUFICIENTE",
            estado="fallida"
        )

        return {
            "estado_pago": paso.estado_pago,
            "metodo": "saldo_insuficiente",
            "mensaje": "Saldo insuficiente. Paso queda pendiente.",
            "saldo_actual": str(billetera.saldo)
        }


class CamaraViewSet(viewsets.ModelViewSet):
    serializer_class = CamaraSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Camara.objects.all().order_by("codigo")

    @action(
        detail=True,
        methods=["get"],
        url_path="stream",
        permission_classes=[AllowAny]
    )
    @action(
        detail=True,
        methods=["get"],
        url_path="stream",
        permission_classes=[AllowAny]
    )
    def stream(self, request, pk=None):
        if not validar_token_stream(request):
            return Response(
                {"error": "Token no válido o no enviado."},
                status=401
            )

        source_url = request.GET.get("source_url")

        if source_url:
            fuente = source_url
        else:
            camara = self.get_object()

            if not camara.stream_url:
                return Response(
                    {"error": "La cámara no tiene una fuente de video configurada."},
                    status=400
                )

            fuente = obtener_fuente_camara(camara)

        captura = cv2.VideoCapture(fuente)

        if not captura.isOpened():
            captura.release()
            return Response(
                {
                    "error": "No se pudo abrir la cámara.",
                    "fuente": str(fuente),
                },
                status=400
            )

        return StreamingHttpResponse(
            generar_frames_camara(captura),
            content_type="multipart/x-mixed-replace; boundary=frame"
        )

    def create(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede crear cámaras."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede actualizar cámaras."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede eliminar cámaras."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().destroy(request, *args, **kwargs)


class PasoPeajeViewSet(viewsets.ModelViewSet):
    serializer_class = PasoPeajeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol in ["operador", "administrador"]:
            return PasoPeaje.objects.all().order_by("-fecha_hora")

        return PasoPeaje.objects.filter(
            vehiculo__usuario=self.request.user
        ).order_by("-fecha_hora")

    def procesar_pago_automatico(self, paso, vehiculo, tarifa_aplicada):

        if not vehiculo:
            paso.estado_pago = "pendiente"
            paso.observacion = (
                f"{paso.observacion or ''} Vehículo no registrado en el sistema."
            )
            paso.save()
            return {
                "estado_pago": paso.estado_pago,
                "metodo": "sin_vehiculo",
                "mensaje": "Vehículo no registrado. Paso queda pendiente."
            }

        usuario = vehiculo.usuario

        hoy = timezone.now().date()

        estado_activa = getattr(Membresia.Estado, "ACTIVA", "activa")

        membresia = Membresia.objects.filter(
            usuario=usuario,
            estado=estado_activa,
            fecha_inicio__lte=hoy,
            fecha_fin__gte=hoy,
            pases_restantes__gt=0
        ).order_by("-fecha_inicio").first()

        if membresia:
            membresia.consumir_pase()

            paso.estado_pago = "membresia"
            paso.membresia_utilizada = membresia
            paso.save()

            Transaccion.objects.create(
                billetera=getattr(usuario, "billetera", None),
                paso_peaje=paso,
                membresia=membresia,
                monto=Decimal("0.00"),
                tipo_transaccion=Transaccion.Tipo.USO_MEMBRESIA,
                metodo_pago="membresia",
                referencia_pago=f"MEMBRESIA-{membresia.id}-PASO-{paso.id}",
                estado="aprobada"
            )

            return {
                "estado_pago": paso.estado_pago,
                "metodo": "membresia",
                "mensaje": "Pago cubierto con membresía.",
                "membresia_id": membresia.id,
                "pases_restantes": membresia.pases_restantes
            }

        try:
            billetera = Billetera.objects.get(usuario=usuario)
        except Billetera.DoesNotExist:
            paso.estado_pago = "pendiente"
            paso.observacion = (
                f"{paso.observacion or ''} Usuario sin billetera activa."
            )
            paso.save()

            return {
                "estado_pago": paso.estado_pago,
                "metodo": "sin_billetera",
                "mensaje": "El usuario no tiene billetera. Paso queda pendiente."
            }

        if billetera.saldo >= tarifa_aplicada:
            billetera.saldo -= tarifa_aplicada
            billetera.save()

            paso.estado_pago = "pagado"
            paso.save()

            Transaccion.objects.create(
                billetera=billetera,
                paso_peaje=paso,
                monto=tarifa_aplicada,
                tipo_transaccion=Transaccion.Tipo.PAGO_PEAJE,
                metodo_pago="billetera",
                referencia_pago=f"BILLETERA-{billetera.id}-PASO-{paso.id}",
                estado="aprobada"
            )

            return {
                "estado_pago": paso.estado_pago,
                "metodo": "billetera",
                "mensaje": "Pago debitado correctamente de la billetera.",
                "saldo_restante": str(billetera.saldo)
            }

        paso.estado_pago = "pendiente"
        paso.observacion = (
            f"{paso.observacion or ''} Saldo insuficiente en billetera."
        )
        paso.save()

        Transaccion.objects.create(
            billetera=billetera,
            paso_peaje=paso,
            monto=tarifa_aplicada,
            tipo_transaccion=Transaccion.Tipo.PAGO_PEAJE,
            metodo_pago="billetera",
            referencia_pago=f"BILLETERA-{billetera.id}-PASO-{paso.id}-SALDO-INSUFICIENTE",
            estado="fallida"
        )

        return {
            "estado_pago": paso.estado_pago,
            "metodo": "saldo_insuficiente",
            "mensaje": "Saldo insuficiente. Paso queda pendiente.",
            "saldo_actual": str(billetera.saldo)
        }

    def procesar_seguridad_automatica(self, paso, vehiculo, peaje):
        """
        Revisa si el vehículo tiene un aviso activo de robo.
        Si existe, genera una alerta de seguridad y registra ubicación.
        """

        if not vehiculo:
            paso.estado_seguridad = "normal"
            paso.save()
            return {
                "estado_seguridad": paso.estado_seguridad,
                "alerta_generada": False,
                "mensaje": "Vehículo no registrado. No se puede validar aviso de robo."
            }

        aviso = AvisoVehiculoRobado.objects.filter(
            vehiculo=vehiculo,
            estado="activo"
        ).order_by("-fecha_aviso").first()

        if not aviso:
            paso.estado_seguridad = "normal"
            paso.save()
            return {
                "estado_seguridad": paso.estado_seguridad,
                "alerta_generada": False,
                "mensaje": "Vehículo sin avisos activos."
            }

        paso.estado_seguridad = "alerta"
        paso.save()

        alerta = AlertaSeguridad.objects.create(
            aviso=aviso,
            vehiculo=vehiculo,
            peaje=peaje,
            paso_peaje=paso,
            tipo_alerta="vehiculo_robado",
            descripcion=(
                f"Vehículo con aviso de robo activo detectado por LPR. "
                f"Placa: {paso.placa_detectada}. "
                f"Peaje: {peaje.nombre if peaje else 'No definido'}."
            ),
            latitud_deteccion=peaje.latitud if peaje else None,
            longitud_deteccion=peaje.longitud if peaje else None,
            estado="pendiente"
        )

        url_maps = None

        if peaje and peaje.latitud and peaje.longitud:
            url_maps = f"https://www.google.com/maps?q={peaje.latitud},{peaje.longitud}"

        UbicacionDeteccion.objects.create(
            alerta=alerta,
            peaje=peaje,
            latitud=peaje.latitud if peaje else None,
            longitud=peaje.longitud if peaje else None,
            direccion_referencial=peaje.ubicacion if peaje else "",
            url_maps=url_maps,
            fecha_hora=timezone.now()
        )

        aviso.estado = "detectado"
        aviso.save()

        registrar_historial(
            usuario=vehiculo.usuario if vehiculo else None,
            accion="Alerta automática por vehículo reportado",
            descripcion=(
                f"Se generó una alerta automática por vehículo con aviso activo. "
                f"Placa: {paso.placa_detectada}. "
                f"Peaje: {peaje.nombre if peaje else 'No definido'}. "
                f"Alerta ID: {alerta.id}."
            ),
            modulo="Seguridad",
            request=None,
            dispositivo="LPR"
        )


        return {
            "estado_seguridad": paso.estado_seguridad,
            "alerta_generada": True,
            "alerta_id": alerta.id,
            "aviso_id": aviso.id,
            "mensaje": "Vehículo con aviso activo detectado. Alerta generada.",
            "url_maps": url_maps
        }

    @action(
        detail=False,
        methods=["post"],
        url_path="detectar-placa"
    )
    def detectar_placa(self, request):
        placa_detectada = request.data.get("placa_detectada")
        camara_id = request.data.get("camara_id")
        confianza = request.data.get("confianza", 0)

        if not placa_detectada:
            return Response(
                {"error": "Debe enviar la placa_detectada."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not camara_id:
            return Response(
                {"error": "Debe enviar el camara_id."},
                status=status.HTTP_400_BAD_REQUEST
            )

        placa_detectada = (
            placa_detectada
            .upper()
            .replace("-", "")
            .replace(" ", "")
            .strip()
        )

        try:
            camara = Camara.objects.select_related("peaje").get(id=camara_id)
        except Camara.DoesNotExist:
            return Response(
                {"error": "La cámara no existe."},
                status=status.HTTP_404_NOT_FOUND
            )

        peaje = camara.peaje

        limite_tiempo = timezone.now() - timedelta(minutes=2)

        paso_reciente = PasoPeaje.objects.filter(
            placa_detectada=placa_detectada,
            camara=camara,
            fecha_hora__gte=limite_tiempo
        ).order_by("-fecha_hora").first()

        if paso_reciente:
            return Response(
                {
                    "mensaje": "Placa detectada recientemente. No se registra duplicado.",
                    "duplicado": True,
                    "paso_id": paso_reciente.id,
                    "placa_detectada": placa_detectada,
                    "fecha_hora": paso_reciente.fecha_hora,
                    "estado_pago": paso_reciente.estado_pago,
                    "estado_seguridad": paso_reciente.estado_seguridad,
                    "tarifa_aplicada": str(paso_reciente.tarifa_aplicada),
                    "vehiculo_encontrado": paso_reciente.vehiculo is not None,
                    "peaje": peaje.nombre if peaje else None,
                    "camara": camara.codigo,
                    "seguridad": {
                        "estado_seguridad": paso_reciente.estado_seguridad,
                        "alerta_generada": paso_reciente.estado_seguridad == "alerta",
                        "mensaje": "Registro duplicado. Se devuelve el paso reciente."
                    }
                },
                status=status.HTTP_200_OK
            )

        vehiculo = Vehiculo.objects.filter(
            placa__iexact=placa_detectada
        ).select_related("usuario", "categoria").first()

        tarifa_aplicada = Decimal("0.00")

        if vehiculo and vehiculo.categoria:
            tarifa_aplicada = vehiculo.categoria.tarifa
        elif peaje and peaje.tarifa:
            tarifa_aplicada = peaje.tarifa

        paso = PasoPeaje.objects.create(
            vehiculo=vehiculo,
            peaje=peaje,
            camara=camara,
            placa_detectada=placa_detectada,
            estado_pago="pendiente",
            estado_seguridad="normal",
            tarifa_aplicada=tarifa_aplicada,
            observacion=f"Detección automática LPR. Confianza OCR: {confianza}%"
        )

        resultado_pago = self.procesar_pago_automatico(
            paso=paso,
            vehiculo=vehiculo,
            tarifa_aplicada=tarifa_aplicada
        )

        resultado_seguridad = self.procesar_seguridad_automatica(
            paso=paso,
            vehiculo=vehiculo,
            peaje=peaje
        )

        paso.refresh_from_db()

        registrar_historial(
            usuario=request.user,
            accion="Registro automático de paso de peaje",
            descripcion=(
                f"Se registró un paso de peaje desde LPR. "
                f"Placa: {placa_detectada}. "
                f"Peaje: {peaje.nombre if peaje else 'No definido'}. "
                f"Estado pago: {paso.estado_pago}. "
                f"Estado seguridad: {paso.estado_seguridad}."
            ),
            modulo="Peajes",
            request=request,
            dispositivo="LPR"
        )

        return Response(
            {
                "mensaje": "Paso de peaje registrado desde LPR.",
                "duplicado": False,
                "paso_id": paso.id,
                "placa_detectada": placa_detectada,
                "vehiculo_encontrado": vehiculo is not None,
                "peaje": peaje.nombre if peaje else None,
                "camara": camara.codigo,
                "tarifa_aplicada": str(tarifa_aplicada),
                "estado_pago": paso.estado_pago,
                "estado_seguridad": paso.estado_seguridad,
                "pago": resultado_pago,
                "seguridad": resultado_seguridad,
            },
            status=status.HTTP_201_CREATED
        )

