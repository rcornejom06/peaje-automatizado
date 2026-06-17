from rest_framework.routers import DefaultRouter
from .views import HistorialUsuarioViewSet

router = DefaultRouter()
router.register(r"historial", HistorialUsuarioViewSet, basename="historial-usuario")

urlpatterns = router.urls