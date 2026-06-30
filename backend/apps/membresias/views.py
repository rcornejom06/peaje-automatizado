from decimal import Decimal
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import PlanMembresia, Membresia
from .serializers import PlanMembresiaSerializer, MembresiaSerializer
from ..usuarios.permissions import obtener_rol_usuario
from ..pagos.models import Billetera, Transaccion

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
        ).order_by("-fecha_creacion").first()

        if not membresia:
            return Response(
                {"mensaje": "No tiene membresía activa."},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = self.get_serializer(membresia)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=False, methods=["post"], url_path="comprar")
    def comprar(self, request):
        plan_id = request.data.get("plan_id") or request.data.get("plan")

        if not plan_id:
            return Response(
                {"error": "Debe enviar el plan_id."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            plan = PlanMembresia.objects.get(
                id=plan_id,
                estado=PlanMembresia.Estado.ACTIVO
            )
        except PlanMembresia.DoesNotExist:
            return Response(
                {"error": "El plan de membresía no existe o no está activo."},
                status=status.HTTP_404_NOT_FOUND
            )

        billetera, created = Billetera.objects.get_or_create(
            usuario=request.user,
            defaults={
                "saldo": Decimal("0.00"),
                "estado": Billetera.Estado.ACTIVA
            }
        )

        if billetera.saldo < plan.precio:
            return Response(
                {
                    "error": "Saldo insuficiente para comprar la membresía.",
                    "saldo_actual": billetera.saldo,
                    "precio_plan": plan.precio,
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        billetera.saldo -= plan.precio
        billetera.save()

        membresia = Membresia.objects.create(
            usuario=request.user,
            plan=plan,
            fecha_inicio=timezone.now().date(),
            fecha_fin=None,
            pases_restantes=plan.pases_incluidos,
            estado=Membresia.Estado.ACTIVA,
        )

        Transaccion.objects.create(
            billetera=billetera,
            membresia=membresia,
            monto=plan.precio,
            tipo_transaccion=Transaccion.Tipo.COMPRA_MEMBRESIA,
            metodo_pago="Billetera virtual",
            referencia_pago=f"COMPRA-MEMBRESIA-{membresia.id}",
            estado=Transaccion.Estado.APROBADA,
        )

        serializer = self.get_serializer(membresia)

        return Response(
            {
                "mensaje": "Membresía comprada correctamente.",
                "membresia": serializer.data,
                "saldo_actual": billetera.saldo,
            },
            status=status.HTTP_201_CREATED
        )