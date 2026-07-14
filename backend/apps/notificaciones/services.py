from apps.usuarios.models import PerfilUsuario
from .models import Notificacion


def crear_notificacion(
    usuario,
    titulo,
    mensaje,
    tipo=Notificacion.Tipo.SISTEMA,
    alerta=None,
    url_accion=None,
    tipo_accion=None,
):
    if not usuario:
        return None

    try:
        return Notificacion.objects.create(
            usuario=usuario,
            alerta=alerta,
            titulo=titulo,
            mensaje=mensaje,
            tipo=tipo,
            url_accion=url_accion,
            tipo_accion=tipo_accion,
        )
    except Exception:
        return None


def notificar_administradores(
    titulo,
    mensaje,
    tipo=Notificacion.Tipo.SISTEMA,
    alerta=None,
    url_accion=None,
    tipo_accion=None,
):
    administradores = PerfilUsuario.objects.filter(
        rol=PerfilUsuario.Rol.ADMINISTRADOR,
        estado=True,
    ).select_related("usuario")

    notificaciones = []

    for perfil in administradores:
        notificacion = crear_notificacion(
            usuario=perfil.usuario,
            titulo=titulo,
            mensaje=mensaje,
            tipo=tipo,
            alerta=alerta,
            url_accion=url_accion,
            tipo_accion=tipo_accion,
        )

        if notificacion:
            notificaciones.append(notificacion)

    return notificaciones