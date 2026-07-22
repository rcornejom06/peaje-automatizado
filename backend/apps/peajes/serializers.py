from rest_framework import serializers
from .models import Peaje, Camara, PasoPeaje, TarifaPeajeCategoria, ViaConcesionada
from ..vehiculos.models import CategoriaVehiculo


class ViaConcesionadaSerializer(serializers.ModelSerializer):
    total_peajes = serializers.IntegerField(
        source="peajes.count",
        read_only=True
    )

    class Meta:
        model = ViaConcesionada
        fields = [
            "id",
            "nombre",
            "codigo",
            "descripcion",
            "tiempo_validez_minutos",
            "cobro_unico_por_trayecto",
            "estado",
            "total_peajes",
            "fecha_creacion",
            "fecha_actualizacion",
        ]
        read_only_fields = [
            "id",
            "total_peajes",
            "fecha_creacion",
            "fecha_actualizacion",
        ]

    def validate_codigo(self, value):
        return value.strip().upper()

    def validate_tiempo_validez_minutos(self, value):
        if value <= 0:
            raise serializers.ValidationError(
                "El tiempo de validez debe ser mayor a 0 minutos."
            )

        return value


class TarifaPeajeCategoriaSerializer(serializers.ModelSerializer):
    categoria_nombre = serializers.CharField(
        source="categoria.nombre",
        read_only=True
    )
    categoria_tipo = serializers.CharField(
        source="categoria.tipo",
        read_only=True
    )
    categoria_numero_ejes = serializers.IntegerField(
        source="categoria.numero_ejes",
        read_only=True
    )

    class Meta:
        model = TarifaPeajeCategoria
        fields = [
            "id",
            "peaje",
            "categoria",
            "categoria_nombre",
            "categoria_tipo",
            "categoria_numero_ejes",
            "valor",
            "estado",
            "fecha_creacion",
            "fecha_actualizacion",
        ]
        read_only_fields = [
            "id",
            "fecha_creacion",
            "fecha_actualizacion",
        ]


class TarifaPeajeCategoriaInputSerializer(serializers.Serializer):
    categoria = serializers.PrimaryKeyRelatedField(
        queryset=CategoriaVehiculo.objects.filter(estado=True)
    )
    valor = serializers.DecimalField(
        max_digits=8,
        decimal_places=2
    )
    estado = serializers.BooleanField(default=True)


class PeajeSerializer(serializers.ModelSerializer):
    tarifas_categoria = TarifaPeajeCategoriaSerializer(many=True, read_only=True)
    tarifas = TarifaPeajeCategoriaInputSerializer(many=True, write_only=True, required=False)
    via_concesionada_nombre = serializers.CharField(source="via_concesionada.nombre", read_only=True)
    via_concesionada_codigo = serializers.CharField(source="via_concesionada.codigo", read_only=True
                                                    )

    class Meta:
        model = Peaje
        fields = [
            "id",
            "nombre",
            "ciudad",
            "ubicacion",
            "latitud",
            "longitud",
            "tarifa",
            "via_concesionada",
            "via_concesionada_nombre",
            "via_concesionada_codigo",
            "orden_en_via",
            "estado",
            "fecha_creacion",
            "tarifas_categoria",
            "tarifas",

        ]
        read_only_fields = [
            "id",
            "fecha_creacion",
            "tarifas_categoria",
            "via_concesionada_nombre",
            "via_concesionada_codigo",
        ]

    def validate_tarifas(self, value):
        categorias = set()

        for tarifa in value:
            categoria = tarifa["categoria"]

            if categoria.id in categorias:
                raise serializers.ValidationError(
                    "No puede repetir la misma categoría en las tarifas del peaje."
                )

            categorias.add(categoria.id)

            if tarifa["valor"] <= 0:
                raise serializers.ValidationError(
                    "El valor de la tarifa debe ser mayor a 0."
                )

        return value

    def create(self, validated_data):
        tarifas_data = validated_data.pop("tarifas", [])

        peaje = Peaje.objects.create(**validated_data)

        self._guardar_tarifas(peaje, tarifas_data)

        return peaje

    def update(self, instance, validated_data):
        tarifas_data = validated_data.pop("tarifas", None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        instance.save()

        if tarifas_data is not None:
            self._guardar_tarifas(instance, tarifas_data)

        return instance

    def _guardar_tarifas(self, peaje, tarifas_data):
        for tarifa_data in tarifas_data:
            TarifaPeajeCategoria.objects.update_or_create(
                peaje=peaje,
                categoria=tarifa_data["categoria"],
                defaults={
                    "valor": tarifa_data["valor"],
                    "estado": tarifa_data.get("estado", True),
                }
            )


class CamaraSerializer(serializers.ModelSerializer):
    peaje_nombre = serializers.CharField(source="peaje.nombre", read_only=True)

    class Meta:
        model = Camara
        fields = "__all__"

    def validate(self, attrs):
        tipo_fuente = attrs.get(
            "tipo_fuente",
            getattr(self.instance, "tipo_fuente", Camara.TipoFuente.RTSP),
        )

        stream_url = attrs.get(
            "stream_url",
            getattr(self.instance, "stream_url", None),
        )

        if tipo_fuente == Camara.TipoFuente.USB:
            if stream_url in [None, ""]:
                attrs["stream_url"] = "0"
                return attrs

            try:
                int(str(stream_url))
            except ValueError:
                raise serializers.ValidationError(
                    {
                        "stream_url": "Para cámara USB debe ingresar un índice numérico, por ejemplo 0, 1 o 2."
                    }
                )

            return attrs

        if tipo_fuente in [
            Camara.TipoFuente.RTSP,
            Camara.TipoFuente.HTTP,
            Camara.TipoFuente.VIDEO,
        ]:
            if not stream_url:
                raise serializers.ValidationError(
                    {
                        "stream_url": "Debe ingresar la URL o ruta de la fuente de video."
                    }
                )

        return attrs


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
