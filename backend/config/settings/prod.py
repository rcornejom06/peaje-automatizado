from .base import *

DEBUG = False

ALLOWED_HOSTS = config("ALLOWED_HOSTS", default="").split(",")

CORS_ALLOW_ALL_ORIGINS = False

CORS_ALLOWED_ORIGINS = config(
    "CORS_ALLOWED_ORIGINS",
    default="https://tu-dominio.com"
).split(",")

CSRF_TRUSTED_ORIGINS = config(
    "CSRF_TRUSTED_ORIGINS",
    default="https://tu-dominio.com"
).split(",")

SECURE_SSL_REDIRECT = config("SECURE_SSL_REDIRECT", default=False, cast=bool)
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_AGE = 3600
SESSION_EXPIRE_AT_BROWSER_CLOSE = True
