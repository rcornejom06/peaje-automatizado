from rest_framework import viewsets, status
from ..usuarios.permissions import obtener_rol_usuario
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from decimal import Decimal, InvalidOperation
from rest_framework.decorators import action
from .models import Billetera, Transaccion
from .serializers import BilleteraSerializer, TransaccionSerializer
from ..auditoria.utils import registrar_historial


class BilleteraViewSet(viewsets.ModelViewSet):
    serializer_class = BilleteraSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == 'administrador':
            return Billetera.objects.all().order_by("id")
        return Billetera.objects.filter(usuario=self.request.user).order_by("id")

    @action(detail=False, methods=['post'], url_path='recargar')
    def recargar(self, request):
        monto = request.data.get('monto')
        metodo_pago = request.data.get('metodo_pago',"PayPhone simulado")
        referencia_pago = request.data.get('referencia_pago', "")

        if not monto:
            return Response({"error": "El campo 'monto' es obligatorio."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            monto_decimal = Decimal(str(monto))
        except (InvalidOperation,ValueError):
            return Response({"error": "El monto no es válido. "}, status=status.HTTP_400_BAD_REQUEST)
        if monto_decimal < 0:
            return Response({"error": "El monto debe ser mayor a 0."}, status=status.HTTP_400_BAD_REQUEST)

        billetera, _= Billetera.objects.get_or_create(
            usuario=request.user,
        defaults={
            "saldo": Decimal("0.00"),
            "estado": Billetera.Estado.ACTIVA
            }
        )
        billetera.saldo += monto_decimal
        billetera.save()

        transaccion, _= Transaccion.objects.create(
            billetera=billetera,
            monto=monto_decimal,
            tipo_transaccion=Transaccion.Tipo.RECARGA,
            metodo_pago=metodo_pago,
            referencia_pago=referencia_pago,
            estado=Transaccion.Estado.APROBADA,
        )

        registrar_historial(
            usuario=request.user,
            accion="Recarga de billetera",
            descripcion=f"El usuario recargó su billetera con un monto de {monto_decimal}.",
            modulo="Pagos",
            request=request,
        )


        return Response(
            {
                "mensaje": f"Recarga exitosa. Nuevo saldo: {billetera.saldo}",
                "saldo_actual": billetera.saldo,
                "transaccion": TransaccionSerializer(transaccion).data,
            },
            status=status.HTTP_200_OK
        )


class TransaccionViewSet(viewsets.ModelViewSet):
    serializer_class = TransaccionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == 'administrador':
            return Transaccion.objects.all().order_by("-fecha_hora")

        return Transaccion.objects.filter(billetera__usuario=self.request.user).order_by("-fecha_hora")