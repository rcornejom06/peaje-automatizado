from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import Vehiculo
from .serializers import VehiculoSerializer


class VehiculoViewSet(viewsets.ModelViewSet):
    queryset = Vehiculo.objects.all().order_by("placa")
    serializer_class = VehiculoSerializer
    permission_classes = [IsAuthenticated]