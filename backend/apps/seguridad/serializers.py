from rest_framework import serializers
from .models import AvisoVehiculoRobado, AlertaSeguridad, UbicacionDeteccion


class AvisoVehiculoRobadoSerializer(serializers.ModelSerializer):
    vehiculo_placa = serializers.CharField(source="vehiculo.placa", read_only=True)

    class Meta:
        model = AvisoVehiculoRobado
        fields = "__all__"


class AlertaSeguridadSerializer(serializers.ModelSerializer):
    vehiculo_placa = serializers.CharField(source="vehiculo.placa", read_only=True)
    peaje_nombre = serializers.CharField(source="peaje.nombre", read_only=True)

    class Meta:
        model = AlertaSeguridad
        fields = "__all__"


class UbicacionDeteccionSerializer(serializers.ModelSerializer):
    peaje_nombre = serializers.CharField(source="peaje.nombre", read_only=True)

    class Meta:
        model = UbicacionDeteccion
        fields = "__all__"