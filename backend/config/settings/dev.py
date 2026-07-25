from .base import *
import os


DEBUG = True

ALLOWED_HOSTS = ["localhost", "127.0.0.1", "0.0.0.0","*"]

CORS_ALLOW_ALL_ORIGINS = True

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"


# EMAIL - desarrollo
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"

EMAIL_HOST = "smtp.gmail.com"
EMAIL_PORT = 587
EMAIL_USE_TLS = True

EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD")
FRONTEND_URL = "http://localhost:5173"
DEFAULT_FROM_EMAIL = EMAIL_HOST_USER