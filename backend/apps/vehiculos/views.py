from importlib.metadata import pass_none
from .models import CategoriaVehiculo
from rest_framework import status,viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Vehiculo
from .serializers import CategoriaVehiculoSerializer,VehiculoSerializer
from apps.auditoria.models import HistorialUsuario


class CategoriaVehiculoViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CategoriaVehiculo.objects.filter(estado=True).order_by("numero_ejes", "tarifa")
    serializer_class = CategoriaVehiculoSerializer
    permission_classes = [IsAuthenticated]



class VehiculoViewSet(viewsets.ModelViewSet):
    queryset = Vehiculo.objects.all().order_by("placa")
    serializer_class = VehiculoSerializer
    permission_classes = [IsAuthenticated]

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

        if Vehiculo.objects.filter(placa=placa).exits():
            return Response({"error": "Ya existe un vehículo con esa placa"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            categoria = CategoriaVehiculo.objects.get(id=categoria_id, estado=true)
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

        try:
            HistorialUsuario.objects.create(
                usuario = request.user,
                accion = f"Registró su propio vehículo: {vehiculo.placa}",
                descripcion = f"El usuario {request.user.username} registró su propio vehículo con placa {vehiculo.placa}.",
                modulo="Vehículos",
                dispositivo="API",
                estado=HistorialUsuario.Estado.EXITOSO
            )
        except Exception as e:
            pass
        serializer = self.get_serializer(vehiculo)

        return Response(
            {"message": "Vehículo registrado exitosamente", "vehiculo": serializer.data},
            status=status.HTTP_201_CREATED
        )