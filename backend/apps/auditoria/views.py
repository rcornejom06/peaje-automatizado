from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.decorators import action
from ..usuarios.permissions import obtener_rol_usuario
from .models import HistorialUsuario
from .serializers import HistorialUsuarioSerializer


class HistorialUsuarioViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = HistorialUsuarioSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        queryset = HistorialUsuario.objects.select_related("usuario").all()

        if rol in ["administrador", "operador"]:
            return queryset.order_by("-fecha_hora")

        return queryset.filter(usuario=self.request.user).order_by("-fecha_hora")

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()

        modulo = request.query_params.get("modulo")
        estado = request.query_params.get("estado")
        accion = request.query_params.get("accion")
        fecha_inicio = request.query_params.get("fecha_inicio")
        fecha_fin = request.query_params.get("fecha_fin")

        if modulo:
            queryset = queryset.filter(modulo__icontains=modulo)

        if estado:
            queryset = queryset.filter(estado=estado)

        if accion:
            queryset = queryset.filter(accion__icontains=accion)

        if fecha_inicio:
            queryset = queryset.filter(fecha_hora__date__gte=fecha_inicio)

        if fecha_fin:
            queryset = queryset.filter(fecha_hora__date__lte=fecha_fin)

        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)

        return Response(serializer.data)

    @action(detail=False, methods=["get"], url_path="resumen")
    def resumen(self, request):
        queryset = self.get_queryset()

        total = queryset.count()
        exitosos = queryset.filter(estado=HistorialUsuario.Estado.EXITOSO).count()
        fallidos = queryset.filter(estado=HistorialUsuario.Estado.FALLIDO).count()
        pendientes = queryset.filter(estado=HistorialUsuario.Estado.PENDIENTE).count()

        por_modulo = (
            queryset
            .values("modulo")
            .order_by("modulo")
        )

        resumen_modulo = {}

        for item in por_modulo:
            modulo = item["modulo"] or "Sin módulo"
            resumen_modulo[modulo] = resumen_modulo.get(modulo, 0) + 1

        return Response(
            {
                "total": total,
                "exitosos": exitosos,
                "fallidos": fallidos,
                "pendientes": pendientes,
                "por_modulo": resumen_modulo,
            }
        )