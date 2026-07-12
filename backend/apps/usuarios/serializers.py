import re
from datetime import timedelta
from django.utils import timezone
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.exceptions import AuthenticationFailed
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
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
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'is_active', 'is_staff', 'date_joined']


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

    def validate_first_name(self, value):
        value = value.strip()

        if not re.match(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$", value):
            raise serializers.ValidationError(
                "El nombre solo debe contener letras."
            )

        return value

    def validate_last_name(self, value):
        value = value.strip()

        if not re.match(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$", value):
            raise serializers.ValidationError(
                "El apellido solo debe contener letras."
            )

        return value

    def validate_email(self, value):
        user = self.context["request"].user

        if User.objects.filter(email=value).exclude(id=user.id).exists():
            raise serializers.ValidationError(
                "Ya existe otro usuario con ese correo."
            )

        return value

    def validate_telefono(self, value):
        value = value.strip()

        if not value:
            return value

        if not value.isdigit():
            raise serializers.ValidationError(
                "El teléfono solo debe contener números."
            )

        if len(value) != 10:
            raise serializers.ValidationError(
                "El teléfono debe tener 10 dígitos."
            )

        if not value.startswith("09"):
            raise serializers.ValidationError(
                "El celular debe iniciar con 09."
            )
        return value

    def validate_cedula(self, value):
        value = value.strip()

        if not value:
            return value

        if not value.isdigit():
            raise serializers.ValidationError(
                "La cédula solo debe contener números."
            )

        if not validar_cedula_ecuatoriana(value):
            raise serializers.ValidationError(
                "La cédula ingresada no es válida para Ecuador."
            )

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


class CambiarPasswordSerializer(serializers.Serializer):
    password_actual = serializers.CharField(write_only=True)
    nueva_password = serializers.CharField(write_only=True, min_length=8)
    confirmar_password = serializers.CharField(write_only=True, min_length=8)

    def validate(self, attrs):
        user = self.context["request"].user

        password_actual = attrs.get("password_actual")
        nueva_password = attrs.get("nueva_password")
        confirmar_password = attrs.get("confirmar_password")

        if not user.check_password(password_actual):
            raise serializers.ValidationError({
                "password_actual": "La contraseña actual no es correcta."
            })

        if nueva_password != confirmar_password:
            raise serializers.ValidationError({
                "confirmar_password": "Las contraseñas no coinciden."
            })

        if password_actual == nueva_password:
            raise serializers.ValidationError({
                "nueva_password": "La nueva contraseña debe ser diferente a la actual."
            })

        try:
            validate_password(nueva_password, user)
        except DjangoValidationError as e:
            raise serializers.ValidationError({
                "nueva_password": list(e.messages)
            })

        return attrs
class SolicitarResetPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        value = value.strip().lower()

        user = User.objects.filter(email__iexact=value).first()

        if not user:
            raise serializers.ValidationError(
                "No existe un usuario registrado con ese correo."
            )

        self.user = user
        return value

    def save(self):
        perfil, _ = PerfilUsuario.objects.get_or_create(usuario=self.user)

        codigo = f"{secrets.randbelow(1000000):06d}"

        perfil.codigo_verificacion = codigo
        perfil.codigo_expira = timezone.now() + timedelta(minutes=10)
        perfil.requiere_cambio_password = True
        perfil.save(update_fields=[
            "codigo_verificacion",
            "codigo_expira",
            "requiere_cambio_password",
            "fecha_actualizacion",
        ])

        return {
            "usuario": self.user,
            "perfil": perfil,
            "codigo": codigo,
        }


class ConfirmarResetPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()
    codigo = serializers.CharField(max_length=6)
    nueva_password = serializers.CharField(write_only=True, min_length=8)
    confirmar_password = serializers.CharField(
        write_only=True,
        min_length=8,
        required=False,
        allow_blank=True
    )

    def validate(self, attrs):
        email = attrs.get("email", "").strip().lower()
        codigo = attrs.get("codigo", "").strip()
        nueva_password = attrs.get("nueva_password")
        confirmar_password = attrs.get("confirmar_password", "")

        user = User.objects.filter(email__iexact=email).first()

        if not user:
            raise serializers.ValidationError({
                "email": "No existe un usuario registrado con ese correo."
            })

        perfil = getattr(user, "perfil", None)

        if not perfil:
            raise serializers.ValidationError({
                "email": "El usuario no tiene un perfil asociado."
            })

        if not perfil.codigo_verificacion:
            raise serializers.ValidationError({
                "codigo": "No existe un código de recuperación activo."
            })

        if perfil.codigo_verificacion != codigo:
            raise serializers.ValidationError({
                "codigo": "El código ingresado no es correcto."
            })

        if perfil.codigo_expira and timezone.now() > perfil.codigo_expira:
            raise serializers.ValidationError({
                "codigo": "El código de recuperación ha expirado."
            })

        if confirmar_password and nueva_password != confirmar_password:
            raise serializers.ValidationError({
                "confirmar_password": "Las contraseñas no coinciden."
            })

        try:
            validate_password(nueva_password, user)
        except DjangoValidationError as e:
            raise serializers.ValidationError({
                "nueva_password": list(e.messages)
            })

        self.user = user
        self.perfil = perfil

        return attrs

    def save(self):
        nueva_password = self.validated_data["nueva_password"]

        self.user.set_password(nueva_password)
        self.user.save(update_fields=["password"])

        self.perfil.codigo_verificacion = None
        self.perfil.codigo_expira = None
        self.perfil.requiere_cambio_password = False
        self.perfil.save(update_fields=[
            "codigo_verificacion",
            "codigo_expira",
            "requiere_cambio_password",
            "fecha_actualizacion",
        ])

        return self.user

class CrearOperadorSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
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

    def validate_username(self, value):
        value = value.strip()

        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError(
                "Ya existe un usuario con ese username."
            )

        return value

    def validate_email(self, value):
        value = value.strip().lower()

        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "Ya existe un usuario con ese correo."
            )

        return value

    def validate_first_name(self, value):
        value = value.strip()

        if not value:
            return value

        if not re.match(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$", value):
            raise serializers.ValidationError(
                "El nombre solo debe contener letras."
            )

        return value

    def validate_last_name(self, value):
        value = value.strip()

        if not value:
            return value

        if not re.match(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$", value):
            raise serializers.ValidationError(
                "El apellido solo debe contener letras."
            )

        return value

    def validate_telefono(self, value):
        value = value.strip()

        if not value:
            return value

        if not value.isdigit():
            raise serializers.ValidationError(
                "El teléfono solo debe contener números."
            )

        if len(value) != 10:
            raise serializers.ValidationError(
                "El teléfono debe tener 10 dígitos."
            )

        if not value.startswith("09"):
            raise serializers.ValidationError(
                "El celular debe iniciar con 09."
            )

        return value

    def validate_cedula(self, value):
        value = value.strip()

        if not value:
            return value

        if not value.isdigit():
            raise serializers.ValidationError(
                "La cédula solo debe contener números."
            )

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
            perfil.rol = PerfilUsuario.Rol.OPERADOR
            perfil.estado = True
            perfil.correo_verificado = True
            perfil.codigo_verificacion = None
            perfil.codigo_expira = None
            perfil.requiere_cambio_password = True
            perfil.save(update_fields=[
                "telefono",
                "cedula",
                "rol",
                "estado",
                "correo_verificado",
                "codigo_verificacion",
                "codigo_expira",
                "requiere_cambio_password",
                "fecha_actualizacion",
            ])

        return user