from rest_framework.routers import DefaultRouter
from .views import (
    AvisoVehiculoRobadoViewSet,
    AlertaSeguridadViewSet,
    UbicacionDeteccionViewSet,
)

router = DefaultRouter()
router.register(r"avisos-robo", AvisoVehiculoRobadoViewSet, basename="avisos-robo")
router.register(r"alertas", AlertaSeguridadViewSet, basename="alertas-seguridad")
router.register(r"ubicaciones", UbicacionDeteccionViewSet, basename="ubicaciones-deteccion")

urlpatterns = router.urls