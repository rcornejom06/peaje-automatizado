from rest_framework.routers import DefaultRouter
from .views import VehiculoViewSet, CategoriaVehiculoViewSet

router = DefaultRouter()
router.register(r"vehiculos", VehiculoViewSet, basename="vehiculos")
router.register(r"categorias", CategoriaVehiculoViewSet, basename="categorias-vehiculo")


urlpatterns = router.urls