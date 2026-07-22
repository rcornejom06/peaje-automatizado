from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from ..usuarios.permissions import obtener_rol_usuario
from .models import AvisoVehiculoRobado, AlertaSeguridad, UbicacionDeteccion, SolicitudReactivacionVehiculo
from .serializers import (AvisoVehiculoRobadoSerializer, AlertaSeguridadSerializer, UbicacionDeteccionSerializer,
                          SolicitudReactivacionVehiculoSerializer)
from ..vehiculos.models import Vehiculo
from django.utils import timezone
from ..notificaciones.models import Notificacion
from ..notificaciones.services import crear_notificacion, notificar_administradores
from ..peajes.models import Peaje, PasoPeaje
from ..auditoria.utils import registrar_historial
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser


class AvisoVehiculoRobadoViewSet(viewsets.ModelViewSet):
    serializer_class = AvisoVehiculoRobadoSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def create(self, request, *args, **kwargs):
        return Response(
            {
                "error": "Use el endpoint /api/seguridad/avisos-robo/crear-aviso/ para registrar avisos de robo."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar avisos directamente. Use las acciones cerrar o cancelar."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def partial_update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar avisos directamente. Use las acciones cerrar o cancelar."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def destroy(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite eliminar avisos de robo."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

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
            estado__in=[
                AvisoVehiculoRobado.Estado.ACTIVO,
                AvisoVehiculoRobado.Estado.DETECTADO,
            ]
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


class SolicitudReactivacionVehiculoViewSet(viewsets.ModelViewSet):
    serializer_class = SolicitudReactivacionVehiculoSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def create(self, request, *args, **kwargs):
        return Response(
            {
                "error": "Use el endpoint /api/seguridad/reactivaciones-vehiculo/solicitar/ para solicitar reactivación."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar solicitudes directamente. Use aprobar o rechazar."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def partial_update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar solicitudes directamente. Use aprobar o rechazar."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def destroy(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite eliminar solicitudes de reactivación."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        queryset = SolicitudReactivacionVehiculo.objects.select_related(
            "aviso",
            "vehiculo",
            "usuario",
            "revisado_por",
        ).order_by("-fecha_solicitud")

        if rol in ["administrador", "operador"]:
            return queryset

        return queryset.filter(usuario=self.request.user)

    @action(detail=False, methods=["post"], url_path="solicitar")
    def solicitar(self, request):
        rol = obtener_rol_usuario(request.user)

        if rol != "usuario":
            return Response(
                {"error": "Solo los usuarios pueden solicitar la reactivación de sus vehículos."},
                status=status.HTTP_403_FORBIDDEN,
            )

        vehiculo_id = request.data.get("vehiculo") or request.data.get("vehiculo_id")
        motivo = request.data.get("motivo", "").strip()

        documento_respaldo = None

        if hasattr(request, "FILES"):
            documento_respaldo = request.FILES.get("documento_respaldo")

        if not vehiculo_id:
            return Response(
                {"error": "Debe seleccionar el vehículo recuperado."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not motivo:
            return Response(
                {"error": "Debe ingresar el motivo o detalle de recuperación."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        vehiculo = Vehiculo.objects.filter(
            id=vehiculo_id,
            usuario=request.user,
        ).first()

        if not vehiculo:
            return Response(
                {"error": "No se encontró un vehículo asociado al usuario autenticado."},
                status=status.HTTP_404_NOT_FOUND,
            )

        if vehiculo.estado != Vehiculo.Estado.AVISO_ROBO:
            return Response(
                {
                    "error": "Este vehículo no se encuentra reportado como robado.",
                    "estado_actual": vehiculo.estado,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        aviso = AvisoVehiculoRobado.objects.filter(
            vehiculo=vehiculo,
            estado__in=[
                AvisoVehiculoRobado.Estado.ACTIVO,
                AvisoVehiculoRobado.Estado.DETECTADO,
            ],
        ).order_by("-fecha_aviso").first()

        if not aviso:
            return Response(
                {"error": "Este vehículo no tiene un aviso de robo activo o detectado."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        solicitud_pendiente = SolicitudReactivacionVehiculo.objects.filter(
            vehiculo=vehiculo,
            estado=SolicitudReactivacionVehiculo.Estado.PENDIENTE,
        ).first()

        if solicitud_pendiente:
            serializer = self.get_serializer(solicitud_pendiente)

            return Response(
                {
                    "error": "Ya existe una solicitud pendiente para este vehículo.",
                    "solicitud": serializer.data,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        datos_solicitud = {
            "aviso": aviso,
            "vehiculo": vehiculo,
            "usuario": request.user,
            "motivo": motivo,
        }

        if documento_respaldo:
            datos_solicitud["documento_respaldo"] = documento_respaldo

        solicitud = SolicitudReactivacionVehiculo.objects.create(
            **datos_solicitud
        )

        try:
            registrar_historial(
                usuario=request.user,
                accion="Solicitud de reactivación de vehículo",
                descripcion=(
                    f"El usuario solicitó reactivar el vehículo recuperado "
                    f"con placa {vehiculo.placa}."
                ),
                modulo="Seguridad",
                request=request,
            )
        except Exception:
            pass

        serializer = self.get_serializer(solicitud)

        return Response(
            {
                "mensaje": "Solicitud enviada correctamente. Queda pendiente de aprobación administrativa.",
                "solicitud": serializer.data,
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["patch"], url_path="aprobar")
    def aprobar(self, request, pk=None):
        rol = obtener_rol_usuario(request.user)

        if rol not in ["administrador", "operador"]:
            return Response(
                {"error": "No tiene permisos para aprobar solicitudes."},
                status=status.HTTP_403_FORBIDDEN
            )

        solicitud = self.get_object()

        if solicitud.estado != SolicitudReactivacionVehiculo.Estado.PENDIENTE:
            return Response(
                {"error": "Esta solicitud ya fue revisada."},
                status=status.HTTP_400_BAD_REQUEST
            )

        respuesta_admin = request.data.get(
            "respuesta_admin",
            "Solicitud aprobada. Vehículo recuperado y reactivado."
        )

        vehiculo = solicitud.vehiculo
        aviso = solicitud.aviso

        vehiculo.estado = Vehiculo.Estado.ACTIVO
        vehiculo.save(update_fields=["estado", "fecha_actualizacion"])

        aviso.estado = AvisoVehiculoRobado.Estado.RECUPERADO
        aviso.save(update_fields=["estado"])

        solicitud.estado = SolicitudReactivacionVehiculo.Estado.APROBADA
        solicitud.respuesta_admin = respuesta_admin
        solicitud.revisado_por = request.user
        solicitud.fecha_revision = timezone.now()
        solicitud.save()

        registrar_historial(
            usuario=request.user,
            accion="Aprobación de reactivación de vehículo",
            descripcion=f"El administrador aprobó la reactivación del vehículo {vehiculo.placa}.",
            modulo="Seguridad",
            request=request,
        )

        serializer = self.get_serializer(solicitud)

        return Response(
            {
                "mensaje": "Vehículo reactivado correctamente. Ya puede volver a generar cobros de peaje.",
                "solicitud": serializer.data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=["patch"], url_path="rechazar")
    def rechazar(self, request, pk=None):
        rol = obtener_rol_usuario(request.user)

        if rol not in ["administrador", "operador"]:
            return Response(
                {"error": "No tiene permisos para rechazar solicitudes."},
                status=status.HTTP_403_FORBIDDEN
            )

        solicitud = self.get_object()

        if solicitud.estado != SolicitudReactivacionVehiculo.Estado.PENDIENTE:
            return Response(
                {"error": "Esta solicitud ya fue revisada."},
                status=status.HTTP_400_BAD_REQUEST
            )

        respuesta_admin = request.data.get("respuesta_admin")

        if not respuesta_admin or not respuesta_admin.strip():
            return Response(
                {"error": "Debe ingresar el motivo del rechazo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        solicitud.estado = SolicitudReactivacionVehiculo.Estado.RECHAZADA
        solicitud.respuesta_admin = respuesta_admin.strip()
        solicitud.revisado_por = request.user
        solicitud.fecha_revision = timezone.now()
        solicitud.save()

        registrar_historial(
            usuario=request.user,
            accion="Rechazo de reactivación de vehículo",
            descripcion=f"El administrador rechazó la reactivación del vehículo {solicitud.vehiculo.placa}.",
            modulo="Seguridad",
            request=request,
        )

        serializer = self.get_serializer(solicitud)

        return Response(
            {
                "mensaje": "Solicitud rechazada correctamente.",
                "solicitud": serializer.data,
            },
            status=status.HTTP_200_OK
        )


class AlertaSeguridadViewSet(viewsets.ModelViewSet):
    serializer_class = AlertaSeguridadSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        return Response(
            {
                "error": "Use el endpoint /api/seguridad/alertas/generar-por-placa/ para generar alertas."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar alertas directamente. Use las acciones disponibles."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def partial_update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar alertas directamente. Use las acciones disponibles."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def destroy(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite eliminar alertas de seguridad."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

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

    def create(self, request, *args, **kwargs):
        return Response(
            {
                "error": "Use el endpoint /api/seguridad/ubicaciones/registrar-maps/ para registrar ubicaciones."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar ubicaciones directamente."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def partial_update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar ubicaciones directamente."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def destroy(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite eliminar ubicaciones de detección."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

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
