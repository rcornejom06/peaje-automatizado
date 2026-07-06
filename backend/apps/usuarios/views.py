from datetime import timedelta
import secrets
from django.core.mail import send_mail
from django.conf import settings
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from django.utils.crypto import constant_time_compare
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError

from .models import PerfilUsuario
from .serializers import (
    UserSerializer,
    PerfilUsuarioSerializer,
    RegistroUsuarioSerializer,
    ActualizarMiPerfilSerializer,
    MiTokenObtainPairSerializer,
)

User = get_user_model()


def enviar_codigo_verificacion(user):
    perfil = user.perfil

    asunto = "Código de verificación - Sistema de Peaje"
    mensaje = (
        f"Hola {user.first_name or user.username},\n\n"
        f"Tu código de verificación es: {perfil.codigo_verificacion}\n\n"
        f"Este código expira en 10 minutos.\n\n"
        f"Sistema Inteligente de Peaje"
    )

    send_mail(
        asunto,
        mensaje,
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
        fail_silently=False,
    )

def enviar_codigo_reset_password(user):
    perfil = user.perfil

    asunto = "Código para restablecer contraseña - Sistema de Peaje"
    mensaje = (
        f"Hola {user.first_name or user.username},\n\n"
        f"Recibimos una solicitud para restablecer tu contraseña.\n\n"
        f"Tu código de seguridad es: {perfil.codigo_verificacion}\n\n"
        f"Este código expira en 10 minutos.\n\n"
        f"Si no solicitaste este cambio, ignora este mensaje.\n\n"
        f"Sistema Inteligente de Peaje"
    )

    send_mail(
        asunto,
        mensaje,
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
        fail_silently=False,
    )



