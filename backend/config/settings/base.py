from decouple import config
from pathlib import Path
from datetime import timedelta


# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY', default='13051684135ed11fsr1gv35fds1vfes1-dev-key')
# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True
SESSION_EXPIRE_AT_BROWSER_CLOSE = True
ALLOWED_HOSTS = ['*','192.168.0.102']


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    #Third party
    'rest_framework',
    'rest_framework_simplejwt',
    'drf_spectacular',
    'corsheaders',

    #Local apps
    # Local apps
    "apps.usuarios.apps.UsuariosConfig",
    "apps.vehiculos.apps.VehiculosConfig",
    "apps.peajes.apps.PeajesConfig",
    "apps.pagos.apps.PagosConfig",
    "apps.membresias.apps.MembresiasConfig",
    "apps.seguridad.apps.SeguridadConfig",
    "apps.notificaciones.apps.NotificacionesConfig",
    "apps.auditoria.apps.AuditoriaConfig",
    "apps.reportes.apps.ReportesConfig",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = 'config.urls'


SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=1),
}

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'


# Database
# https://docs.djangoproject.com/en/5.2/ref/settings/#databases

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": config("POSTGRES_DB", default="peaje_db"),
        "USER": config("POSTGRES_USER", default="peaje_admin"),
        "PASSWORD": config("POSTGRES_PASSWORD", default="peaje_password"),
        "HOST": config("POSTGRES_HOST", default="localhost"),
        "PORT": config("POSTGRES_PORT", default="5432"),
    }
}


# Password validation
# https://docs.djangoproject.com/en/5.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/5.2/topics/i18n/

LANGUAGE_CODE = 'es-ec'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

REST_FRAMEWORK = {
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
}

SPECTACULAR_SETTINGS = {
    "TITLE": "API Sistema Inteligente de Peaje",
    "DESCRIPTION": "API para gestión de peajes, vehículos, pagos, alertas y monitoreo.",
    "VERSION": "1.0.0",
}

# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.2/howto/static-files/

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / "staticfiles"
# Default primary key field type
# https://docs.djangoproject.com/en/5.2/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"

# Firebase Cloud Messaging (notificaciones push a la app móvil)
# Descarga la clave desde Firebase Console -> Configuración del proyecto ->
# Cuentas de servicio -> Generar nueva clave privada. NUNCA subir este
# archivo a git; se referencia por ruta y se puede sobreescribir con la
# variable de entorno FIREBASE_CREDENTIALS_PATH en producción.
FIREBASE_CREDENTIALS_PATH = config(
    "FIREBASE_CREDENTIALS_PATH",
    default=str(BASE_DIR / "firebase-service-account.json"),
)