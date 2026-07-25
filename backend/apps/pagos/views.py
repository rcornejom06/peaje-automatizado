from django.db import transaction
from rest_framework import viewsets, status
from ..usuarios.permissions import obtener_rol_usuario
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from decimal import Decimal
from rest_framework.decorators import action
from .models import Billetera, Transaccion, TarjetaBancaria
from .serializers import BilleteraSerializer, TransaccionSerializer, RecargaConTarjetaSerializer, \
    TarjetaBancariaSerializer, CrearTarjetaBancariaSerializer
from ..auditoria.utils import registrar_historial


class TarjetaBancariaViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return TarjetaBancaria.objects.filter(
            usuario=self.request.user
        ).order_by("-principal", "-fecha_creacion")

    def get_serializer_class(self):
        if self.action == "create":
            return CrearTarjetaBancariaSerializer

        return TarjetaBancariaSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(
            data=request.data,
            context={"request": request}
        )
        serializer.is_valid(raise_exception=True)

        tarjeta = serializer.save()

        return Response(
            TarjetaBancariaSerializer(tarjeta).data,
            status=status.HTTP_201_CREATED
        )

    def destroy(self, request, *args, **kwargs):
        tarjeta = self.get_object()
        tarjeta.estado = TarjetaBancaria.Estado.INACTIVA
        tarjeta.principal = False
        tarjeta.save(update_fields=["estado", "principal"])

        return Response(
            {"mensaje": "Tarjeta eliminada correctamente."},
            status=status.HTTP_200_OK
        )


class BilleteraViewSet(viewsets.ModelViewSet):
    serializer_class = BilleteraSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == "administrador":
            return Billetera.objects.select_related("usuario").all().order_by("id")

        return Billetera.objects.select_related("usuario").filter(
            usuario=self.request.user
        ).order_by("id")

    def create(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite crear billeteras directamente. Use el endpoint /api/pagos/billeteras/mi-billetera/."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar billeteras directamente."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def partial_update(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite modificar billeteras directamente."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def destroy(self, request, *args, **kwargs):
        return Response(
            {
                "error": "No se permite eliminar billeteras."
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    @action(detail=False, methods=["get"], url_path="mi-billetera")
    def mi_billetera(self, request):
        billetera, created = Billetera.objects.get_or_create(
            usuario=request.user,
            defaults={
                "saldo": Decimal("0.00"),
                "estado": Billetera.Estado.ACTIVA,
            },
        )

        serializer = self.get_serializer(billetera)

        return Response(
            serializer.data,
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["post"], url_path="recargar")
    @transaction.atomic
    def recargar(self, request):
        serializer = RecargaConTarjetaSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        monto = serializer.validated_data["monto"]
        tarjeta_id = serializer.validated_data["tarjeta_id"]

        try:
            tarjeta = TarjetaBancaria.objects.select_for_update().get(
                id=tarjeta_id,
                usuario=request.user,
                estado=TarjetaBancaria.Estado.ACTIVA,
            )
        except TarjetaBancaria.DoesNotExist:
            return Response(
                {"error": "La tarjeta bancaria no existe o no está activa."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if tarjeta.esta_vencida():
            return Response(
                {"error": "La tarjeta bancaria está vencida."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        billetera, _ = Billetera.objects.select_for_update().get_or_create(
            usuario=request.user,
            defaults={
                "saldo": Decimal("0.00"),
                "estado": Billetera.Estado.ACTIVA,
            },
        )

        if billetera.estado != Billetera.Estado.ACTIVA:
            return Response(
                {"error": "La billetera no está activa."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        billetera.saldo += monto
        billetera.save(update_fields=["saldo", "fecha_actualizacion"])

        transaccion = Transaccion.objects.create(
            billetera=billetera,
            monto=monto,
            tipo_transaccion=Transaccion.Tipo.RECARGA,
            metodo_pago=f"Tarjeta {tarjeta.get_marca_display()} terminada en {tarjeta.ultimos4}",
            referencia_pago=f"TARJETA-{tarjeta.id}-RECARGA",
            estado=Transaccion.Estado.APROBADA,
        )

        registrar_historial(
            usuario=request.user,
            accion="Recarga de billetera",
            descripcion=f"El usuario recargó ${monto} en su billetera.",
            modulo="Pagos",
            request=request,
        )

        return Response(
            {
                "mensaje": "Recarga realizada correctamente.",
                "saldo_actual": str(billetera.saldo),
                "tarjeta": TarjetaBancariaSerializer(tarjeta).data,
                "transaccion": TransaccionSerializer(transaccion).data,
            },
            status=status.HTTP_200_OK,
        )


class TransaccionViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = TransaccionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        queryset = Transaccion.objects.select_related(
            "billetera",
            "billetera__usuario",
            "paso_peaje",
            "membresia",
        ).order_by("-fecha_hora")

        if rol == "administrador":
            return queryset

        return queryset.filter(billetera__usuario=self.request.user)