class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by("id")
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    @action(
        detail=False,
        methods=["post"],
        permission_classes=[AllowAny],
        url_path="registro"
    )
    def registro(self, request):
        serializer = RegistroUsuarioSerializer(data=request.data)

        if serializer.is_valid():
            user = serializer.save()

            try:
                enviar_codigo_verificacion(user)
            except Exception as e:
                return Response(
                    {
                        "mensaje": "Usuario registrado, pero no se pudo enviar el correo.",
                        "requiere_reenvio": True,
                        "email": user.email,
                    },
                    status=status.HTTP_201_CREATED
                )

            return Response(
                {
                    "mensaje": "Usuario registrado correctamente. Revise su correo para verificar la cuenta.",
                    "usuario": UserSerializer(user).data,
                    "perfil": PerfilUsuarioSerializer(user.perfil).data,
                },
                status=status.HTTP_201_CREATED
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(
        detail=False,
        methods=["post"],
        permission_classes=[AllowAny],
        url_path="verificar-correo"
    )
    def verificar_correo(self, request):
        email = request.data.get("email", "").lower().strip()
        codigo = request.data.get("codigo", "").strip()

        if not email or not codigo:
            return Response(
                {"error": "Debe enviar email y código."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(codigo) != 6 or not codigo.isdigit():
            return Response(
                {"error": "El código debe tener 6 dígitos."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.filter(email__iexact=email).first()

        if not user:
            return Response(
                {"error": "No existe un usuario con ese correo."},
                status=status.HTTP_404_NOT_FOUND
            )

        perfil = getattr(user, "perfil", None)

        if not perfil:
            return Response(
                {"error": "El usuario no tiene perfil asociado."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if perfil.correo_verificado:
            return Response(
                {"mensaje": "El correo ya está verificado."},
                status=status.HTTP_200_OK
            )

        if not perfil.codigo_verificacion:
            return Response(
                {"error": "No existe un código activo. Solicite uno nuevo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not perfil.codigo_expira:
            return Response(
                {"error": "El código no tiene fecha de expiración. Solicite uno nuevo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if timezone.now() > perfil.codigo_expira:
            return Response(
                {"error": "El código ha expirado. Solicite uno nuevo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not constant_time_compare(perfil.codigo_verificacion, codigo):
            return Response(
                {"error": "Código incorrecto."},
                status=status.HTTP_400_BAD_REQUEST
            )

        perfil.correo_verificado = True
        perfil.codigo_verificacion = None
        perfil.codigo_expira = None
        perfil.estado = True
        perfil.save(update_fields=[
            "correo_verificado",
            "codigo_verificacion",
            "codigo_expira",
            "estado"
        ])

        user.is_active = True
        user.save(update_fields=["is_active"])

        return Response(
            {"mensaje": "Correo verificado correctamente. Ya puede iniciar sesión."},
            status=status.HTTP_200_OK
        )

    @action(
        detail=False,
        methods=["post"],
        permission_classes=[AllowAny],
        url_path="reenviar-codigo"
    )
    def reenviar_codigo(self, request):
        email = request.data.get("email", "").lower().strip()

        if not email:
            return Response(
                {"error": "Debe enviar el email."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.filter(email__iexact=email).first()

        if not user:
            return Response(
                {"error": "No existe un usuario con ese correo."},
                status=status.HTTP_404_NOT_FOUND
            )

        perfil = getattr(user, "perfil", None)

        if not perfil:
            return Response(
                {"error": "El usuario no tiene perfil asociado."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if perfil.correo_verificado:
            return Response(
                {"mensaje": "El correo ya está verificado."},
                status=status.HTTP_200_OK
            )

        perfil.codigo_verificacion = f"{secrets.randbelow(1000000):06d}"
        perfil.codigo_expira = timezone.now() + timedelta(minutes=10)
        perfil.save(update_fields=["codigo_verificacion", "codigo_expira"])

        try:
            enviar_codigo_verificacion(user)
        except Exception:
            return Response(
                {"error": "No se pudo enviar el correo. Intente nuevamente."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        return Response(
            {"mensaje": "Código reenviado correctamente."},
            status=status.HTTP_200_OK
        )

    @action(
        detail=False,
        methods=["post"],
        permission_classes=[AllowAny],
        url_path="solicitar-reset-password"
    )
    def solicitar_reset_password(self, request):
        email = request.data.get("email", "").lower().strip()

        if not email:
            return Response(
                {"error": "Debe enviar el correo electrónico."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.filter(email__iexact=email).first()

        # Respuesta genérica por seguridad
        if not user:
            return Response(
                {
                    "mensaje": "Si el correo está registrado, se enviará un código de recuperación."
                },
                status=status.HTTP_200_OK
            )

        perfil = getattr(user, "perfil", None)

        if not perfil:
            return Response(
                {"error": "El usuario no tiene perfil asociado."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not perfil.correo_verificado:
            return Response(
                {
                    "error": "Debe verificar su correo antes de recuperar la contraseña."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        codigo = f"{secrets.randbelow(1000000):06d}"

        perfil.codigo_verificacion = codigo
        perfil.codigo_expira = timezone.now() + timedelta(minutes=10)
        perfil.requiere_cambio_password = True
        perfil.save(update_fields=[
            "codigo_verificacion",
            "codigo_expira",
            "requiere_cambio_password"
        ])

        try:
            enviar_codigo_reset_password(user)
        except Exception:
            return Response(
                {"error": "No se pudo enviar el código. Intente nuevamente."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        return Response(
            {
                "mensaje": "Si el correo está registrado, se enviará un código de recuperación."
            },
            status=status.HTTP_200_OK
        )

    @action(
        detail=False,
        methods=["post"],
        permission_classes=[AllowAny],
        url_path="confirmar-reset-password"
    )
    def confirmar_reset_password(self, request):
        email = request.data.get("email", "").lower().strip()
        codigo = request.data.get("codigo", "").strip()
        nueva_password = request.data.get("nueva_password", "")
        confirmar_password = request.data.get("confirmar_password", "")

        if not email or not codigo or not nueva_password or not confirmar_password:
            return Response(
                {"error": "Debe enviar email, código, nueva contraseña y confirmación."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(codigo) != 6 or not codigo.isdigit():
            return Response(
                {"error": "El código debe tener 6 dígitos."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if nueva_password != confirmar_password:
            return Response(
                {"error": "Las contraseñas no coinciden."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.filter(email__iexact=email).first()

        if not user:
            return Response(
                {"error": "Código incorrecto o expirado."},
                status=status.HTTP_400_BAD_REQUEST
            )

        perfil = getattr(user, "perfil", None)

        if not perfil:
            return Response(
                {"error": "El usuario no tiene perfil asociado."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not perfil.requiere_cambio_password:
            return Response(
                {"error": "No existe una solicitud activa para cambiar la contraseña."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not perfil.codigo_verificacion:
            return Response(
                {"error": "No existe un código activo. Solicite uno nuevo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not perfil.codigo_expira:
            return Response(
                {"error": "El código no tiene fecha de expiración. Solicite uno nuevo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if timezone.now() > perfil.codigo_expira:
            return Response(
                {"error": "El código ha expirado. Solicite uno nuevo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not constant_time_compare(perfil.codigo_verificacion, codigo):
            return Response(
                {"error": "Código incorrecto."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            validate_password(nueva_password, user)
        except DjangoValidationError as e:
            return Response(
                {"error": list(e.messages)},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(nueva_password)
        user.save(update_fields=["password"])

        perfil.codigo_verificacion = None
        perfil.codigo_expira = None
        perfil.requiere_cambio_password = False
        perfil.save(update_fields=[
            "codigo_verificacion",
            "codigo_expira",
            "requiere_cambio_password"
        ])

        return Response(
            {"mensaje": "Contraseña restablecida correctamente. Ya puede iniciar sesión."},
            status=status.HTTP_200_OK
        )

class PerfilUsuarioViewSet(viewsets.ModelViewSet):
    queryset = PerfilUsuario.objects.all().order_by("id")
    serializer_class = PerfilUsuarioSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["get"], url_path="mi-perfil")
    def mi_perfil(self, request):
        perfil = request.user.perfil

        return Response(
            PerfilUsuarioSerializer(perfil).data,
            status=status.HTTP_200_OK
        )

    @action(detail=False, methods=["patch"], url_path="actualizar-mi-perfil")
    def actualizar_mi_perfil(self, request):
        perfil = request.user.perfil

        serializer = ActualizarMiPerfilSerializer(
            perfil,
            data=request.data,
            partial=True,
            context={"request": request}
        )

        serializer.is_valid(raise_exception=True)
        serializer.save()

        perfil_actualizado = PerfilUsuarioSerializer(
            perfil,
            context={"request": request}
        )

        return Response(
            {
                "mensaje": "Perfil actualizado correctamente.",
                "perfil": perfil_actualizado.data,
            },
            status=status.HTTP_200_OK
        )

class MiTokenObtainPairView(TokenObtainPairView):
    serializer_class = MiTokenObtainPairSerializer


