from rest_framework.routers import DefaultRouter
from .views import VehiculoViewSet, CategoriaVehiculoViewSet

router = DefaultRouter()

router.register(r"categorias", CategoriaVehiculoViewSet, basename="categorias-vehiculo")

router.register(r"", VehiculoViewSet, basename="vehiculos")


urlpatterns = router.urls