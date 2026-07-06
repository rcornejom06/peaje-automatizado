from rest_framework import serializers
from .models import CategoriaVehiculo, Vehiculo


class CategoriaVehiculoSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategoriaVehiculo
        fields = "__all__"


class VehiculoSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(
        source="usuario.username",
        read_only=True
    )

    usuario_email = serializers.EmailField(
        source="usuario.email",
        read_only=True
    )

    usuario_detalle = serializers.SerializerMethodField()
    perfil_usuario = serializers.SerializerMethodField()

    categoria_nombre = serializers.CharField(
        source="categoria.nombre",
        read_only=True
    )

    categoria_tarifa = serializers.DecimalField(
        source="categoria.tarifa",
        max_digits=8,
        decimal_places=2,
        read_only=True
    )

    revisado_por_username = serializers.CharField(
        source="revisado_por.username",
        read_only=True
    )

    documento_respaldo_url = serializers.SerializerMethodField()

    class Meta:
        model = Vehiculo
        fields = [
            "id",

            "usuario",
            "usuario_username",
            "usuario_email",
            "usuario_detalle",
            "perfil_usuario",

            "categoria",
            "categoria_nombre",
            "categoria_tarifa",

            "placa",
            "marca",
            "modelo",
            "color",
            "anio",
            "estado",

            "fecha_registro",
            "fecha_actualizacion",

            "estado_revision",
            "motivo_revision",
            "fecha_revision",

            "revisado_por",
            "revisado_por_username",

            "documento_respaldo",
            "documento_respaldo_url",
        ]

        read_only_fields = [
            "usuario",
            "usuario_username",
            "usuario_email",
            "usuario_detalle",
            "perfil_usuario",

            "categoria_nombre",
            "categoria_tarifa",

            "fecha_registro",
            "fecha_actualizacion",

            "estado_revision",
            "motivo_revision",
            "fecha_revision",

            "revisado_por",
            "revisado_por_username",

            "documento_respaldo_url",
        ]

    def get_usuario_detalle(self, obj):
        usuario = obj.usuario

        if not usuario:
            return None

        return {
            "id": usuario.id,
            "username": usuario.username,
            "first_name": usuario.first_name,
            "last_name": usuario.last_name,
            "email": usuario.email,
        }

    def get_perfil_usuario(self, obj):
        usuario = obj.usuario

        if not usuario:
            return None

        perfil = getattr(usuario, "perfil", None)

        if not perfil:
            return None

        return {
            "telefono": perfil.telefono,
            "cedula": perfil.cedula,
            "rol": perfil.rol,
            "estado": perfil.estado,
        }

    def get_documento_respaldo_url(self, obj):
        request = self.context.get("request")

        if not obj.documento_respaldo:
            return None

        if request:
            return request.build_absolute_uri(obj.documento_respaldo.url)

        return obj.documento_respaldo.url