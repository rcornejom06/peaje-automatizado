import random
from datetime import timedelta
from django.utils import timezone
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.exceptions import AuthenticationFailed
from django.contrib.auth import get_user_model
from rest_framework import serializers
from .models import PerfilUsuario
from django.db import transaction
from .validators import validar_cedula_ecuatoriana
import secrets

User = get_user_model()

class MiTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)

        perfil = getattr(self.user, 'perfil', None)

        if perfil and not perfil.correo_verificado:
            raise AuthenticationFailed(
                'Debe verificar su correo electrónico antes de iniciar sesión.',
                code='correo_no_verificado'
            )

        if perfil and not perfil.estado:
            raise AuthenticationFailed(
                'Su cuenta está inactiva. Contacte al administrador.',
                code='cuenta_inactiva'
            )

        return data

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name','email','is_active','is_staff','date_joined']


class PerfilUsuarioSerializer(serializers.ModelSerializer):
    usuario_detalle = UserSerializer(source='usuario', read_only=True)

    class Meta:
        model = PerfilUsuario
        fields = [
            'id',
            'usuario',
            'usuario_detalle',
            'telefono',
            'cedula',
            'rol',
            'estado',
            'correo_verificado',
            'requiere_cambio_password',
            'fecha_creacion',
            'fecha_actualizacion',
        ]


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

    def validate_cedula(self, value):
        value = value.strip()

        if not validar_cedula_ecuatoriana(value):
            raise serializers.ValidationError(
                "La cédula ingresada no es válida para Ecuador."
            )

        return value

    def create(self, validated_data):
        telefono = validated_data.pop("telefono", "")
        cedula = validated_data.pop("cedula", "")
        password = validated_data.pop("password")

        with transaction.atomic():
            user = User.objects.create_user(
                password=password,
                is_active=True,
                **validated_data
            )

            perfil = user.perfil
            perfil.telefono = telefono
            perfil.cedula = cedula
            perfil.rol = PerfilUsuario.Rol.USUARIO
            perfil.estado = False
            perfil.correo_verificado = False
            perfil.codigo_verificacion = f"{secrets.randbelow(1000000):06d}"
            perfil.codigo_expira = timezone.now() + timedelta(minutes=10)
            perfil.requiere_cambio_password = False
            perfil.save()

        return user


class ActualizarMiPerfilSerializer(serializers.Serializer):
    first_name = serializers.CharField(
        max_length=150,
        required=False,
        allow_blank=True
    )
    last_name = serializers.CharField(
        max_length=150,
        required=False,
        allow_blank=True
    )
    email = serializers.EmailField(
        required=False
    )
    telefono = serializers.CharField(
        max_length=20,
        required=False,
        allow_blank=True
    )
    cedula = serializers.CharField(
        max_length=20,
        required=False,
        allow_blank=True
    )

    def validate_email(self, value):
        user = self.context["request"].user

        if User.objects.filter(email=value).exclude(id=user.id).exists():
            raise serializers.ValidationError(
                "Ya existe otro usuario con ese correo."
            )

        return value

    def validate_cedula(self, value):
        value = value.strip()

        if not validar_cedula_ecuatoriana(value):
            raise serializers.ValidationError("Ingrese una cédula ecuatoriana válida.")

        return value

    def update(self, instance, validated_data):
        user = instance.usuario

        user.first_name = validated_data.get("first_name", user.first_name)
        user.last_name = validated_data.get("last_name", user.last_name)
        user.email = validated_data.get("email", user.email)
        user.save()

        instance.telefono = validated_data.get("telefono", instance.telefono)
        instance.cedula = validated_data.get("cedula", instance.cedula)
        instance.save()

        return instance