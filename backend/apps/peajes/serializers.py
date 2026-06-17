from rest_framework import serializers
from .models import Peaje, Camara, PasoPeaje


class PeajeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Peaje
        fields = "__all__"


class CamaraSerializer(serializers.ModelSerializer):
    peaje_nombre = serializers.CharField(source="peaje.nombre", read_only=True)

    class Meta:
        model = Camara
        fields = "__all__"


class PasoPeajeSerializer(serializers.ModelSerializer):
    peaje_nombre = serializers.CharField(source="peaje.nombre", read_only=True)
    vehiculo_placa = serializers.CharField(source="vehiculo.placa", read_only=True)
    camara_codigo = serializers.CharField(source="camara.codigo", read_only=True)

    class Meta:
        model = PasoPeaje
        fields = "__all__"