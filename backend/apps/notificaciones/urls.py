from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import NotificacionViewSet, registrar_token_push

router = DefaultRouter()
router.register(r"", NotificacionViewSet, basename="notificaciones")

urlpatterns = [
    path(
        "dispositivos/registrar-token/",
        registrar_token_push,
        name="registrar-token-push",
    ),
] + router.urls