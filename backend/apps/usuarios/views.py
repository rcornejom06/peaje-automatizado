from datetime import timedelta
import secrets
from urllib.parse import urlencode

from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone
from django.utils.crypto import constant_time_compare
from django.contrib.auth import get_user_model

from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action,api_view, permission_classes
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


@api_view(["POST"])
@permission_classes([AllowAny])
def verificar_correo_operador(request):
    email = request.data.get("email", "").strip().lower()
    codigo = request.data.get("codigo", "").strip()

    if not email or not codigo:
        return Response(
            {"error": "Debe ingresar el correo y el código de verificación."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    usuario = User.objects.filter(email__iexact=email).first()

    if not usuario:
        return Response(
            {"error": "No existe una cuenta administrativa con ese correo."},
            status=status.HTTP_404_NOT_FOUND,
        )

    perfil = getattr(usuario, "perfil", None)

    if not perfil:
        return Response(
            {"error": "El usuario no tiene perfil asociado."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    roles_permitidos = [
        PerfilUsuario.Rol.ADMINISTRADOR,
        PerfilUsuario.Rol.OPERADOR,
    ]

    if perfil.rol not in roles_permitidos:
        return Response(
            {"error": "Este correo no pertenece a una cuenta administrativa."},
            status=status.HTTP_403_FORBIDDEN,
        )

    if perfil.correo_verificado:
        return Response(
            {"mensaje": "El correo administrativo ya se encuentra verificado."},
            status=status.HTTP_200_OK,
        )

    if perfil.codigo_verificacion != codigo:
        return Response(
            {"error": "Código de verificación incorrecto."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if perfil.codigo_expira and perfil.codigo_expira < timezone.now():
        return Response(
            {"error": "El código de verificación ha expirado. Solicite uno nuevo."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    perfil.correo_verificado = True
    perfil.estado = True
    perfil.codigo_verificacion = None
    perfil.codigo_expira = None
    perfil.save(update_fields=[
        "correo_verificado",
        "estado",
        "codigo_verificacion",
        "codigo_expira",
        "fecha_actualizacion",
    ])

    return Response(
        {
            "mensaje": "Correo administrativo verificado correctamente. Ahora puede iniciar sesión."
        },
        status=status.HTTP_200_OK,
    )


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
        except Exception as error:
            if settings.DEBUG:
                return Response(
                    {
                        "mensaje": "Código generado. No se pudo enviar el correo, pero estás en modo DEBUG.",
                        "codigo_debug": perfil.codigo_verificacion,
                        "error_email": str(error),
                    },
                    status=status.HTTP_200_OK,
                )

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

    def create(self, request, *args, **kwargs):
        if not es_administrador(request.user):
            return Response(
                {
                    "error": "No tienes permisos para crear perfiles."
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if not es_administrador(request.user):
            return Response(
                {
                    "error": "No tienes permisos para modificar perfiles directamente. Use actualizar-mi-perfil."
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        if not es_administrador(request.user):
            return Response(
                {
                    "error": "No tienes permisos para modificar perfiles directamente. Use actualizar-mi-perfil."
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if not es_administrador(request.user):
            return Response(
                {
                    "error": "No tienes permisos para eliminar perfiles."
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        return super().destroy(request, *args, **kwargs)

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

        codigo = f"{secrets.randbelow(1000000):06d}"

        perfil.rol = PerfilUsuario.Rol.OPERADOR
        perfil.estado = True
        perfil.correo_verificado = False
        perfil.codigo_verificacion = codigo
        perfil.codigo_expira = timezone.now() + timedelta(minutes=15)
        perfil.requiere_cambio_password = True
        perfil.save()

        frontend_admin_url = getattr(
            settings,
            "FRONTEND_ADMIN_URL",
            "http://localhost:5173",
        )

        query = urlencode(
            {
                "email": usuario.email,
                "codigo": codigo,
            }
        )

        enlace_verificacion = (
            f"{frontend_admin_url}/verificar-correo-operador?{query}"
        )

        asunto = "Verificación de cuenta de operador - VíaSmart"

        mensaje = (
            f"Hola {usuario.first_name or usuario.username},\n\n"
            f"Tu cuenta de operador fue creada en el Panel Administrativo de VíaSmart.\n\n"
            f"Usuario: {usuario.username}\n\n"
            f"Para verificar tu correo, abre el siguiente enlace:\n\n"
            f"{enlace_verificacion}\n\n"
            f"También puedes ingresar manualmente este código:\n\n"
            f"{codigo}\n\n"
            f"Este código expira en 15 minutos.\n\n"
            f"Después de verificar tu correo, deberás cambiar tu contraseña temporal "
            f"en el primer ingreso.\n\n"
            f"Sistema Inteligente de Peaje Automatizado - VíaSmart"
        )

        html_message = f"""
        <div style="font-family: Arial, sans-serif; color: #111827; line-height: 1.5;">
            <h2>Verificación de cuenta de operador - VíaSmart</h2>

            <p>Hola <strong>{usuario.first_name or usuario.username}</strong>,</p>

            <p>
                Tu cuenta de operador fue creada en el Panel Administrativo de VíaSmart.
            </p>

            <p>
                <strong>Usuario:</strong> {usuario.username}
            </p>

            <p>Para verificar tu correo, haz clic en el siguiente botón:</p>

            <p style="margin: 24px 0;">
                <a href="{enlace_verificacion}"
                   style="
                        background: #2563eb;
                        color: #ffffff;
                        padding: 12px 20px;
                        text-decoration: none;
                        border-radius: 8px;
                        font-weight: bold;
                        display: inline-block;
                   ">
                    Verificar cuenta de operador
                </a>
            </p>

            <p>Si el botón no funciona, copia y pega este enlace en tu navegador:</p>

            <p style="word-break: break-all;">
                <a href="{enlace_verificacion}">{enlace_verificacion}</a>
            </p>

            <p>También puedes ingresar este código manualmente:</p>

            <h3 style="letter-spacing: 4px; font-size: 24px;">{codigo}</h3>

            <p>Este código expira en 15 minutos.</p>

            <p>
                Después de verificar tu correo, deberás cambiar tu contraseña temporal
                en el primer ingreso.
            </p>

            <hr />

            <small>Sistema Inteligente de Peaje Automatizado - VíaSmart</small>
        </div>
        """

        try:
            send_mail(
                asunto,
                mensaje,
                getattr(settings, "DEFAULT_FROM_EMAIL", "no-reply@viasmart.com"),
                [usuario.email],
                fail_silently=False,
                html_message=html_message,
            )
        except Exception as error:
            respuesta = PerfilUsuarioSerializer(perfil)

            if settings.DEBUG:
                return Response(
                    {
                        "mensaje": "Operador creado. No se pudo enviar el correo, pero estás en modo DEBUG.",
                        "codigo_debug": codigo,
                        "enlace_debug": enlace_verificacion,
                        "error_email": str(error),
                        "perfil": respuesta.data,
                    },
                    status=status.HTTP_201_CREATED,
                )

            return Response(
                {
                    "error": "Operador creado, pero no se pudo enviar el correo de verificación."
                },
                status=status.HTTP_201_CREATED,
            )

        respuesta = PerfilUsuarioSerializer(perfil)

        return Response(
            {
                "mensaje": "Operador creado correctamente. Se envió el enlace de verificación al correo.",
                "perfil": respuesta.data,
            },
            status=status.HTTP_201_CREATED,
        )


class MiTokenObtainPairView(TokenObtainPairView):
    serializer_class = MiTokenObtainPairSerializer
