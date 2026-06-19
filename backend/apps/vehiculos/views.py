from .models import CategoriaVehiculo
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Vehiculo
from .serializers import CategoriaVehiculoSerializer,VehiculoSerializer
from ..usuarios.permissions import obtener_rol_usuario
from ..auditoria.utils import registrar_historial

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

    @action(detail=False, methods=["post"], url_path="Registrar-propio")
    def registrar_propio(self, request, status=None):
        placa = request.data["placa"]
        marca = request.data["marca"]
        categoria_id = request.data.get("categoria")
        modelo = request.data["modelo"]
        color = request.data["color"]
        anio = request.data["anio"]

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
        vehiculo = Vehiculo.objects.create(
            usuario = request.user,
            placa=placa,
            marca=marca,
            categoria=categoria,
            modelo=modelo,
            color=color,
            anio=anio
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
            {"message": "Vehículo registrado exitosamente", "vehiculo": serializer.data},
            status=status.HTTP_201_CREATED
        )