from .models import CategoriaVehiculo, Vehiculo
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from .serializers import CategoriaVehiculoSerializer, VehiculoSerializer
from ..notificaciones.models import Notificacion
from ..notificaciones.services import crear_notificacion, notificar_administradores
from ..usuarios.permissions import obtener_rol_usuario
from ..auditoria.utils import registrar_historial
from django.utils import timezone
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser


class CategoriaVehiculoViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = CategoriaVehiculoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)
        if rol == 'administrador':
            return CategoriaVehiculo.objects.all().order_by("numero_ejes", "tarifa")
        return CategoriaVehiculo.objects.filter(estado=True).order_by("numero_ejes", "tarifa")


class VehiculoViewSet(viewsets.ModelViewSet):
    serializer_class = VehiculoSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)
        if rol in ['operador', 'administrador']:
            return Vehiculo.objects.all().order_by("placa")
        return Vehiculo.objects.filter(usuario=self.request.user).order_by("placa")

    def create(self, request, *args, **kwargs):
        rol = obtener_rol_usuario(request.user)

        if rol == "usuario":
            return Response(
                {
                    "error": "Use el endpoint /api/vehiculos/registrar-propio/ para registrar vehículos."
                },
                status=status.HTTP_405_METHOD_NOT_ALLOWED,
            )

        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        rol = obtener_rol_usuario(request.user)

        if rol == "usuario":
            return Response(
                {
                    "error": "Use el endpoint /api/vehiculos/<id>/actualizar-propio/ para actualizar su vehículo."
                },
                status=status.HTTP_405_METHOD_NOT_ALLOWED,
            )

        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        rol = obtener_rol_usuario(request.user)

        if rol == "usuario":
            return Response(
                {
                    "error": "Use el endpoint /api/vehiculos/<id>/actualizar-propio/ para actualizar su vehículo."
                },
                status=status.HTTP_405_METHOD_NOT_ALLOWED,
            )

        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        rol = obtener_rol_usuario(request.user)

        if rol != "administrador":
            return Response(
                {"error": "Solo el administrador puede eliminar vehículos."},
                status=status.HTTP_403_FORBIDDEN,
            )

        return super().destroy(request, *args, **kwargs)

    def perform_create(self, serializer):
        rol = obtener_rol_usuario(self.request.user)
        if rol == 'usuario':
            serializer.save(usuario=self.request.user)
        else:
            serializer.save()

    @action(detail=False, methods=["post"], url_path="registrar-propio")
    def registrar_propio(self, request):
        rol = obtener_rol_usuario(request.user)

        if rol != "usuario":
            return Response(
                {"error": "Solo los usuarios pueden registrar vehículos propios."},
                status=status.HTTP_403_FORBIDDEN,
            )

        placa = request.data.get("placa", "").strip().upper()
        marca = request.data.get("marca", "").strip()
        modelo = request.data.get("modelo", "").strip()
        color = request.data.get("color", "").strip()
        anio = request.data.get("anio")
        categoria_id = request.data.get("categoria")
        documento_respaldo = request.FILES.get("documento_respaldo")

        if not placa or not marca or not modelo or not categoria_id:
            return Response(
                {"error": "Debe completar placa, marca, modelo y categoría."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not documento_respaldo:
            return Response(
                {"error": "Debe adjuntar un documento de respaldo del vehículo."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if Vehiculo.objects.filter(placa=placa).exists():
            return Response(
                {"error": "Ya existe un vehículo con esa placa."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            categoria = CategoriaVehiculo.objects.get(
                id=categoria_id,
                estado=True,
            )
        except CategoriaVehiculo.DoesNotExist:
            return Response(
                {"error": "La categoría indicada no existe o no está activa."},
                status=status.HTTP_404_NOT_FOUND,
            )

        anio_valor = None

        if anio not in [None, ""]:
            try:
                anio_valor = int(anio)
            except ValueError:
                return Response(
                    {"error": "El año debe ser un número válido."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        vehiculo = Vehiculo.objects.create(
            usuario=request.user,
            placa=placa,
            marca=marca,
            categoria=categoria,
            modelo=modelo,
            color=color,
            anio=anio_valor,
            estado=Vehiculo.Estado.ACTIVO,
            estado_revision=Vehiculo.EstadoRevision.EN_REVISION,
            motivo_revision=None,
            fecha_revision=None,
            revisado_por=None,
            documento_respaldo=documento_respaldo,
        )

        registrar_historial(
            usuario=request.user,
            accion="Registro de vehículo",
            descripcion=f"El usuario registró el vehículo con placa {placa}.",
            modulo="Vehículos",
            request=request,
        )

        notificar_administradores(
            titulo="Nuevo vehículo registrado",
            mensaje=(
                f"El usuario {request.user.username} registró el vehículo "
                f"con placa {vehiculo.placa}."
            ),
            tipo=Notificacion.Tipo.SISTEMA,
            tipo_accion="vehiculos",
        )

        serializer = self.get_serializer(vehiculo)

        return Response(
            {
                "mensaje": "Vehículo registrado exitosamente. Queda en revisión hasta aprobación administrativa.",
                "vehiculo": serializer.data,
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["patch"], url_path="actualizar-propio")
    def actualizar_propio(self, request, pk=None):
        vehiculo = self.get_object()

        if vehiculo.usuario != request.user:
            return Response(
                {"error": "No tiene permisos para modificar este vehículo."},
                status=status.HTTP_403_FORBIDDEN
            )

        marca = request.data.get("marca")
        modelo = request.data.get("modelo")
        color = request.data.get("color")
        anio = request.data.get("anio")
        categoria_id = request.data.get("categoria")
        documento_respaldo = request.FILES.get("documento_respaldo")

        if marca is not None:
            vehiculo.marca = marca.strip()

        if modelo is not None:
            vehiculo.modelo = modelo.strip()

        if color is not None:
            vehiculo.color = color.strip()

        if anio is not None:
            try:
                vehiculo.anio = int(anio)
            except ValueError:
                return Response(
                    {"error": "El año debe ser un número válido."},
                    status=status.HTTP_400_BAD_REQUEST
                )

        if categoria_id is not None:
            try:
                categoria = CategoriaVehiculo.objects.get(
                    id=categoria_id,
                    estado=True
                )
                vehiculo.categoria = categoria
            except CategoriaVehiculo.DoesNotExist:
                return Response(
                    {"error": "La categoría indicada no existe o no está activa."},
                    status=status.HTTP_404_NOT_FOUND
                )

        if documento_respaldo:
            vehiculo.documento_respaldo = documento_respaldo

        vehiculo.estado_revision = Vehiculo.EstadoRevision.EN_REVISION
        vehiculo.motivo_revision = None
        vehiculo.fecha_revision = None
        vehiculo.revisado_por = None
        vehiculo.save()

        registrar_historial(
            usuario=request.user,
            accion="Actualización de vehículo",
            descripcion=f"El usuario actualizó el vehículo con placa {vehiculo.placa}. El vehículo volvió a revisión.",
            modulo="Vehículos",
            request=request,
        )

        serializer = self.get_serializer(vehiculo)

        return Response(
            {
                "mensaje": "Vehículo actualizado correctamente. Queda nuevamente en revisión administrativa.",
                "vehiculo": serializer.data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=False, methods=["get"], url_path="buscar-revision")
    def buscar_revision(self, request):
        rol = obtener_rol_usuario(request.user)

        if rol not in ["administrador", "operador"]:
            return Response(
                {"error": "No tiene permisos para revisar vehículos."},
                status=status.HTTP_403_FORBIDDEN
            )

        placa = request.query_params.get("placa")

        if not placa:
            return Response(
                {"error": "Debe enviar la placa."},
                status=status.HTTP_400_BAD_REQUEST
            )

        placa = placa.upper().replace("-", "").replace(" ", "").strip()

        vehiculo = Vehiculo.objects.select_related(
            "usuario",
            "categoria",
            "revisado_por"
        ).filter(
            placa__iexact=placa
        ).first()

        if not vehiculo:
            return Response(
                {"error": "No se encontró un vehículo con esa placa."},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = self.get_serializer(vehiculo)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=True, methods=["patch"], url_path="aprobar")
    def aprobar(self, request, pk=None):
        rol = obtener_rol_usuario(request.user)

        if rol not in ["administrador", "operador"]:
            return Response(
                {"error": "No tiene permisos para aprobar vehículos."},
                status=status.HTTP_403_FORBIDDEN
            )

        vehiculo = self.get_object()
        vehiculo.estado_revision = Vehiculo.EstadoRevision.APROBADO
        vehiculo.motivo_revision = request.data.get(
            "motivo_revision",
            "Vehículo aprobado por validación administrativa."
        )
        vehiculo.fecha_revision = timezone.now()
        vehiculo.revisado_por = request.user
        vehiculo.save()

        serializer = self.get_serializer(vehiculo)

        crear_notificacion(
            usuario=vehiculo.usuario,
            titulo="Vehículo aprobado",
            mensaje=f"Tu vehículo con placa {vehiculo.placa} fue aprobado correctamente.",
            tipo=Notificacion.Tipo.SISTEMA,
            tipo_accion="vehiculos",
        )

        return Response(
            {
                "mensaje": "Vehículo aprobado correctamente.",
                "vehiculo": serializer.data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=["patch"], url_path="rechazar")
    def rechazar(self, request, pk=None):
        rol = obtener_rol_usuario(request.user)

        if rol not in ["administrador", "operador"]:
            return Response(
                {"error": "No tiene permisos para rechazar vehículos."},
                status=status.HTTP_403_FORBIDDEN
            )

        motivo = request.data.get("motivo_revision")

        if not motivo:
            return Response(
                {"error": "Debe enviar el motivo del rechazo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        vehiculo = self.get_object()
        vehiculo.estado_revision = Vehiculo.EstadoRevision.RECHAZADO
        vehiculo.motivo_revision = motivo
        vehiculo.fecha_revision = timezone.now()
        vehiculo.revisado_por = request.user
        vehiculo.save()

        serializer = self.get_serializer(vehiculo)
        crear_notificacion(
            usuario=vehiculo.usuario,
            titulo="Vehículo rechazado",
            mensaje=(
                f"Tu vehículo con placa {vehiculo.placa} fue rechazado. "
                f"Revisa la información registrada."
            ),
            tipo=Notificacion.Tipo.SISTEMA,
            tipo_accion="vehiculos",
        )

        return Response(
            {
                "mensaje": "Vehículo rechazado correctamente.",
                "vehiculo": serializer.data,
            },
            status=status.HTTP_200_OK
        )

    @action(
        detail=True,
        methods=["patch"],
        url_path="cambiar-estado-revision",
        permission_classes=[IsAuthenticated],
    )
    def cambiar_estado_revision(self, request, pk=None):
        rol = obtener_rol_usuario(request.user)

        if rol not in ["administrador", "operador"]:
            return Response(
                {"error": "No tiene permisos para cambiar el estado de revisión."},
                status=status.HTTP_403_FORBIDDEN,
            )

        vehiculo = self.get_object()

        nuevo_estado = request.data.get("estado_revision")
        motivo = (
                request.data.get("motivo_revision")
                or request.data.get("observacion_revision")
                or ""
        ).strip()

        estados_validos = [
            Vehiculo.EstadoRevision.EN_REVISION,
            Vehiculo.EstadoRevision.APROBADO,
            Vehiculo.EstadoRevision.RECHAZADO,
        ]

        if nuevo_estado not in estados_validos:
            return Response(
                {
                    "error": "Estado de revisión inválido.",
                    "estados_validos": estados_validos,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if nuevo_estado == Vehiculo.EstadoRevision.RECHAZADO and not motivo:
            return Response(
                {"error": "Debe ingresar el motivo del rechazo."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if nuevo_estado == Vehiculo.EstadoRevision.APROBADO and not motivo:
            motivo = "Vehículo aprobado por validación administrativa."

        vehiculo.estado_revision = nuevo_estado
        vehiculo.motivo_revision = motivo
        vehiculo.fecha_revision = timezone.now()
        vehiculo.revisado_por = request.user

        if nuevo_estado == Vehiculo.EstadoRevision.APROBADO:
            if vehiculo.estado != Vehiculo.Estado.AVISO_ROBO:
                vehiculo.estado = Vehiculo.Estado.ACTIVO

        if nuevo_estado == Vehiculo.EstadoRevision.RECHAZADO:
            if vehiculo.estado != Vehiculo.Estado.AVISO_ROBO:
                vehiculo.estado = Vehiculo.Estado.INACTIVO

        vehiculo.save()

        if nuevo_estado == Vehiculo.EstadoRevision.APROBADO:
            crear_notificacion(
                usuario=vehiculo.usuario,
                titulo="Vehículo aprobado",
                mensaje=f"Tu vehículo con placa {vehiculo.placa} fue aprobado correctamente.",
                tipo=Notificacion.Tipo.SISTEMA,
                tipo_accion="vehiculos",
            )

        elif nuevo_estado == Vehiculo.EstadoRevision.RECHAZADO:
            crear_notificacion(
                usuario=vehiculo.usuario,
                titulo="Vehículo rechazado",
                mensaje=(
                    f"Tu vehículo con placa {vehiculo.placa} fue rechazado. "
                    f"Motivo: {motivo}"
                ),
                tipo=Notificacion.Tipo.SISTEMA,
                tipo_accion="vehiculos",
            )

        registrar_historial(
            usuario=request.user,
            accion="Cambio de estado de revisión de vehículo",
            descripcion=(
                f"Se cambió el estado de revisión del vehículo {vehiculo.placa} "
                f"a {nuevo_estado}."
            ),
            modulo="Vehículos",
            request=request,
        )

        serializer = self.get_serializer(vehiculo)

        return Response(
            {
                "mensaje": "Estado de revisión actualizado correctamente.",
                "vehiculo": serializer.data,
            },
            status=status.HTTP_200_OK,
        )
