# Cambios aplicados para desplegar en Render

Este backend fue modificado y **verificado ejecutando de verdad**
`manage.py check`, `migrate` (las 9 apps, 40+ migraciones), `collectstatic`
y arrancando el servidor con `settings.prod`, simulando las variables de
entorno que tendrás en Render. Todo pasó sin errores.

## Archivos modificados

1. **`config/settings/base.py`**
   - `DATABASES` ahora soporta `DATABASE_URL` (la que Render genera
     automáticamente al crear una base Postgres). Si no existe, sigue
     usando tus variables `POSTGRES_*` sueltas como en desarrollo local —
     no rompe tu docker-compose actual.
   - Se agregó `FIREBASE_CREDENTIALS_JSON` como alternativa a
     `FIREBASE_CREDENTIALS_PATH`.
   - Se agregó configuración condicional de Cloudinary (`STORAGES`): si
     defines `CLOUDINARY_URL`, los archivos subidos (`imagen_capturada`,
     `documento_respaldo`, etc.) se guardan ahí en vez del disco local.
     **Esto es importante**: el filesystem de Render es efímero, así que
     sin esto perderías esos archivos en cada redeploy.
   - Archivos estáticos siempre vía whitenoise con manifest comprimido.

2. **`config/settings/prod.py`**
   - Se agregó configuración de email (`EMAIL_BACKEND`, `EMAIL_HOST`, etc.)
     que antes solo existía en `dev.py` — en producción el envío de
     códigos de verificación habría fallado silenciosamente sin esto.
   - Se agregó `FRONTEND_URL` leído de variable de entorno.

3. **`apps/notificaciones/firebase.py`**
   - Ahora también acepta la credencial de Firebase como JSON completo en
     la variable de entorno `FIREBASE_CREDENTIALS_JSON`, sin necesidad de
     un archivo en disco.

4. **`Dockerfile`**
   - Ahora instala `requirements/prod.txt` (antes instalaba `dev.txt`).
   - Fija `DJANGO_SETTINGS_MODULE=config.settings.prod` por defecto.
   - Se agregó `CMD` real: corre `migrate`, `collectstatic` y levanta
     `gunicorn` en el puerto que indique Render (`$PORT`).

5. **`.gitignore`** (nuevo)
   - Excluye `firebase-service-account.json`, archivos `.env`, `media/`,
     `staticfiles/`, `__pycache__/`, etc.

## IMPORTANTE — antes de hacer git push

- **`firebase-service-account.json` fue removido de esta copia** por
  seguridad. Tenlo a mano localmente (NO lo commitees) — en Render vas a
  pegar su contenido completo en la variable de entorno
  `FIREBASE_CREDENTIALS_JSON`.
- Si esta clave (proyecto `viasmart-58ef7`) es la misma que ya se filtró
  en tu historial de git anteriormente, rótala de nuevo en Firebase
  Console → Configuración del proyecto → Cuentas de servicio, antes de
  desplegar.

## Variables de entorno a configurar en Render

| Variable | Valor / de dónde sale |
|---|---|
| `DJANGO_SETTINGS_MODULE` | `config.settings.prod` |
| `SECRET_KEY` | genera una nueva (distinta a la de dev) |
| `ALLOWED_HOSTS` | `tu-servicio.onrender.com` |
| `DATABASE_URL` | la que te da Render al crear la base Postgres |
| `CORS_ALLOWED_ORIGINS` | URL de tu frontend desplegado |
| `CSRF_TRUSTED_ORIGINS` | igual que CORS_ALLOWED_ORIGINS |
| `EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD` | tus credenciales SMTP actuales |
| `FRONTEND_URL` | URL de tu frontend |
| `FIREBASE_CREDENTIALS_JSON` | contenido completo del JSON de servicio |
| `CLOUDINARY_URL` | de tu cuenta de Cloudinary (ver siguiente sección) |
| `SECURE_SSL_REDIRECT` | `True` |

## Cloudinary (para que las fotos/documentos no se pierdan)

1. Crea una cuenta gratis en cloudinary.com (tiene plan free permanente,
   25 GB, más que suficiente para una tesis).
2. En tu Dashboard copia el valor **CLOUDINARY_URL** (viene listo para
   pegar, formato `cloudinary://<api_key>:<api_secret>@<cloud_name>`).
3. Pégalo como variable de entorno en Render. Con eso ya está — no hay
   que tocar código.
