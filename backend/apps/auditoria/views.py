from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from ..usuarios.permissions import obtener_rol_usuario
from .models import HistorialUsuario
from .serializers import HistorialUsuarioSerializer
from rest_framework.response import Response
from rest_framework.decorators import action

class HistorialUsuarioViewSet(viewsets.ModelViewSet):
    serializer_class = HistorialUsuarioSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == "administrador":
            return HistorialUsuario.objects.all().order_by("-fecha_hora_hora")

        return HistorialUsuario.objects.filter(
            usuario=self.request.user
        ).order_by("-fecha_hora_hora")

    @action(detail=False, methods=["get"], url_path="mi-historial")
    def mi_historial(self, request):
        historial = HistorialUsuario.objects.filter(
            usuario=request.user
        ).order_by("-fecha_hora")

        serializer = self.get_serializer(historial, many=True)

        return Response(
            {
                "total": historial.count(),
                "historial": serializer.data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=False, methods=["get"], url_path="por-modulo")
    def por_modulo(self, request):
        rol = obtener_rol_usuario(request.user)

        if rol != "administrador":
            return Response(
                {"error": "Solo el administrador puede consultar historial por módulo."},
                status=status.HTTP_403_FORBIDDEN
            )

        modulo = request.query_params.get("modulo")

        if not modulo:
            return Response(
                {"error": "El parámetro modulo es obligatorio."},
                status=status.HTTP_400_BAD_REQUEST
            )

        historial = HistorialUsuario.objects.filter(
            modulo__icontains=modulo
        ).order_by("-fecha_hora")

        serializer = self.get_serializer(historial, many=True)

        return Response(
            {
                "modulo": modulo,
                "total": historial.count(),
                "historial": serializer.data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=False, methods=["get"], url_path="por-usuario")
    def por_usuario(self, request):
        rol = obtener_rol_usuario(request.user)

        if rol != "administrador":
            return Response(
                {"error": "Solo el administrador puede consultar historial por usuario."},
                status=status.HTTP_403_FORBIDDEN
            )

        usuario_id = request.query_params.get("usuario")

        if not usuario_id:
            return Response(
                {"error": "El parámetro usuario es obligatorio."},
                status=status.HTTP_400_BAD_REQUEST
            )

        historial = HistorialUsuario.objects.filter(
            usuario_id=usuario_id
        ).order_by("-fecha_hora")

        serializer = self.get_serializer(historial, many=True)

        return Response(
            {
                "usuario": usuario_id,
                "total": historial.count(),
                "historial": serializer.data,
            },
            status=status.HTTP_200_OK
        )