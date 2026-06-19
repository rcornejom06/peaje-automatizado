from rest_framework import viewsets,status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..usuarios.permissions import obtener_rol_usuario
from .models import Notificacion
from .serializers import NotificacionSerializer


class NotificacionViewSet(viewsets.ModelViewSet):
    serializer_class = NotificacionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol == "administrador":
            return Notificacion.objects.all().order_by("-fecha_hora")

        return Notificacion.objects.filter(
            usuario=self.request.user
        ).order_by("-fecha_hora")

    @action(detail=False, methods=["get"], url_path="mis-notificaciones")
    def mis_notificaciones(self, request):
        notificaciones = Notificacion.objects.filter(
            usuario=request.user
        ).order_by("-fecha_hora")

        serializer = self.get_serializer(notificaciones, many=True)

        return Response(
            {
                "total": notificaciones.count(),
                "notificaciones": serializer.data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=False, methods=["get"], url_path="no-leidas")
    def no_leidas(self, request):
        notificaciones = Notificacion.objects.filter(
            usuario=request.user,
            leida=False
        ).order_by("-fecha_hora")

        serializer = self.get_serializer(notificaciones, many=True)

        return Response(
            {
                "total_no_leidas": notificaciones.count(),
                "notificaciones": serializer.data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=["patch"], url_path="marcar-leida")
    def marcar_leida(self, request, pk=None):
        notificacion = self.get_object()

        if notificacion.usuario != request.user and obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "No puede modificar una notificación de otro usuario."},
                status=status.HTTP_403_FORBIDDEN
            )

        if notificacion.leida:
            return Response(
                {
                    "mensaje": "La notificación ya estaba marcada como leída.",
                    "notificacion": self.get_serializer(notificacion).data,
                },
                status=status.HTTP_200_OK
            )

        notificacion.leida = True
        notificacion.save()

        return Response(
            {
                "mensaje": "Notificación marcada como leída.",
                "notificacion": self.get_serializer(notificacion).data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=False, methods=["patch"], url_path="marcar-todas-leidas")
    def marcar_todas_leidas(self, request):
        notificaciones = Notificacion.objects.filter(
            usuario=request.user,
            leida=False
        )

        total = notificaciones.count()

        notificaciones.update(leida=True)

        return Response(
            {
                "mensaje": "Todas las notificaciones fueron marcadas como leídas.",
                "total_actualizadas": total,
            },
            status=status.HTTP_200_OK
        )