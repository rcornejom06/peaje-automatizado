from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from ..usuarios.permissions import obtener_rol_usuario
from .models import Notificacion
from .serializers import NotificacionSerializer


class NotificacionViewSet(viewsets.ModelViewSet):
    serializer_class = NotificacionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == "administrador":
            return Notificacion.objects.all().order_by("-fecha_hora")

        return Notificacion.objects.filter(
            usuario=self.request.user
        ).order_by("-fecha_hora")