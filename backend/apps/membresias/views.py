from decimal import Decimal

from django.db import transaction
from django.utils import timezone
from rest_framework import viewsets, status, request
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import PlanMembresia, Membresia
from .serializers import PlanMembresiaSerializer, MembresiaSerializer
from ..notificaciones.models import Notificacion
from ..notificaciones.services import crear_notificacion
from ..usuarios.permissions import obtener_rol_usuario
from ..pagos.models import Billetera, Transaccion
from ..vehiculos.models import Vehiculo


class PlanMembresiaViewSet(viewsets.ModelViewSet):
    serializer_class = PlanMembresiaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == "administrador":
            return PlanMembresia.objects.all().order_by("nombre")

        return PlanMembresia.objects.filter(
            estado=PlanMembresia.Estado.ACTIVO
        ).order_by("nombre")

    def create(self, request, *args, **kwargs):
        rol = obtener_rol_usuario(request.user)

        if rol != "administrador":
            return Response(
                {"error": "No tiene permisos para crear planes de membresía."},
                status=status.HTTP_403_FORBIDDEN
            )

        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        rol = obtener_rol_usuario(request.user)

        if rol != "administrador":
            return Response(
                {"error": "No tiene permisos para editar planes de membresía."},
                status=status.HTTP_403_FORBIDDEN
            )

        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        rol = obtener_rol_usuario(request.user)

        if rol != "administrador":
            return Response(
                {"error": "No tiene permisos para editar planes de membresía."},
                status=status.HTTP_403_FORBIDDEN
            )

        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        rol = obtener_rol_usuario(request.user)

        if rol != "administrador":
            return Response(
                {"error": "No tiene permisos para eliminar planes de membresía."},
                status=status.HTTP_403_FORBIDDEN
            )

        return super().destroy(request, *args, **kwargs)


class MembresiaViewSet(viewsets.ModelViewSet):
    serializer_class = MembresiaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff or self.request.user.is_superuser:
            return Membresia.objects.select_related(
                "usuario",
                "plan"
            ).all().order_by("-fecha_creacion")

        return Membresia.objects.select_related(
            "usuario",
            "plan"
        ).filter(
            usuario=self.request.user
        ).order_by("-fecha_creacion")

    def create(self, request, *args, **kwargs):
        return Response(
            {
                "error": "Use el endpoint /api/membresias/comprar/ para adquirir una membresía."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar membresías directamente."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def partial_update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar membresías directamente."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def destroy(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite eliminar membresías."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    @action(detail=False, methods=["get"], url_path="mi-membresia-activa")
    def mi_membresia_activa(self, request):
        membresia = Membresia.objects.select_related("usuario", "plan").filter(
            usuario=request.user,
            estado=Membresia.Estado.ACTIVA,
            pases_restantes__gt=0,
        ).order_by("-fecha_creacion").first()

        if not membresia:
            return Response({}, status=status.HTTP_200_OK)

        serializer = self.get_serializer(membresia)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=False, methods=["post"], url_path="comprar")
    @transaction.atomic
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

        membresia_activa = Membresia.objects.select_for_update().filter(
            usuario=request.user,
            estado=Membresia.Estado.ACTIVA,
            pases_restantes__gt=0,
        ).exists()

        if membresia_activa:
            return Response(
                {
                    "error": "Ya tienes una membresía activa. No puedes adquirir otra hasta que finalice o se agoten sus pases."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        vehiculos_usuario = Vehiculo.objects.select_related("categoria").filter(
            usuario=request.user,
            estado=Vehiculo.Estado.ACTIVO,
            estado_revision=Vehiculo.EstadoRevision.APROBADO,
        )

        tiene_vehiculo_apto = any(
            self._categoria_aplica_membresia(vehiculo.categoria)
            for vehiculo in vehiculos_usuario
        )

        if not tiene_vehiculo_apto:
            return Response(
                {
                    "error": "La membresía solo aplica para vehículos livianos o de hasta 4 ejes. Los vehículos extrapesados pagan directamente desde la billetera."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        billetera, created = Billetera.objects.select_for_update().get_or_create(
            usuario=request.user,
            defaults={
                "saldo": Decimal("0.00"),
                "estado": Billetera.Estado.ACTIVA,
            }
        )

        if billetera.estado != Billetera.Estado.ACTIVA:
            return Response(
                {"error": "La billetera no está activa."},
                status=status.HTTP_400_BAD_REQUEST
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
        billetera.save(update_fields=["saldo"])

        membresia = Membresia.objects.create(
            usuario=request.user,
            plan=plan,
            fecha_inicio=timezone.now().date(),
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

        crear_notificacion(
            usuario=request.user,
            titulo="Membresía activada",
            mensaje=(
                f"Tu membresía fue activada correctamente. "
                f"Ya puedes usar tus pases disponibles."
            ),
            tipo=Notificacion.Tipo.MEMBRESIA,
            tipo_accion="membresias",
        )

        return Response(
            {
                "mensaje": "Membresía comprada correctamente.",
                "membresia": serializer.data,
                "saldo_actual": billetera.saldo,
            },
            status=status.HTTP_201_CREATED
        )

    def _categoria_aplica_membresia(self, categoria):
        if not categoria:
            return False

        if hasattr(categoria, "aplica_membresia"):
            return bool(categoria.aplica_membresia)

        nombre = (getattr(categoria, "nombre", "") or "").lower().strip()
        tipo = (getattr(categoria, "tipo", "") or "").lower().strip()
        ejes = getattr(categoria, "ejes", None)

        if "extrapesado" in nombre or tipo == "extrapesado":
            return False

        if ejes is not None:
            try:
                return int(ejes) <= 4
            except (TypeError, ValueError):
                return False

        categorias_validas = [
            "liviano",
            "auto",
            "automovil",
            "automóvil",
            "camioneta",
            "pesado",
        ]

        return any(valor in nombre for valor in categorias_validas)
