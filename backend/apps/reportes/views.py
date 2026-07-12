from decimal import Decimal

from django.db.models import Count, Sum, DecimalField
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


def respuesta_sin_permiso():
    return Response(
        {"error": "No tiene permisos para consultar reportes."},
        status=status.HTTP_403_FORBIDDEN
    )


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


def sumar_monto(queryset):
    total = queryset.aggregate(
        total=Coalesce(
            Sum("monto"),
            Decimal("0.00"),
            output_field=DecimalField(max_digits=12, decimal_places=2)
        )
    )["total"]

    return total or Decimal("0.00")


def decimal_a_str(valor):
    return str(valor or Decimal("0.00"))


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

        pasos_pagados = pasos.filter(estado_pago="pagado").count()
        pasos_membresia = pasos.filter(estado_pago="membresia").count()
        pasos_pendientes = pasos.filter(estado_pago="pendiente").count()
        pasos_fallidos = pasos.filter(estado_pago="fallido").count()

        pasos_alerta = pasos.filter(estado_seguridad="alerta").count()
        pasos_normales = pasos.filter(estado_seguridad="normal").count()

        recaudacion_peajes = sumar_monto(
            transacciones.filter(
                estado="aprobada",
                tipo_transaccion="pago_peaje"
            )
        )

        recaudacion_membresias = sumar_monto(
            transacciones.filter(
                estado="aprobada",
                tipo_transaccion="compra_membresia"
            )
        )

        recargas_billetera = sumar_monto(
            transacciones.filter(
                estado="aprobada",
                tipo_transaccion="recarga"
            )
        )

        return Response(
            {
                "total_pasos": total_pasos,
                "total_alertas": total_alertas,
                "total_vehiculos_detectados": total_vehiculos_detectados,

                "pasos_pagados": pasos_pagados,
                "pasos_cubiertos_por_membresia": pasos_membresia,
                "pasos_pendientes": pasos_pendientes,
                "pasos_fallidos": pasos_fallidos,

                "pasos_con_alerta": pasos_alerta,
                "pasos_normales": pasos_normales,

                "recaudacion_peajes": decimal_a_str(recaudacion_peajes),
                "recaudacion_membresias": decimal_a_str(recaudacion_membresias),
                "recaudacion_total": decimal_a_str(recaudacion_peajes + recaudacion_membresias),
                "recargas_billetera": decimal_a_str(recargas_billetera),
            },
            status=status.HTTP_200_OK
        )


