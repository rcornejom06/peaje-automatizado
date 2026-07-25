import json
import os

import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings

_app = None
_intento_inicializacion_fallido = False


def _obtener_app():
    """Inicializa Firebase Admin una sola vez (perezosamente).

    Busca la credencial en dos lugares, en este orden:
      1. settings.FIREBASE_CREDENTIALS_JSON: el JSON completo de la cuenta
         de servicio pegado como variable de entorno (usar en Render/Railway/
         cualquier entorno sin filesystem persistente para secretos).
      2. settings.FIREBASE_CREDENTIALS_PATH: ruta a un archivo .json en disco
         (uso local/Docker Compose, como hasta ahora).

    Si ninguna de las dos esta disponible o falla, devuelve None en vez de
    reventar el resto de la app.
    """
    global _app, _intento_inicializacion_fallido

    if _app is not None:
        return _app

    if _intento_inicializacion_fallido:
        return None

    cred_json = getattr(settings, "FIREBASE_CREDENTIALS_JSON", None)
    cred_path = getattr(settings, "FIREBASE_CREDENTIALS_PATH", None)

    try:
        if firebase_admin._apps:
            _app = firebase_admin.get_app()
            return _app

        if cred_json:
            cred_dict = json.loads(cred_json)
            cred = credentials.Certificate(cred_dict)
        elif cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
        else:
            _intento_inicializacion_fallido = True
            return None

        _app = firebase_admin.initialize_app(cred)
    except Exception:
        _intento_inicializacion_fallido = True
        return None

    return _app

def enviar_push(tokens, titulo, mensaje, datos=None):
    """Envía una notificación push a una lista de tokens de dispositivo.
    Devuelve la lista de tokens que resultaron inválidos (para poder
    borrarlos de la base de datos y no seguir intentando enviarles)."""
    app = _obtener_app()

    if not app or not tokens:
        return []

    datos_str = {str(k): str(v) for k, v in (datos or {}).items() if v is not None}
    tokens_invalidos = []

    for token in tokens:
        mensaje_fcm = messaging.Message(
            notification=messaging.Notification(title=titulo, body=mensaje),
            data=datos_str,
            token=token,
        )

        try:
            messaging.send(mensaje_fcm, app=app)
        except (messaging.UnregisteredError, messaging.SenderIdMismatchError):
            tokens_invalidos.append(token)
        except Exception:
            # Un error puntual de red/FCM no debe romper la creación de la
            # notificación en la BD; simplemente ese envío se pierde.
            pass

    return tokens_invalidos