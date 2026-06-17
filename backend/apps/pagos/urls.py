from rest_framework.routers import DefaultRouter
from .views import BilleteraViewSet, TransaccionViewSet

router = DefaultRouter()
router.register(r"billeteras", BilleteraViewSet, basename="billeteras")
router.register(r"transacciones", TransaccionViewSet, basename="transacciones")

urlpatterns = router.urls