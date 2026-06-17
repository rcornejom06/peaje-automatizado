from rest_framework.routers import DefaultRouter
from .views import UserViewSet, PerfilUsuarioViewSet

router = DefaultRouter()
router.register(r"usuarios", UserViewSet, basename="usuarios")
router.register(r"perfiles", PerfilUsuarioViewSet, basename="perfiles")

urlpatterns = router.urls
