from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import PlanMembresia, Membresia
from .serializers import PlanMembresiaSerializer, MembresiaSerializer


class PlanMembresiaViewSet(viewsets.ModelViewSet):
    queryset = PlanMembresia.objects.all().order_by("nombre")
    serializer_class = PlanMembresiaSerializer
    permission_classes = [IsAuthenticated]


class MembresiaViewSet(viewsets.ModelViewSet):
    queryset = Membresia.objects.all().order_by("-fecha_creacion")
    serializer_class = MembresiaSerializer
    permission_classes = [IsAuthenticated]