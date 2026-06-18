from rest_framework import serializers
from .models import CategoriaVehiculo,Vehiculo


class CategoriaVehiculoSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategoriaVehiculo
        fields = "__all__"


class VehiculoSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(source="usuario.username", read_only=True)
    categoria_nombre = serializers.CharField(source="categoria.nombre", read_only=True)
    categoria_tarifa = serializers.DecimalField(source="categoria.tarifa", max_digits=8, decimal_places=2, read_only=True)

    class Meta:
        model = Vehiculo
        fields = ["id","usuario","usuario_username","categoria","categoria_nombre","categoria_tarifa","placa","marca","modelo","color","anio","estado","fecha_registro","fecha_actualizacion",]