from .models import CategoriaVehiculo,Vehiculo
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from .serializers import CategoriaVehiculoSerializer,VehiculoSerializer
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
            return CategoriaVehiculo.objects.all().order_by("numero_ejes","tarifa")
        return CategoriaVehiculo.objects.filter(estado=True).order_by("numero_ejes","tarifa")


class VehiculoViewSet(viewsets.ModelViewSet):
    serializer_class = VehiculoSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]


    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)
        if rol in ['operador', 'administrador']:
            return Vehiculo.objects.all().order_by("placa")
        return Vehiculo.objects.filter(usuario=self.request.user).order_by("placa")

    def perform_create(self, serializer):
        rol = obtener_rol_usuario(self.request.user)
        if rol == 'usuario':
            serializer.save(usuario=self.request.user)
        else:
            serializer.save()

    @action(detail=False, methods=["post"], url_path="registrar-propio")
    def registrar_propio(self, request):
        placa = request.data["placa"]
        marca = request.data["marca"]
        categoria_id = request.data.get("categoria")
        modelo = request.data["modelo"]
        color = request.data["color"]
        anio = request.data["anio"]
        documento_respaldo = request.FILES.get("documento_respaldo")

        if not placa or not marca or not modelo or not categoria_id:
            return Response({"error": "Faltan campos obligatorios"}, status=status.HTTP_400_BAD_REQUEST)

        placa = placa.upper().strip()

        if Vehiculo.objects.filter(placa=placa).exists():
            return Response({"error": "Ya existe un vehículo con esa placa"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            categoria = CategoriaVehiculo.objects.get(id=categoria_id, estado=True)
        except CategoriaVehiculo.DoesNotExist:
            return Response(
                {"error": "La categoría indicada no existe o no está activa."},
                status=status.HTTP_404_NOT_FOUND
            )

        if not documento_respaldo:
            return Response(
                {"error": "Debe adjuntar un documento de respaldo del vehículo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        vehiculo = Vehiculo.objects.create(
            usuario = request.user,
            placa=placa,
            marca=marca,
            categoria=categoria,
            modelo=modelo,
            color=color,
            anio=anio,
            estado_revision=Vehiculo.EstadoRevision.EN_REVISION,
            documento_respaldo=documento_respaldo,
        )

        registrar_historial(
            usuario=request.user,
            accion="Registro de vehículo",
            descripcion=f"El usuario registró el vehículo con placa {placa}.",
            modulo="Vehículos",
            request=request,
        )

        serializer = self.get_serializer(vehiculo)

        return Response(
            {"message": "Vehículo registrado exitosamente. Queda en revisión hasta aprobación administrativa", "vehiculo": serializer.data},
            status=status.HTTP_201_CREATED
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

        return Response(
            {
                "mensaje": "Vehículo rechazado correctamente.",
                "vehiculo": serializer.data,
            },
            status=status.HTTP_200_OK
        )