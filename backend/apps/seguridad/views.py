from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from ..usuarios.permissions import obtener_rol_usuario
from .models import AvisoVehiculoRobado, AlertaSeguridad, UbicacionDeteccion
from .serializers import (AvisoVehiculoRobadoSerializer, AlertaSeguridadSerializer, UbicacionDeteccionSerializer, )
from ..vehiculos.models import Vehiculo
from ..notificaciones.models import Notificacion
from ..notificaciones.services import crear_notificacion, notificar_administradores
from ..peajes.models import Peaje, PasoPeaje
from ..auditoria.utils import registrar_historial
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser


class AvisoVehiculoRobadoViewSet(viewsets.ModelViewSet):
    serializer_class = AvisoVehiculoRobadoSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol in ["operador", "administrador"]:
            return AvisoVehiculoRobado.objects.all().order_by("-fecha_aviso")

        return AvisoVehiculoRobado.objects.filter(
            vehiculo__usuario=self.request.user
        ).order_by("-fecha_aviso")

    @action(detail=False, methods=["post"], url_path="crear-aviso")
    def crear_aviso(self, request, alerta=None, peaje=None, url_maps=None):
        vehiculo_id = request.data.get("vehiculo")
        placa = request.data.get("placa")
        rol = obtener_rol_usuario(self.request.user)

        numero_denuncia = request.data.get("numero_denuncia")
        entidad_denuncia = request.data.get("entidad_denuncia")
        fecha_denuncia = request.data.get("fecha_denuncia")
        lugar_robo = request.data.get("lugar_robo")
        descripcion = request.data.get("descripcion")
        latitud_robo = request.data.get("latitud_robo")
        longitud_robo = request.data.get("longitud_robo")

        documento_respaldo = request.FILES.get("documento_respaldo")

        vehiculo = None

        if rol != "usuario":
            return Response(
                {"error": "Solo los usuarios pueden crear avisos internos de vehículos robados."},
                status=status.HTTP_403_FORBIDDEN
            )

        if vehiculo_id:
            vehiculo = Vehiculo.objects.filter(
                id=vehiculo_id,
                usuario=request.user
            ).first()
        elif placa:
            vehiculo = Vehiculo.objects.filter(
                placa=placa.upper().strip(),
                usuario=request.user
            ).first()

        if not vehiculo:
            return Response(
                {
                    "error": "No se encontró un vehículo asociado al usuario autenticado."
                },
                status=status.HTTP_404_NOT_FOUND
            )

        aviso_activo = AvisoVehiculoRobado.objects.filter(
            vehiculo=vehiculo,
            estado=AvisoVehiculoRobado.Estado.ACTIVO
        ).first()

        if aviso_activo:
            return Response(
                {
                    "error": "Este vehículo ya tiene un aviso activo.",
                    "aviso": AvisoVehiculoRobadoSerializer(
                        aviso_activo,
                        context={"request": request}
                    ).data,
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if not documento_respaldo:
            return Response(
                {
                    "error": "Debe adjuntar el documento PDF de respaldo de la denuncia."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        nombre_archivo = documento_respaldo.name.lower()

        if not nombre_archivo.endswith(".pdf"):
            return Response(
                {
                    "error": "El documento de respaldo debe ser un archivo PDF."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if documento_respaldo.content_type not in [
            "application/pdf",
            "application/x-pdf",
            "application/octet-stream",
        ]:
            return Response(
                {
                    "error": "El archivo adjunto no tiene un formato PDF válido."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        max_size = 5 * 1024 * 1024

        if documento_respaldo.size > max_size:
            return Response(
                {
                    "error": "El PDF de respaldo no debe superar los 5 MB."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        aviso = AvisoVehiculoRobado.objects.create(
            vehiculo=vehiculo,
            numero_denuncia=numero_denuncia,
            entidad_denuncia=entidad_denuncia,
            fecha_denuncia=fecha_denuncia,
            lugar_robo=lugar_robo,
            descripcion=descripcion,
            latitud_robo=latitud_robo,
            longitud_robo=longitud_robo,
            documento_respaldo=documento_respaldo,
            estado=AvisoVehiculoRobado.Estado.ACTIVO,
        )

        vehiculo.estado = Vehiculo.Estado.AVISO_ROBO
        vehiculo.save()
        
        notificar_administradores(
            titulo="Nuevo aviso de vehículo robado",
            mensaje=f"El usuario {request.user.username} reportó como robado el vehículo {vehiculo.placa}.",
            tipo=Notificacion.Tipo.ALERTA,
            tipo_accion="seguridad",
        )

        crear_notificacion(
            usuario=vehiculo.usuario,
            alerta=alerta,
            titulo="Vehículo reportado detectado",
            mensaje=(
                f"Tu vehículo con placa {vehiculo.placa} fue detectado en "
                f"{peaje.nombre if peaje else 'un peaje registrado'}."
            ),
            tipo=Notificacion.Tipo.ALERTA,
            url_accion=url_maps,
            tipo_accion="mapa",
        )

        try:
            registrar_historial(
                usuario=request.user,
                accion="Aviso interno de vehículo robado",
                descripcion=(
                    f"El usuario registró un aviso interno para el vehículo "
                    f"{vehiculo.placa} con documento de respaldo PDF."
                ),
                modulo="Seguridad",
                request=request,
            )
        except Exception:
            pass

        return Response(
            {
                "mensaje": "Aviso interno de vehículo robado creado correctamente.",
                "aviso": AvisoVehiculoRobadoSerializer(
                    aviso,
                    context={"request": request}
                ).data,
            },
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=["patch"], url_path="cerrar")
    def cerrar(self, request, pk=None):
        aviso = self.get_object()
        rol = obtener_rol_usuario(request.user)

        if rol not in ["operador", "administrador"]:
            return Response(
                {"error": "Solo operadores o administradores pueden cerrar avisos."},
                status=status.HTTP_403_FORBIDDEN
            )

        if aviso.estado == AvisoVehiculoRobado.Estado.CERRADO:
            return Response(
                {"error": "El aviso ya se encuentra cerrado."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if aviso.estado == AvisoVehiculoRobado.Estado.CANCELADO:
            return Response(
                {"error": "No se puede cerrar un aviso cancelado."},
                status=status.HTTP_400_BAD_REQUEST
            )

        aviso.estado = AvisoVehiculoRobado.Estado.CERRADO
        aviso.save()

        vehiculo = aviso.vehiculo
        vehiculo.estado = Vehiculo.Estado.ACTIVO
        vehiculo.save()

        try:
            Notificacion.objects.create(
                usuario=aviso.vehiculo.usuario,
                titulo="Aviso de vehículo cerrado",
                mensaje=f"El aviso interno del vehículo {aviso.vehiculo.placa} fue cerrado.",
                tipo=Notificacion.Tipo.ALERTA,
            )
        except Exception:
            pass

        registrar_historial(
            usuario=request.user,
            accion="Cierre de alerta",
            descripcion=f"Se cerró la alerta del vehículo {aviso.vehiculo.placa}.",
            modulo="Seguridad",
            request=request,
        )

        return Response(
            {
                "mensaje": "Aviso cerrado correctamente.",
                "aviso": AvisoVehiculoRobadoSerializer(aviso).data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=["patch"], url_path="cancelar")
    def cancelar(self, request, pk=None):
        aviso = self.get_object()
        rol = obtener_rol_usuario(request.user)

        es_dueno = aviso.vehiculo.usuario == request.user

        if not es_dueno and rol != "administrador":
            return Response(
                {"error": "Solo el dueño del vehículo o un administrador puede cancelar el aviso."},
                status=status.HTTP_403_FORBIDDEN
            )

        if aviso.estado == AvisoVehiculoRobado.Estado.CERRADO:
            return Response(
                {"error": "No se puede cancelar un aviso cerrado."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if aviso.estado == AvisoVehiculoRobado.Estado.CANCELADO:
            return Response(
                {"error": "El aviso ya se encuentra cancelado."},
                status=status.HTTP_400_BAD_REQUEST
            )

        aviso.estado = AvisoVehiculoRobado.Estado.CANCELADO
        aviso.save()

        vehiculo = aviso.vehiculo
        vehiculo.estado = Vehiculo.Estado.ACTIVO
        vehiculo.save()

        try:
            Notificacion.objects.create(
                usuario=aviso.vehiculo.usuario,
                titulo="Aviso cancelado",
                mensaje=f"El aviso interno del vehículo {aviso.vehiculo.placa} fue cancelado.",
                tipo=Notificacion.Tipo.ALERTA,
            )
        except Exception:
            pass

        registrar_historial(
            usuario=request.user,
            accion="Cancelación de aviso de vehículo",
            descripcion=f"Se canceló el aviso interno del vehículo {aviso.vehiculo.placa}.",
            modulo="Seguridad",
            request=request,
        )

        return Response(
            {
                "mensaje": "Aviso cancelado correctamente.",
                "aviso": AvisoVehiculoRobadoSerializer(aviso).data,
            },
            status=status.HTTP_200_OK
        )


class AlertaSeguridadViewSet(viewsets.ModelViewSet):
    serializer_class = AlertaSeguridadSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol in ["operador", "administrador"]:
            return AlertaSeguridad.objects.all().order_by("-fecha_hora")

        return AlertaSeguridad.objects.filter(
            vehiculo__usuario=self.request.user
        ).order_by("-fecha_hora")

    @action(detail=False, methods=["post"], url_path="generar-por-placa")
    def generar_por_placa(self, request):
        placa = request.data.get("placa")
        peaje_id = request.data.get("peaje")
        paso_peaje_id = request.data.get("paso_peaje")
        rol = obtener_rol_usuario(request.user)

        if rol not in ["operador", "administrador"]:
            return Response(
                {"error": "Solo operadores o administradores pueden generar alertas por placa."},
                status=status.HTTP_403_FORBIDDEN
            )

        if not placa or not peaje_id:
            return Response(
                {"error": "Los campos placa y peaje son obligatorios."},
                status=status.HTTP_400_BAD_REQUEST
            )

        placa = placa.upper().strip()
        vehiculo = Vehiculo.objects.filter(placa=placa).first()

        if not vehiculo:
            return Response(
                {"error": "No existe un vehículo registrado con esa placa."},
                status=status.HTTP_404_NOT_FOUND
            )

        aviso = AvisoVehiculoRobado.objects.filter(
            vehiculo=vehiculo,
            estado=AvisoVehiculoRobado.Estado.ACTIVO
        ).first()

        if not aviso:
            return Response(
                {"mensaje": "La placa no tiene aviso activo. No se generó alerta."},
                status=status.HTTP_200_OK
            )

        try:
            peaje = Peaje.objects.get(id=peaje_id)
        except Peaje.DoesNotExist:
            return Response(
                {"error": "El peaje indicado no existe."},
                status=status.HTTP_404_NOT_FOUND
            )

        paso_peaje = None
        if paso_peaje_id:
            paso_peaje = PasoPeaje.objects.filter(id=paso_peaje_id).first()

        alerta = AlertaSeguridad.objects.create(
            aviso=aviso,
            vehiculo=vehiculo,
            peaje=peaje,
            paso_peaje=paso_peaje,
            tipo_alerta="Vehículo con aviso interno de robo",
            descripcion=f"La placa {placa} tiene un aviso activo y fue detectada en {peaje.nombre}.",
            estado=AlertaSeguridad.Estado.PENDIENTE,
            latitud_deteccion=peaje.latitud,
            longitud_deteccion=peaje.longitud,
        )

        maps_url = f"https://www.google.com/maps?q={peaje.latitud},{peaje.longitud}"

        ubicacion = UbicacionDeteccion.objects.create(
            alerta=alerta,
            peaje=peaje,
            latitud=peaje.latitud,
            longitud=peaje.longitud,
            direccion_referencial=peaje.ubicacion,
            url_maps=maps_url,
        )

        aviso.estado = AvisoVehiculoRobado.Estado.DETECTADO
        aviso.save()

        registrar_historial(
            usuario=request.user,
            accion="Generación de alerta por placa",
            descripcion=(
                f"Se generó una alerta para la placa {placa} "
                f"detectada en {peaje.nombre}."
            ),
            modulo="Seguridad",
            request=request,
        )

        return Response(
            {
                "mensaje": "Alerta generada correctamente.",
                "alerta": AlertaSeguridadSerializer(alerta).data,
                "ubicacion": UbicacionDeteccionSerializer(ubicacion).data,
                "url_maps": maps_url,
            },
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=["patch"], url_path="marcar-revisada")
    def marcar_revisada(self, request, pk=None):
        alerta = self.get_object()
        rol = obtener_rol_usuario(request.user)

        if rol not in ["operador", "administrador"]:
            return Response(
                {"error": "Solo operadores o administradores pueden revisar alertas."},
                status=status.HTTP_403_FORBIDDEN
            )

        if alerta.estado in [
            AlertaSeguridad.Estado.CERRADA,
            AlertaSeguridad.Estado.DESCARTADA,
        ]:
            return Response(
                {"error": "No se puede revisar una alerta cerrada o descartada."},
                status=status.HTTP_400_BAD_REQUEST
            )

        alerta.estado = AlertaSeguridad.Estado.REVISADA
        alerta.save()

        placa = alerta.vehiculo.placa if alerta.vehiculo else "Sin vehículo"

        registrar_historial(
            usuario=request.user,
            accion="Revisión de alerta",
            descripcion=(
                f"Se marcó como revisada la alerta ID {alerta.id}. "
                f"Vehículo: {placa}. "
                f"Peaje: {alerta.peaje if alerta.peaje else 'Sin peaje'}."
            ),
            modulo="Seguridad",
            request=request,
            dispositivo="Panel React",
        )

        return Response(
            {
                "mensaje": "Alerta marcada como revisada.",
                "alerta": AlertaSeguridadSerializer(alerta).data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=["patch"], url_path="derivar-autoridad")
    def derivar_autoridad(self, request, pk=None):
        alerta = self.get_object()
        rol = obtener_rol_usuario(request.user)

        if rol not in ["operador", "administrador"]:
            return Response(
                {"error": "Solo operadores o administradores pueden derivar alertas."},
                status=status.HTTP_403_FORBIDDEN
            )

        if alerta.estado in [
            AlertaSeguridad.Estado.CERRADA,
            AlertaSeguridad.Estado.DESCARTADA,
        ]:
            return Response(
                {"error": "No se puede derivar una alerta cerrada o descartada."},
                status=status.HTTP_400_BAD_REQUEST
            )

        alerta.estado = AlertaSeguridad.Estado.DERIVADA
        alerta.save()

        try:
            if alerta.vehiculo and alerta.vehiculo.usuario:
                Notificacion.objects.create(
                    usuario=alerta.vehiculo.usuario,
                    titulo="Alerta derivada a autoridad",
                    mensaje=(
                        f"La alerta del vehículo {alerta.vehiculo.placa} "
                        "fue derivada a la autoridad competente."
                    ),
                    tipo=Notificacion.Tipo.ALERTA,
                )
        except Exception:
            pass

        placa = alerta.vehiculo.placa if alerta.vehiculo else "Sin vehículo"

        registrar_historial(
            usuario=request.user,
            accion="Derivación de alerta",
            descripcion=(
                f"Se derivó a autoridad la alerta ID {alerta.id}. "
                f"Vehículo: {placa}. "
                f"Peaje: {alerta.peaje if alerta.peaje else 'Sin peaje'}."
            ),
            modulo="Seguridad",
            request=request,
            dispositivo="Panel React",
        )

        return Response(
            {
                "mensaje": "Alerta derivada correctamente.",
                "alerta": AlertaSeguridadSerializer(alerta).data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=["patch"], url_path="cerrar")
    def cerrar(self, request, pk=None):
        alerta = self.get_object()
        rol = obtener_rol_usuario(request.user)

        if rol not in ["operador", "administrador"]:
            return Response(
                {"error": "Solo operadores o administradores pueden cerrar alertas."},
                status=status.HTTP_403_FORBIDDEN
            )

        if alerta.estado == AlertaSeguridad.Estado.CERRADA:
            return Response(
                {"error": "La alerta ya se encuentra cerrada."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if alerta.estado == AlertaSeguridad.Estado.DESCARTADA:
            return Response(
                {"error": "No se puede cerrar una alerta descartada."},
                status=status.HTTP_400_BAD_REQUEST
            )

        alerta.estado = AlertaSeguridad.Estado.CERRADA
        alerta.save()

        placa = alerta.vehiculo.placa if alerta.vehiculo else "Sin vehículo"

        registrar_historial(
            usuario=request.user,
            accion="Cierre de alerta",
            descripcion=(
                f"Se cerró la alerta ID {alerta.id}. "
                f"Vehículo: {placa}. "
                f"Peaje: {alerta.peaje if alerta.peaje else 'Sin peaje'}."
            ),
            modulo="Seguridad",
            request=request,
            dispositivo="Panel React",
        )

        return Response(
            {
                "mensaje": "Alerta cerrada correctamente.",
                "alerta": AlertaSeguridadSerializer(alerta).data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=["patch"], url_path="descartar")
    def descartar(self, request, pk=None):
        alerta = self.get_object()
        rol = obtener_rol_usuario(request.user)

        if rol not in ["operador", "administrador"]:
            return Response(
                {"error": "Solo operadores o administradores pueden descartar alertas."},
                status=status.HTTP_403_FORBIDDEN
            )

        if alerta.estado == AlertaSeguridad.Estado.CERRADA:
            return Response(
                {"error": "No se puede descartar una alerta cerrada."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if alerta.estado == AlertaSeguridad.Estado.DESCARTADA:
            return Response(
                {"error": "La alerta ya se encuentra descartada."},
                status=status.HTTP_400_BAD_REQUEST
            )

        alerta.estado = AlertaSeguridad.Estado.DESCARTADA
        alerta.save()

        placa = alerta.vehiculo.placa if alerta.vehiculo else "Sin vehículo"

        registrar_historial(
            usuario=request.user,
            accion="Descarte de alerta",
            descripcion=(
                f"Se descartó la alerta ID {alerta.id}. "
                f"Vehículo: {placa}. "
                f"Peaje: {alerta.peaje if alerta.peaje else 'Sin peaje'}."
            ),
            modulo="Seguridad",
            request=request,
            dispositivo="Panel React",
        )

        return Response(
            {
                "mensaje": "Alerta descartada correctamente.",
                "alerta": AlertaSeguridadSerializer(alerta).data,
            },
            status=status.HTTP_200_OK
        )


class UbicacionDeteccionViewSet(viewsets.ModelViewSet):
    serializer_class = UbicacionDeteccionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol in ["operador", "administrador"]:
            return UbicacionDeteccion.objects.all().order_by("-fecha_hora")

        return UbicacionDeteccion.objects.filter(
            alerta__vehiculo__usuario=self.request.user
        ).order_by("-fecha_hora")

    @action(detail=False, methods=["post"], url_path="registrar-maps")
    def registrar_maps(self, request):
        alerta_id = request.data.get("alerta")
        rol = obtener_rol_usuario(self.request.user)

        if rol not in ["operador", "administrador"]:
            return Response(
                {"error": "Solo operadores o administradores pueden registrar ubicaciones."},
                status=status.HTTP_403_FORBIDDEN
            )

        if not alerta_id:
            return Response(
                {"error": "El campo alerta es obligatorio."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            alerta = AlertaSeguridad.objects.get(id=alerta_id)
        except AlertaSeguridad.DoesNotExist:
            return Response(
                {"error": "La alerta indicada no existe."},
                status=status.HTTP_404_NOT_FOUND
            )

        if hasattr(alerta, "ubicacion"):
            return Response(
                {
                    "mensaje": "La alerta ya tiene una ubicación registrada.",
                    "ubicacion": UbicacionDeteccionSerializer(alerta.ubicacion).data,
                },
                status=status.HTTP_200_OK
            )

        peaje = alerta.peaje
        maps_url = f"https://www.google.com/maps?q={peaje.latitud},{peaje.longitud}"

        ubicacion = UbicacionDeteccion.objects.create(
            alerta=alerta,
            peaje=peaje,
            latitud=peaje.latitud,
            longitud=peaje.longitud,
            direccion_referencial=peaje.ubicacion,
            url_maps=maps_url,
        )

        registrar_historial(
            usuario=request.user,
            accion="Registro de ubicación de detección",
            descripcion=(
                f"Se registró la ubicación de detección para la alerta "
                f"del vehículo {alerta.vehiculo.placa}."
            ),
            modulo="Seguridad",
            request=request,
        )

        return Response(
            {
                "mensaje": "Ubicación de detección registrada correctamente.",
                "ubicacion": UbicacionDeteccionSerializer(ubicacion).data,
                "url_maps": maps_url,
            },
            status=status.HTTP_201_CREATED
        )
