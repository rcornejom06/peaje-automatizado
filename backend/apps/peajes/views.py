from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import Peaje, Camara, PasoPeaje
from .serializers import PeajeSerializer, CamaraSerializer, PasoPeajeSerializer


class PeajeViewSet(viewsets.ModelViewSet):
    queryset = Peaje.objects.all().order_by("nombre")
    serializer_class = PeajeSerializer
    permission_classes = [IsAuthenticated]


class CamaraViewSet(viewsets.ModelViewSet):
    queryset = Camara.objects.all().order_by("codigo")
    serializer_class = CamaraSerializer
    permission_classes = [IsAuthenticated]


class PasoPeajeViewSet(viewsets.ModelViewSet):
    queryset = PasoPeaje.objects.all().order_by("-fecha_hora")
    serializer_class = PasoPeajeSerializer
    permission_classes = [IsAuthenticated]