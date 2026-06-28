from django.contrib.auth.models import User
from rest_framework import serializers
from .models import PerfilUsuario

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name','email','is_active','is_staff','date_joined']


class PerfilUsuarioSerializer(serializers.ModelSerializer):
    usuario_detalle = UserSerializer(source='usuario', read_only=True)

    class Meta:
        model = PerfilUsuario
        fields = ['id', 'usuario', 'usuario_detalle', 'telefono', 'cedula', 'rol', 'estado', 'fecha_creacion', 'fecha_actualizacion']


class RegistroUsuarioSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    first_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    last_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    telefono = serializers.CharField(max_length=20, required=False, allow_blank=True)
    cedula = serializers.CharField(max_length=20, required=False, allow_blank=True)

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Ya existe un usuario con ese username.")
        return value

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Ya existe un usuario con ese correo.")
        return value

    def create(self, validated_data):
        telefono = validated_data.pop("telefono", "")
        cedula = validated_data.pop("cedula", "")

        password = validated_data.pop("password")

        user = User.objects.create_user(
            password=password,
            **validated_data
        )

        perfil = user.perfil
        perfil.telefono = telefono
        perfil.cedula = cedula
        perfil.rol = PerfilUsuario.Rol.USUARIO
        perfil.save()

        return user