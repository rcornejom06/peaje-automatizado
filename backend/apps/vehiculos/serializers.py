from rest_framework import serializers
from .models import Vehiculo


class VehiculoSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(source="usuario.username", read_only=True)

    class Meta:
        model = Vehiculo
        fields = ["id","usuario","usuario_username","placa","marca","modelo","color","anio","estado","fecha_registro","fecha_actualizacion",]