from datetime import timedelta
import secrets

from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone
from django.utils.crypto import constant_time_compare
from django.contrib.auth import get_user_model

from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from rest_framework.response import Response

from rest_framework_simplejwt.views import TokenObtainPairView

from .models import PerfilUsuario
from .serializers import (
    UserSerializer,
    PerfilUsuarioSerializer,
    RegistroUsuarioSerializer,
    ActualizarMiPerfilSerializer,
    MiTokenObtainPairSerializer,
    CambiarPasswordSerializer,
    SolicitarResetPasswordSerializer,
    ConfirmarResetPasswordSerializer,
    CrearOperadorSerializer,
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


def es_administrador(usuario):
    if usuario.is_superuser or usuario.is_staff:
        return True

    perfil = getattr(usuario, "perfil", None)

    if not perfil:
        return False

    return perfil.rol == PerfilUsuario.Rol.ADMINISTRADOR


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by("id")
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    @action(
        detail=False,
        methods=["post"],
        permission_classes=[AllowAny],
        url_path="registro",
    )
    def registro(self, request):
        serializer = RegistroUsuarioSerializer(data=request.data)

        if serializer.is_valid():
            user = serializer.save()

            try:
                enviar_codigo_verificacion(user)
            except Exception:
                return Response(
                    {
                        "mensaje": "Usuario registrado, pero no se pudo enviar el correo.",
                        "requiere_reenvio": True,
                        "email": user.email,
                    },
                    status=status.HTTP_201_CREATED,
                )

            return Response(
                {
                    "mensaje": "Usuario registrado correctamente. Revise su correo para verificar la cuenta.",
                    "usuario": UserSerializer(user).data,
                    "perfil": PerfilUsuarioSerializer(user.perfil).data,
                },
                status=status.HTTP_201_CREATED,
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(
        detail=False,
        methods=["post"],
        url_path="solicitar-reset-password",
        permission_classes=[AllowAny],
    )
    def solicitar_reset_password(self, request):
        serializer = SolicitarResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        resultado = serializer.save()
        usuario = resultado["usuario"]
        codigo = resultado["codigo"]

        asunto = "Código de recuperación de contraseña - VíaSmart"
        mensaje = (
            f"Hola {usuario.first_name or usuario.username},\n\n"
            f"Tu código de recuperación de contraseña es: {codigo}\n\n"
            f"Este código expira en 10 minutos.\n\n"
            f"Si no solicitaste este cambio, ignora este mensaje.\n\n"
            f"Sistema Inteligente de Peaje"
        )

        try:
            send_mail(
                asunto,
                mensaje,
                getattr(settings, "DEFAULT_FROM_EMAIL", "no-reply@viasmart.com"),
                [usuario.email],
                fail_silently=False,
            )
        except Exception as error:
            if settings.DEBUG:
                return Response(
                    {
                        "mensaje": "Código generado. El correo no pudo enviarse, pero estás en modo DEBUG.",
                        "codigo_debug": codigo,
                        "error_email": str(error),
                    },
                    status=status.HTTP_200_OK,
                )

            return Response(
                {
                    "error": "No se pudo enviar el correo de recuperación."
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        return Response(
            {
                "mensaje": "Código de recuperación enviado correctamente."
            },
            status=status.HTTP_200_OK,
        )

    @action(
        detail=False,
        methods=["post"],
        url_path="confirmar-reset-password",
        permission_classes=[AllowAny],
    )
    def confirmar_reset_password(self, request):
        serializer = ConfirmarResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(
            {
                "mensaje": "Contraseña actualizada correctamente. Ya puede iniciar sesión."
            },
            status=status.HTTP_200_OK,
        )

    @action(
        detail=False,
        methods=["post"],
        permission_classes=[AllowAny],
        url_path="verificar-correo",
    )
    def verificar_correo(self, request):
        email = request.data.get("email", "").lower().strip()
        codigo = request.data.get("codigo", "").strip()

        if not email or not codigo:
            return Response(
                {"error": "Debe enviar email y código."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if len(codigo) != 6 or not codigo.isdigit():
            return Response(
                {"error": "El código debe tener 6 dígitos."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.filter(email__iexact=email).first()

        if not user:
            return Response(
                {"error": "No existe un usuario con ese correo."},
                status=status.HTTP_404_NOT_FOUND,
            )

        perfil = getattr(user, "perfil", None)

        if not perfil:
            return Response(
                {"error": "El usuario no tiene perfil asociado."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if perfil.correo_verificado:
            return Response(
                {"mensaje": "El correo ya está verificado."},
                status=status.HTTP_200_OK,
            )

        if not perfil.codigo_verificacion:
            return Response(
                {"error": "No existe un código activo. Solicite uno nuevo."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not perfil.codigo_expira:
            return Response(
                {"error": "El código no tiene fecha de expiración. Solicite uno nuevo."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if timezone.now() > perfil.codigo_expira:
            return Response(
                {"error": "El código ha expirado. Solicite uno nuevo."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not constant_time_compare(perfil.codigo_verificacion, codigo):
            return Response(
                {"error": "Código incorrecto."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        perfil.correo_verificado = True
        perfil.codigo_verificacion = None
        perfil.codigo_expira = None
        perfil.estado = True
        perfil.save(
            update_fields=[
                "correo_verificado",
                "codigo_verificacion",
                "codigo_expira",
                "estado",
            ]
        )

        user.is_active = True
        user.save(update_fields=["is_active"])

        return Response(
            {"mensaje": "Correo verificado correctamente. Ya puede iniciar sesión."},
            status=status.HTTP_200_OK,
        )

    @action(
        detail=False,
        methods=["post"],
        permission_classes=[AllowAny],
        url_path="reenviar-codigo",
    )
    def reenviar_codigo(self, request):
        email = request.data.get("email", "").lower().strip()

        if not email:
            return Response(
                {"error": "Debe enviar el email."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.filter(email__iexact=email).first()

        if not user:
            return Response(
                {"error": "No existe un usuario con ese correo."},
                status=status.HTTP_404_NOT_FOUND,
            )

        perfil = getattr(user, "perfil", None)

        if not perfil:
            return Response(
                {"error": "El usuario no tiene perfil asociado."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if perfil.correo_verificado:
            return Response(
                {"mensaje": "El correo ya está verificado."},
                status=status.HTTP_200_OK,
            )

        perfil.codigo_verificacion = f"{secrets.randbelow(1000000):06d}"
        perfil.codigo_expira = timezone.now() + timedelta(minutes=10)
        perfil.save(update_fields=["codigo_verificacion", "codigo_expira"])

        try:
            enviar_codigo_verificacion(user)
        except Exception:
            return Response(
                {"error": "No se pudo enviar el correo. Intente nuevamente."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        return Response(
            {"mensaje": "Código reenviado correctamente."},
            status=status.HTTP_200_OK,
        )


class PerfilUsuarioViewSet(viewsets.ModelViewSet):
    queryset = PerfilUsuario.objects.select_related("usuario").all()
    serializer_class = PerfilUsuarioSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        usuario = self.request.user

        if es_administrador(usuario):
            return PerfilUsuario.objects.select_related("usuario").all()

        return PerfilUsuario.objects.select_related("usuario").filter(usuario=usuario)

    @action(
        detail=False,
        methods=["get"],
        url_path="mi-perfil",
        permission_classes=[IsAuthenticated],
    )
    def mi_perfil(self, request):
        perfil, _ = PerfilUsuario.objects.get_or_create(usuario=request.user)
        serializer = PerfilUsuarioSerializer(perfil)

        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(
        detail=False,
        methods=["patch"],
        url_path="actualizar-mi-perfil",
        permission_classes=[IsAuthenticated],
    )
    def actualizar_mi_perfil(self, request):
        perfil, _ = PerfilUsuario.objects.get_or_create(usuario=request.user)

        serializer = ActualizarMiPerfilSerializer(
            perfil,
            data=request.data,
            partial=True,
            context={"request": request},
        )

        serializer.is_valid(raise_exception=True)
        serializer.save()

        perfil.refresh_from_db()
        respuesta = PerfilUsuarioSerializer(perfil)

        return Response(
            {
                "mensaje": "Perfil actualizado correctamente.",
                "perfil": respuesta.data,
            },
            status=status.HTTP_200_OK,
        )

    @action(
        detail=False,
        methods=["post"],
        url_path="cambiar-password",
        permission_classes=[IsAuthenticated],
    )
    def cambiar_password(self, request):
        serializer = CambiarPasswordSerializer(
            data=request.data,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)

        nueva_password = serializer.validated_data["nueva_password"]

        request.user.set_password(nueva_password)
        request.user.save(update_fields=["password"])

        perfil = getattr(request.user, "perfil", None)

        if perfil:
            perfil.requiere_cambio_password = False
            perfil.save(update_fields=["requiere_cambio_password"])

        return Response(
            {"mensaje": "Contraseña actualizada correctamente."},
            status=status.HTTP_200_OK,
        )

    @action(
        detail=False,
        methods=["post"],
        url_path="crear-operador",
        permission_classes=[IsAuthenticated],
    )
    def crear_operador(self, request):
        if not es_administrador(request.user):
            return Response(
                {
                    "error": "No tienes permisos para crear operadores."
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = CrearOperadorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        usuario = serializer.save()

        perfil = usuario.perfil
        respuesta = PerfilUsuarioSerializer(perfil)

        return Response(
            {
                "mensaje": "Operador creado correctamente.",
                "perfil": respuesta.data,
            },
            status=status.HTTP_201_CREATED,
        )


class MiTokenObtainPairView(TokenObtainPairView):
    serializer_class = MiTokenObtainPairSerializer