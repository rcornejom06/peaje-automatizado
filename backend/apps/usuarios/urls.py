from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from . import views
from .views import UserViewSet, PerfilUsuarioViewSet

router = DefaultRouter()
router.register(r"perfiles", PerfilUsuarioViewSet, basename="perfiles")

router.register(r"", UserViewSet, basename="usuarios")

urlpatterns = [
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path(
        "verificar-correo-operador/",
        views.verificar_correo_operador,
        name="verificar-correo-operador",
    ),
    path("", include(router.urls)),
]
