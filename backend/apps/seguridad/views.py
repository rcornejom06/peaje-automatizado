from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import AvisoVehiculoRobado, AlertaSeguridad, UbicacionDeteccion
from .serializers import (
    AvisoVehiculoRobadoSerializer,
    AlertaSeguridadSerializer,
    UbicacionDeteccionSerializer,
)


class AvisoVehiculoRobadoViewSet(viewsets.ModelViewSet):
    queryset = AvisoVehiculoRobado.objects.all().order_by("-fecha_aviso")
    serializer_class = AvisoVehiculoRobadoSerializer
    permission_classes = [IsAuthenticated]


class AlertaSeguridadViewSet(viewsets.ModelViewSet):
    queryset = AlertaSeguridad.objects.all().order_by("-fecha_hora")
    serializer_class = AlertaSeguridadSerializer
    permission_classes = [IsAuthenticated]


class UbicacionDeteccionViewSet(viewsets.ModelViewSet):
    queryset = UbicacionDeteccion.objects.all().order_by("-fecha_hora")
    serializer_class = UbicacionDeteccionSerializer
    permission_classes = [IsAuthenticated]