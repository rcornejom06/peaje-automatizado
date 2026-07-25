from rest_framework import serializers
from .models import AvisoVehiculoRobado, AlertaSeguridad, UbicacionDeteccion, SolicitudReactivacionVehiculo


class AvisoVehiculoRobadoSerializer(serializers.ModelSerializer):
    vehiculo_placa = serializers.CharField(
        source="vehiculo.placa",
        read_only=True
    )

    usuario_username = serializers.CharField(
        source="vehiculo.usuario.username",
        read_only=True
    )

    documento_respaldo_url = serializers.SerializerMethodField()

    class Meta:
        model = AvisoVehiculoRobado
        fields = ["id", "vehiculo",
                  "vehiculo_placa",
                  "usuario_username",
                  "numero_denuncia",
                  "entidad_denuncia",
                  "fecha_denuncia",
                  "fecha_aviso",
                  "lugar_robo",
                  "descripcion",
                  "latitud_robo",
                  "longitud_robo",
                  "documento_respaldo",
                  "documento_respaldo_url",
                  "estado",
                  ]

        read_only_fields = [
            "id",
            "fecha_aviso",
            "documento_respaldo_url",
        ]

    def get_documento_respaldo_url(self, obj):
        request = self.context.get("request")

        if not obj.documento_respaldo:
            return None

        if request:
            return request.build_absolute_uri(obj.documento_respaldo.url)

        return obj.documento_respaldo.url


class SolicitudReactivacionVehiculoSerializer(serializers.ModelSerializer):
    placa = serializers.CharField(
        source="vehiculo.placa",
        read_only=True
    )
    usuario_username = serializers.CharField(
        source="usuario.username",
        read_only=True
    )
    aviso_estado = serializers.CharField(
        source="aviso.estado",
        read_only=True
    )
    documento_respaldo_url = serializers.SerializerMethodField()

    class Meta:
        model = SolicitudReactivacionVehiculo
        fields = [
            "id",
            "aviso",
            "vehiculo",
            "placa",
            "usuario",
            "usuario_username",
            "motivo",
            "documento_respaldo",
            "documento_respaldo_url",
            "estado",
            "respuesta_admin",
            "revisado_por",
            "fecha_solicitud",
            "fecha_revision",
            "aviso_estado",
        ]
        read_only_fields = [
            "id",
            "aviso",
            "vehiculo",
            "usuario",
            "usuario_username",
            "estado",
            "respuesta_admin",
            "revisado_por",
            "fecha_solicitud",
            "fecha_revision",
            "aviso_estado",
            "documento_respaldo_url",
        ]

    def get_documento_respaldo_url(self, obj):
        if not obj.documento_respaldo:
            return None

        url = obj.documento_respaldo.url
        request = self.context.get("request")

        if request:
            return request.build_absolute_uri(url)

        return url


class UbicacionDeteccionSerializer(serializers.ModelSerializer):
    peaje_nombre = serializers.CharField(
        source="peaje.nombre",
        read_only=True
    )

    class Meta:
        model = UbicacionDeteccion
        fields = [
            "id",
            "alerta",
            "peaje",
            "peaje_nombre",
            "latitud",
            "longitud",
            "direccion_referencial",
            "url_maps",
            "fecha_hora",
        ]


class AlertaSeguridadSerializer(serializers.ModelSerializer):
    vehiculo_placa = serializers.CharField(
        source="vehiculo.placa",
        read_only=True
    )

    peaje_nombre = serializers.CharField(
        source="peaje.nombre",
        read_only=True
    )

    aviso_detalle = AvisoVehiculoRobadoSerializer(
        source="aviso",
        read_only=True
    )

    ubicacion_detalle = serializers.SerializerMethodField()
    url_maps = serializers.SerializerMethodField()
    documento_respaldo_url = serializers.SerializerMethodField()

    class Meta:
        model = AlertaSeguridad
        fields = [
            "id",
            "aviso",
            "aviso_detalle",
            "vehiculo",
            "vehiculo_placa",
            "peaje",
            "peaje_nombre",
            "paso_peaje",
            "tipo_alerta",
            "descripcion",
            "fecha_hora",
            "estado",
            "latitud_deteccion",
            "longitud_deteccion",
            "ubicacion_detalle",
            "url_maps",
            "documento_respaldo_url",
        ]

    def get_ubicacion_detalle(self, obj):
        ubicacion = getattr(obj, "ubicacion", None)

        if not ubicacion:
            return None

        return UbicacionDeteccionSerializer(ubicacion).data

    def get_url_maps(self, obj):
        ubicacion = getattr(obj, "ubicacion", None)

        if ubicacion and ubicacion.url_maps:
            return ubicacion.url_maps

        if obj.latitud_deteccion and obj.longitud_deteccion:
            return f"https://www.google.com/maps?q={obj.latitud_deteccion},{obj.longitud_deteccion}"

        return None

    def get_documento_respaldo_url(self, obj):
        request = self.context.get("request")

        if not obj.aviso:
            return None

        if not obj.aviso.documento_respaldo:
            return None

        if request:
            return request.build_absolute_uri(obj.aviso.documento_respaldo.url)

        return obj.aviso.documento_respaldo.url
