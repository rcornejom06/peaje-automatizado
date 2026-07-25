from apps.usuarios.models import PerfilUsuario
from .models import DispositivoPush, Notificacion
from .firebase import enviar_push


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
        notificacion = Notificacion.objects.create(
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

    _enviar_push_a_usuario(
        usuario,
        titulo=titulo,
        mensaje=mensaje,
        tipo=tipo,
        url_accion=url_accion,
        tipo_accion=tipo_accion,
    )

    return notificacion


def _enviar_push_a_usuario(usuario, titulo, mensaje, tipo, url_accion, tipo_accion):
    tokens = list(
        DispositivoPush.objects.filter(usuario=usuario).values_list("token", flat=True)
    )

    if not tokens:
        return

    tokens_invalidos = enviar_push(
        tokens,
        titulo=titulo,
        mensaje=mensaje,
        datos={
            "tipo": tipo,
            "tipo_accion": tipo_accion,
            "url_accion": url_accion,
        },
    )

    if tokens_invalidos:
        DispositivoPush.objects.filter(token__in=tokens_invalidos).delete()


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