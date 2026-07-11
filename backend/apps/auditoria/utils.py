from .models import HistorialUsuario


def obtener_ip_request(request):
    if not request:
        return None

    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")

    if x_forwarded_for:
        ip = x_forwarded_for.split(",")[0]
    else:
        ip = request.META.get("REMOTE_ADDR")

    return ip


def registrar_historial(
    usuario,
    accion,
    descripcion="",
    modulo="General",
    request=None,
    dispositivo="API",
    estado=None,
):
    try:
        if estado is None:
            estado = HistorialUsuario.Estado.EXITOSO

        HistorialUsuario.objects.create(
            usuario=usuario,
            accion=accion,
            descripcion=descripcion,
            modulo=modulo,
            direccion_ip=obtener_ip_request(request),
            dispositivo=dispositivo,
            estado=estado,
        )

        return True

    except Exception:
        return False