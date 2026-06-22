from django.db.models import Count, Sum, DecimalField
from decimal import Decimal
from django.db.models.functions import Coalesce
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from ..usuarios.permissions import obtener_rol_usuario
from ..peajes.models import PasoPeaje
from ..pagos.models import Transaccion
from ..seguridad.models import AlertaSeguridad
from ..membresias.models import Membresia


def validar_permiso_reportes(request):
    rol = obtener_rol_usuario(request.user)
    return rol in ["operador", "administrador"]


def aplicar_filtros_fecha(queryset, request, campo_fecha="fecha_hora"):
    fecha_inicio = request.query_params.get("fecha_inicio")
    fecha_fin = request.query_params.get("fecha_fin")

    if fecha_inicio:
        filtro = {f"{campo_fecha}__date__gte": fecha_inicio}
        queryset = queryset.filter(**filtro)

    if fecha_fin:
        filtro = {f"{campo_fecha}__date__lte": fecha_fin}
        queryset = queryset.filter(**filtro)

    return queryset


def respuesta_sin_permiso():
    return Response(
        {"error": "No tiene permisos para consultar reportes."},
        status=status.HTTP_403_FORBIDDEN
    )

def sumar_monto(queryset):
    total = queryset.aggregate(
        total=Coalesce(
            Sum("monto"),
            Decimal("0.00"),
            output_field=DecimalField(max_digits=12, decimal_places=2)
        )
    )["total"]

    return total


class ResumenReporteView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not validar_permiso_reportes(request):
            return respuesta_sin_permiso()

        pasos = aplicar_filtros_fecha(PasoPeaje.objects.all(), request)
        alertas = aplicar_filtros_fecha(AlertaSeguridad.objects.all(), request)
        transacciones = aplicar_filtros_fecha(Transaccion.objects.all(), request)

        total_pasos = pasos.count()
        total_alertas = alertas.count()
        total_vehiculos_detectados = pasos.values("placa_detectada").distinct().count()

        recaudacion_peajes = sumar_monto(
            transacciones.filter(
                estado=Transaccion.Estado.APROBADA,
                tipo_transaccion=Transaccion.Tipo.PAGO_PEAJE
            )
        )

        recaudacion_membresias = sumar_monto(
            transacciones.filter(
                estado=Transaccion.Estado.APROBADA,
                tipo_transaccion=Transaccion.Tipo.COMPRA_MEMBRESIA
            )
        )

        pasos_con_membresia = pasos.filter(
            estado_pago=PasoPeaje.EstadoPago.MEMBRESIA
        ).count()

        return Response(
            {
                "total_pasos": total_pasos,
                "total_alertas": total_alertas,
                "total_vehiculos_detectados": total_vehiculos_detectados,
                "recaudacion_peajes": recaudacion_peajes,
                "recaudacion_membresias": recaudacion_membresias,
                "recaudacion_total": recaudacion_peajes + recaudacion_membresias,
                "pasos_cubiertos_por_membresia": pasos_con_membresia,
            },
            status=status.HTTP_200_OK
        )


class RecaudacionReporteView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not validar_permiso_reportes(request):
            return respuesta_sin_permiso()

        transacciones = aplicar_filtros_fecha(Transaccion.objects.all(), request)

        recaudacion_peajes = sumar_monto(
            transacciones.filter(
                estado=Transaccion.Estado.APROBADA,
                tipo_transaccion=Transaccion.Tipo.PAGO_PEAJE
            )
        )

        recaudacion_membresias = sumar_monto(
            transacciones.filter(
                estado=Transaccion.Estado.APROBADA,
                tipo_transaccion=Transaccion.Tipo.COMPRA_MEMBRESIA
            )
        )

        recargas_billetera = sumar_monto(
            transacciones.filter(
                estado=Transaccion.Estado.APROBADA,
                tipo_transaccion=Transaccion.Tipo.RECARGA
            )
        )

        return Response(
            {
                "recaudacion_peajes": recaudacion_peajes,
                "recaudacion_membresias": recaudacion_membresias,
                "recaudacion_total": recaudacion_peajes + recaudacion_membresias,
                "recargas_billetera": recargas_billetera,
                "nota": "Las recargas de billetera se muestran aparte porque no representan cobro directo de peaje hasta que se consume el saldo.",
            },
            status=status.HTTP_200_OK
        )


