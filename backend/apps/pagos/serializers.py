from rest_framework import serializers
from .models import Billetera, Transaccion


class BilleteraSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(source="usuario.username", read_only=True)

    class Meta:
        model = Billetera
        fields = "__all__"


class TransaccionSerializer(serializers.ModelSerializer):
    usuario = serializers.CharField(source="billetera.usuario.username", read_only=True)

    class Meta:
        model = Transaccion
        fields = "__all__"