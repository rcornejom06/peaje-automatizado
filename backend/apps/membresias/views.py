from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from datetime import timedelta
from django.utils import timezone
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import PlanMembresia, Membresia
from .serializers import PlanMembresiaSerializer, MembresiaSerializer
from ..usuarios.permissions import obtener_rol_usuario

class PlanMembresiaViewSet(viewsets.ModelViewSet):
    serializer_class = PlanMembresiaSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]

        rol = obtener_rol_usuario(self.request.user)

        if rol == 'administrador':
            return [IsAuthenticated()]

        return[IsAuthenticated()]

    def ger_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == 'administrador':
            return PlanMembresia.objects.all().order_by("nombre")
        return PlanMembresia.objects.filter(estado=PlanMembresia.Estado.ACTIVO).order_by("nombre")


class MembresiaViewSet(viewsets.ModelViewSet):
    serializer_class = MembresiaSerializer
    permission_classes = [IsAuthenticated]

    def get_query(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol in ["administrador", "operador"]:
            return Membresia.objects.all().order_by("-fecha_creación")
        return Membresia.objects.filter(usuario=self.request.user).order_by("-fecha_creacion")

    @action(detail=False, methods=["post"], url_path="comprar")
    def comprar(self, request):
        plan_id = request.data.get("plan")
        rol = obtener_rol_usuario(self.request.user)

        if rol != "usuario":
            return Response(
                {"error": "Solo usuarios pueden comprar membresias."},
                status=status.HTTP_403_FORBIDDEN
            )

        if not plan_id:
            return Response(
                {"error": "El campo plan es obligatorio."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            plan = PlanMembresia.objects.get(
                id=plan_id,
                estado=PlanMembresia.Estado.ACTIVO
            )
        except PlanMembresia.DoesNotExist:
            return Response(
                {"error": "El plan de membresía no existe o está inactivo."},
                status=status.HTTP_404_NOT_FOUND
            )

        hoy = timezone.localdate()

        membresia_activa = Membresia.objects.filter(
            usuario=request.user,
            estado=Membresia.Estado.ACTIVA,
            fecha_inicio__lte=hoy,
            fecha_fin__gte=hoy,
            pases_restantes__gt=0
        ).first()

        if membresia_activa:
            return Response(
                {
                    "error": "El usuario ya tiene una membresía activa.",
                    "membresia_activa": MembresiaSerializer(membresia_activa).data,
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        from apps.pagos.models import Billetera, Transaccion

        billetera = Billetera.objects.filter(
            usuario=request.user,
            estado=Billetera.Estado.ACTIVA
        ).first()

        if not billetera:
            return Response(
                {"error": "El usuario no tiene una billetera activa."},
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
        billetera.save()

        fecha_inicio = hoy
        fecha_fin = hoy + timedelta(days=plan.duracion_dias)

        membresia = Membresia.objects.create(
            usuario=request.user,
            plan=plan,
            fecha_inicio=fecha_inicio,
            fecha_fin=fecha_fin,
            pases_restantes=plan.pases_incluidos,
            estado=Membresia.Estado.ACTIVA,
        )

        transaccion = Transaccion.objects.create(
            billetera=billetera,
            membresia=membresia,
            monto=plan.precio,
            tipo_transaccion=Transaccion.Tipo.COMPRA_MEMBRESIA,
            metodo_pago="Billetera virtual",
            referencia_pago=f"Compra de membresía {plan.nombre}",
            estado=Transaccion.Estado.APROBADA,
        )

        try:
            from apps.notificaciones.models import Notificacion

            Notificacion.objects.create(
                usuario=request.user,
                titulo="Membresía adquirida",
                mensaje=(
                    f"Has adquirido la membresía {plan.nombre} "
                    f"con {plan.pases_incluidos} pases disponibles."
                ),
                tipo=Notificacion.Tipo.MEMBRESIA,
            )
        except Exception:
            pass

        try:
            from apps.auditoria.models import HistorialUsuario

            HistorialUsuario.objects.create(
                usuario=request.user,
                accion="Compra de membresía",
                descripcion=(
                    f"El usuario compró la membresía {plan.nombre} "
                    f"por un valor de {plan.precio}."
                ),
                modulo="Membresías",
                dispositivo="API",
                estado=HistorialUsuario.Estado.EXITOSO,
            )
        except Exception:
            pass

        return Response(
            {
                "mensaje": "Membresía comprada correctamente.",
                "membresia": MembresiaSerializer(membresia).data,
                "saldo_actual": billetera.saldo,
                "transaccion_id": transaccion.id,
            },
            status=status.HTTP_201_CREATED
        )

    @action(detail=False, methods=["get"], url_path="mi-membresia-activa")
    def mi_membresia_activa(self, request):
        hoy = timezone.localdate()

        membresia = Membresia.objects.filter(
            usuario=request.user,
            estado=Membresia.Estado.ACTIVA,
            fecha_inicio__lte=hoy,
            fecha_fin__gte=hoy,
            pases_restantes__gt=0
        ).order_by("fecha_fin").first()

        if not membresia:
            return Response(
                {"mensaje": "El usuario no tiene una membresía activa."},
                status=status.HTTP_200_OK
            )

        return Response(
            {
                "membresia": MembresiaSerializer(membresia).data
            },
            status=status.HTTP_200_OK
        )