class PasosPorPeajeReporteView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not validar_permiso_reportes(request):
            return respuesta_sin_permiso()

        pasos = aplicar_filtros_fecha(PasoPeaje.objects.all(), request)

        peaje_id = request.query_params.get("peaje")
        if peaje_id:
            pasos = pasos.filter(peaje_id=peaje_id)

        data = pasos.values(
            "peaje__id",
            "peaje__nombre",
            "peaje__ciudad",
        ).annotate(
            total_pasos=Count("id"),
            vehiculos_distintos=Count("placa_detectada", distinct=True),
        ).order_by("-total_pasos")

        return Response(
            list(data),
            status=status.HTTP_200_OK
        )


class AlertasReporteView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not validar_permiso_reportes(request):
            return respuesta_sin_permiso()

        alertas = aplicar_filtros_fecha(AlertaSeguridad.objects.all(), request)

        peaje_id = request.query_params.get("peaje")
        if peaje_id:
            alertas = alertas.filter(peaje_id=peaje_id)

        resumen_estado = alertas.values(
            "estado"
        ).annotate(
            total=Count("id")
        ).order_by("estado")

        resumen_peaje = alertas.values(
            "peaje__id",
            "peaje__nombre",
        ).annotate(
            total_alertas=Count("id")
        ).order_by("-total_alertas")

        return Response(
            {
                "total_alertas": alertas.count(),
                "por_estado": list(resumen_estado),
                "por_peaje": list(resumen_peaje),
            },
            status=status.HTTP_200_OK
        )


class VehiculosDetectadosReporteView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not validar_permiso_reportes(request):
            return respuesta_sin_permiso()

        pasos = aplicar_filtros_fecha(PasoPeaje.objects.all(), request)

        peaje_id = request.query_params.get("peaje")
        if peaje_id:
            pasos = pasos.filter(peaje_id=peaje_id)

        top_vehiculos = pasos.values(
            "placa_detectada"
        ).annotate(
            total_detecciones=Count("id")
        ).order_by("-total_detecciones")[:10]

        return Response(
            {
                "total_detecciones": pasos.count(),
                "vehiculos_distintos": pasos.values("placa_detectada").distinct().count(),
                "top_vehiculos_detectados": list(top_vehiculos),
            },
            status=status.HTTP_200_OK
        )


class UsoMembresiasReporteView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not validar_permiso_reportes(request):
            return respuesta_sin_permiso()

        pasos = aplicar_filtros_fecha(PasoPeaje.objects.all(), request)
        pasos_membresia = pasos.filter(
            estado_pago=PasoPeaje.EstadoPago.MEMBRESIA
        )

        membresias_activas = Membresia.objects.filter(
            estado=Membresia.Estado.ACTIVA,
            pases_restantes__gt=0
        )

        total_pases_restantes = membresias_activas.aggregate(
            total=Coalesce(Sum("pases_restantes"), 0)
        )["total"]

        uso_por_plan = pasos_membresia.values(
            "membresia_utilizada__plan__nombre"
        ).annotate(
            total_usos=Count("id")
        ).order_by("-total_usos")

        return Response(
            {
                "total_pasos_cubiertos_por_membresia": pasos_membresia.count(),
                "membresias_activas": membresias_activas.count(),
                "pases_restantes_totales": total_pases_restantes,
                "uso_por_plan": list(uso_por_plan),
            },
            status=status.HTTP_200_OK
        )