class RecaudacionReporteView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not validar_permiso_reportes(request):
            return respuesta_sin_permiso()

        transacciones = aplicar_filtros_fecha(Transaccion.objects.all(), request)

        transacciones_aprobadas = transacciones.filter(estado="aprobada")
        transacciones_fallidas = transacciones.filter(estado="fallida")

        recaudacion_peajes = sumar_monto(
            transacciones_aprobadas.filter(tipo_transaccion="pago_peaje")
        )

        recaudacion_membresias = sumar_monto(
            transacciones_aprobadas.filter(tipo_transaccion="compra_membresia")
        )

        recargas_billetera = sumar_monto(
            transacciones_aprobadas.filter(tipo_transaccion="recarga")
        )

        pagos_por_billetera = sumar_monto(
            transacciones_aprobadas.filter(
                tipo_transaccion="pago_peaje",
                metodo_pago="billetera"
            )
        )

        usos_membresia = transacciones_aprobadas.filter(
            tipo_transaccion="uso_membresia"
        ).count()

        return Response(
            {
                "recaudacion_peajes": decimal_a_str(recaudacion_peajes),
                "recaudacion_membresias": decimal_a_str(recaudacion_membresias),
                "recaudacion_total": decimal_a_str(recaudacion_peajes + recaudacion_membresias),
                "recargas_billetera": decimal_a_str(recargas_billetera),
                "pagos_por_billetera": decimal_a_str(pagos_por_billetera),
                "usos_membresia": usos_membresia,
                "transacciones_aprobadas": transacciones_aprobadas.count(),
                "transacciones_fallidas": transacciones_fallidas.count(),
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
            pasos_pagados=Count("id", filter=None),
        ).order_by("-total_pasos")

        resultado = []

        for item in data:
            peaje_id_item = item["peaje__id"]

            pasos_peaje = pasos.filter(peaje_id=peaje_id_item)

            resultado.append({
                "peaje_id": item["peaje__id"],
                "peaje_nombre": item["peaje__nombre"],
                "peaje_ciudad": item["peaje__ciudad"],
                "total_pasos": item["total_pasos"],
                "vehiculos_distintos": item["vehiculos_distintos"],
                "pagados": pasos_peaje.filter(estado_pago="pagado").count(),
                "membresia": pasos_peaje.filter(estado_pago="membresia").count(),
                "pendientes": pasos_peaje.filter(estado_pago="pendiente").count(),
                "fallidos": pasos_peaje.filter(estado_pago="fallido").count(),
                "alertas": pasos_peaje.filter(estado_seguridad="alerta").count(),
            })

        return Response(resultado, status=status.HTTP_200_OK)


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

        resumen_tipo = alertas.values(
            "tipo_alerta"
        ).annotate(
            total=Count("id")
        ).order_by("-total")

        resumen_peaje = alertas.values(
            "peaje__id",
            "peaje__nombre",
        ).annotate(
            total_alertas=Count("id")
        ).order_by("-total_alertas")

        ultimas_alertas = alertas.order_by("-fecha_hora")[:10]

        ultimas = []

        for alerta in ultimas_alertas:
            ultimas.append({
                "id": alerta.id,
                "vehiculo": str(alerta.vehiculo) if alerta.vehiculo else None,
                "placa": alerta.vehiculo.placa if alerta.vehiculo else None,
                "peaje": alerta.peaje.nombre if alerta.peaje else None,
                "tipo_alerta": alerta.tipo_alerta,
                "estado": alerta.estado,
                "fecha_hora": alerta.fecha_hora,
                "descripcion": alerta.descripcion,
            })

        return Response(
            {
                "total_alertas": alertas.count(),
                "por_estado": list(resumen_estado),
                "por_tipo": list(resumen_tipo),
                "por_peaje": list(resumen_peaje),
                "ultimas_alertas": ultimas,
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

        ultimas_detecciones = pasos.order_by("-fecha_hora")[:10]

        ultimas = []

        for paso in ultimas_detecciones:
            ultimas.append({
                "id": paso.id,
                "placa_detectada": paso.placa_detectada,
                "vehiculo": str(paso.vehiculo) if paso.vehiculo else None,
                "peaje": paso.peaje.nombre if paso.peaje else None,
                "camara": paso.camara.codigo if paso.camara else None,
                "estado_pago": paso.estado_pago,
                "estado_seguridad": paso.estado_seguridad,
                "tarifa_aplicada": str(paso.tarifa_aplicada),
                "fecha_hora": paso.fecha_hora,
            })

        return Response(
            {
                "total_detecciones": pasos.count(),
                "vehiculos_distintos": pasos.values("placa_detectada").distinct().count(),
                "top_vehiculos_detectados": list(top_vehiculos),
                "ultimas_detecciones": ultimas,
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
            estado_pago="membresia"
        )

        membresias_activas = Membresia.objects.filter(
            estado="activa",
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

        ultimas_membresias = membresias_activas.order_by("-fecha_creacion")[:10]

        membresias_data = []

        for membresia in ultimas_membresias:
            membresias_data.append({
                "id": membresia.id,
                "usuario": membresia.usuario.username,
                "plan": membresia.plan.nombre,
                "estado": membresia.estado,
                "pases_restantes": membresia.pases_restantes,
                "fecha_inicio": membresia.fecha_inicio,
            })

        return Response(
            {
                "total_pasos_cubiertos_por_membresia": pasos_membresia.count(),
                "membresias_activas": membresias_activas.count(),
                "pases_restantes_totales": total_pases_restantes,
                "uso_por_plan": list(uso_por_plan),
                "membresias": membresias_data,
            },
            status=status.HTTP_200_OK
        )