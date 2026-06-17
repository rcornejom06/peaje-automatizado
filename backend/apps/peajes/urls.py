from rest_framework.routers import DefaultRouter
from .views import PeajeViewSet, CamaraViewSet, PasoPeajeViewSet

router = DefaultRouter()
router.register(r"peajes", PeajeViewSet, basename="peajes")
router.register(r"camaras", CamaraViewSet, basename="camaras")
router.register(r"pasos-peaje", PasoPeajeViewSet, basename="pasos-peaje")

urlpatterns = router.urls