from rest_framework import serializers
from .models import PlanMembresia, Membresia


class PlanMembresiaSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlanMembresia
        fields = "__all__"


class MembresiaSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(source="usuario.username", read_only=True)
    plan_nombre = serializers.CharField(source="plan.nombre", read_only=True)
    pases_incluidos = serializers.IntegerField(source="plan.pases_incluidos", read_only=True)

    class Meta:
        model = Membresia
        fields = "__all__"