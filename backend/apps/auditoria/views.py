from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from ..usuarios.permissions import obtener_rol_usuario
from .models import HistorialUsuario
from .serializers import HistorialUsuarioSerializer


class HistorialUsuarioViewSet(viewsets.ModelViewSet):
    serializer_class = HistorialUsuarioSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == "administrador":
            return HistorialUsuario.objects.all().order_by("-fecha_hora")

        return HistorialUsuario.objects.filter(
            usuario=self.request.user
        ).order_by("-fecha_hora")
