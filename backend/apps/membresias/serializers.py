from rest_framework import serializers
from .models import PlanMembresia, Membresia


class PlanMembresiaSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlanMembresia
        fields = [
            "id",
            "nombre",
            "descripcion",
            "precio",
            "duracion_dias",
            "pases_incluidos",
            "descuento_porcentaje",
            "estado",
        ]


class MembresiaSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(
        source="usuario.username",
        read_only=True
    )

    plan_nombre = serializers.CharField(
        source="plan.nombre",
        read_only=True
    )

    plan_precio = serializers.DecimalField(
        source="plan.precio",
        max_digits=10,
        decimal_places=2,
        read_only=True
    )

    pases_incluidos = serializers.IntegerField(
        source="plan.pases_incluidos",
        read_only=True
    )

    class Meta:
        model = Membresia
        fields = [
            "id",
            "usuario",
            "usuario_username",
            "plan",
            "plan_nombre",
            "plan_precio",
            "pases_incluidos",
            "fecha_inicio",
            "pases_restantes",
            "estado",
            "fecha_creacion",
        ]

        read_only_fields = [
            "id",
            "usuario",
            "usuario_username",
            "plan_nombre",
            "plan_precio",
            "pases_incluidos",
            "fecha_inicio",
            "pases_restantes",
            "estado",
            "fecha_creacion",
        ]

