from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import Billetera, Transaccion
from .serializers import BilleteraSerializer, TransaccionSerializer


class BilleteraViewSet(viewsets.ModelViewSet):
    queryset = Billetera.objects.all().order_by("id")
    serializer_class = BilleteraSerializer
    permission_classes = [IsAuthenticated]


class TransaccionViewSet(viewsets.ModelViewSet):
    queryset = Transaccion.objects.all().order_by("-fecha_hora")
    serializer_class = TransaccionSerializer
    permission_classes = [IsAuthenticated]