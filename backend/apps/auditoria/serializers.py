from rest_framework import serializers
from .models import HistorialUsuario


class HistorialUsuarioSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(
        source="usuario.username",
        read_only=True
    )

    usuario_nombre = serializers.SerializerMethodField()

    class Meta:
        model = HistorialUsuario
        fields = [
            "id",
            "usuario",
            "usuario_username",
            "usuario_nombre",
            "accion",
            "descripcion",
            "modulo",
            "direccion_ip",
            "dispositivo",
            "estado",
            "fecha_hora",
        ]
        read_only_fields = fields

    def get_usuario_nombre(self, obj):
        if not obj.usuario:
            return "Sistema"

        nombre_completo = obj.usuario.get_full_name()

        if nombre_completo:
            return nombre_completo

        return obj.usuario.username