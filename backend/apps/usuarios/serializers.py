from django.contrib.auth.models import User
from rest_framework import serializers
from .models import PerfilUsuario

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name','email','is_active','is_staff','date_joined']


class PerfilUsuarioSerializer(serializers.ModelSerializer):
    usuario_detalle = UserSerializer(source='usuario', read_only=True)

    class Meta:
        model = PerfilUsuario
        fields = ['id', 'usuario', 'usuario_detalle', 'telefono', 'cedula', 'rol', 'estado', 'fecha_creacion', 'fecha_actualizacion']


