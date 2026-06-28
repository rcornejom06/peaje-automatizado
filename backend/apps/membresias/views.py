from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from datetime import timedelta
from django.utils import timezone
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import PlanMembresia, Membresia
from .serializers import PlanMembresiaSerializer, MembresiaSerializer
from ..usuarios.permissions import obtener_rol_usuario
from ..pagos.models import (Billetera, Transaccion)
from ..notificaciones.models import Notificacion
from ..auditoria.utils import registrar_historial


class PlanMembresiaViewSet(viewsets.ModelViewSet):
    queryset = PlanMembresia.objects.all()
    serializer_class = PlanMembresiaSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]

        rol = obtener_rol_usuario(self.request.user)

        if rol == 'administrador':
            return [IsAuthenticated()]

        return[IsAuthenticated()]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == 'administrador':
            return PlanMembresia.objects.all().order_by("nombre")
        return PlanMembresia.objects.filter(estado=PlanMembresia.Estado.ACTIVO).order_by("nombre")


class MembresiaViewSet(viewsets.ModelViewSet):
    serializer_class = MembresiaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff or self.request.user.is_superuser:
            return Membresia.objects.select_related("usuario", "plan").all().order_by("-fecha_creacion")

        return Membresia.objects.select_related("usuario", "plan").filter(
            usuario=self.request.user
        ).order_by("-fecha_creacion")

    @action(detail=False, methods=["get"], url_path="mi-membresia-activa")
    def mi_membresia_activa(self, request):
        membresia = Membresia.objects.select_related("usuario", "plan").filter(
            usuario=request.user,
            estado=Membresia.Estado.ACTIVA,
            pases_restantes__gt=0,
            fecha_fin__gte=timezone.now().date(),
        ).order_by("-fecha_creacion").first()

        if not membresia:
            return Response(
                {"mensaje": "No tiene membresía activa."},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = self.get_serializer(membresia)

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )