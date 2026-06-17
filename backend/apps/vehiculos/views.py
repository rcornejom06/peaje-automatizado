from importlib.metadata import pass_none

from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Vehiculo
from .serializers import VehiculoSerializer
from apps.auditoria.models import HistorialUsuario

class VehiculoViewSet(viewsets.ModelViewSet):
    queryset = Vehiculo.objects.all().order_by("placa")
    serializer_class = VehiculoSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["post"], url_path="Registrar-propio")
    def registrar_propio(self, request, status=None):
        placa = request.data["placa"]
        marca = request.data["marca"]
        modelo = request.data["modelo"]
        color = request.data["color"]
        anio = request.data["anio"]

        if not placa or not marca or not modelo:
            return Response({"error": "Faltan campos obligatorios"}, status=status.HTTP_400_BAD_REQUEST)

        placa = placa.upper().strip()

        if Vehiculo.objects.filter(placa=placa).exits():
            return Response({"error": "Ya existe un vehículo con esa placa"}, status=status.HTTP_400_BAD_REQUEST)

        vehiculo = Vehiculo.objects.create(
            usuario = request.user,
            placa=placa,
            marca=marca,
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