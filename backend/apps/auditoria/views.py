from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import HistorialUsuario
from .serializers import HistorialUsuarioSerializer


class HistorialUsuarioViewSet(viewsets.ModelViewSet):
    queryset = HistorialUsuario.objects.all().order_by("-fecha_hora")
    serializer_class = HistorialUsuarioSerializer
    permission_classes = [IsAuthenticated]