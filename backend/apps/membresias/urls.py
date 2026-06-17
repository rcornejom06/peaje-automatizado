from rest_framework.routers import DefaultRouter
from .views import PlanMembresiaViewSet, MembresiaViewSet

router = DefaultRouter()
router.register(r"planes", PlanMembresiaViewSet, basename="planes-membresia")
router.register(r"membresias", MembresiaViewSet, basename="membresias")

urlpatterns = router.urls