from rest_framework.routers import DefaultRouter
from .views import BilleteraViewSet, TransaccionViewSet, TarjetaBancariaViewSet

router = DefaultRouter()
router.register(r"billeteras", BilleteraViewSet, basename="billeteras")
router.register(r"transacciones", TransaccionViewSet, basename="transacciones")
router.register(r"tarjetas", TarjetaBancariaViewSet, basename="tarjetas")

urlpatterns = router.urls