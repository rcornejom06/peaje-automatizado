from rest_framework import serializers
from .models import DispositivoPush, Notificacion


class NotificacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notificacion
        fields = [
            "id",
            "usuario",
            "alerta",
            "titulo",
            "mensaje",
            "tipo",
            "leida",
            "fecha_hora",
            "url_accion",
            "tipo_accion",
        ]
        read_only_fields = [
            "id",
            "usuario",
            "fecha_hora",
        ]


class DispositivoPushSerializer(serializers.ModelSerializer):
    class Meta:
        model = DispositivoPush
        fields = ["token", "plataforma"]