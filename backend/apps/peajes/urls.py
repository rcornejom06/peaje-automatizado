from rest_framework.routers import DefaultRouter
from .views import PeajeViewSet, CamaraViewSet, PasoPeajeViewSet, TarifaPeajeCategoriaViewSet, ViaConcesionadaViewSet

router = DefaultRouter()

router.register(r"camaras", CamaraViewSet, basename="camaras")
router.register(r"pasos-peaje", PasoPeajeViewSet, basename="pasos-peaje")
router.register(r"tarifas-categoria", TarifaPeajeCategoriaViewSet, basename="tarifas-peaje-categoria")
router.register(r"vias-concesionadas",ViaConcesionadaViewSet,basename="vias-concesionadas")

router.register(r"", PeajeViewSet, basename="peajes")

urlpatterns = router.urls