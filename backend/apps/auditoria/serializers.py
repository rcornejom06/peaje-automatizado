from rest_framework import serializers
from .models import HistorialUsuario


class HistorialUsuarioSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(source="usuario.username", read_only=True)

    class Meta:
        model = HistorialUsuario
        fields = "__all__"