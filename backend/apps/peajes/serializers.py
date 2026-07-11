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



class ComprobantePasoPeajeSerializer(serializers.Serializer):
    id_paso = serializers.IntegerField()
    ticket = serializers.CharField()
    placa = serializers.CharField()
    peaje = serializers.CharField()
    carril = serializers.CharField()
    categoria = serializers.CharField()
    tipo_cliente = serializers.CharField()
    metodo_pago = serializers.CharField()
    valor = serializers.DecimalField(max_digits=10, decimal_places=2)
    fecha_generacion = serializers.DateTimeField()
    estado_pago = serializers.CharField()
    estado_seguridad = serializers.CharField()
    usuario = serializers.CharField()
    observacion = serializers.CharField()
    codigo_qr = serializers.CharField()