from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import Notificacion
from .serializers import NotificacionSerializer


class NotificacionViewSet(viewsets.ModelViewSet):
    queryset = Notificacion.objects.all().order_by("-fecha_hora")
    serializer_class = NotificacionSerializer
    permission_classes = [IsAuthenticated]