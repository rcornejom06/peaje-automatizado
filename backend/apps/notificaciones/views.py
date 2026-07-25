from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import DispositivoPush, Notificacion
from .serializers import DispositivoPushSerializer, NotificacionSerializer


class NotificacionViewSet(viewsets.ModelViewSet):
    serializer_class = NotificacionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notificacion.objects.filter(
            usuario=self.request.user
        ).order_by("-fecha_hora")

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)

    @action(detail=False, methods=["get"], url_path="no-leidas")
    def no_leidas(self, request):
        total = Notificacion.objects.filter(
            usuario=request.user,
            leida=False
        ).count()

        return Response(
            {
                "no_leidas": total
            },
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=["patch"], url_path="marcar-leida")
    def marcar_leida(self, request, pk=None):
        notificacion = self.get_object()
        notificacion.leida = True
        notificacion.save(update_fields=["leida"])

        return Response(
            {
                "mensaje": "Notificación marcada como leída.",
                "notificacion": NotificacionSerializer(notificacion).data,
            },
            status=status.HTTP_200_OK
        )

    @action(detail=False, methods=["patch"], url_path="marcar-todas-leidas")
    def marcar_todas_leidas(self, request):
        total = Notificacion.objects.filter(
            usuario=request.user,
            leida=False
        ).update(leida=True)

        return Response(
            {
                "mensaje": "Todas las notificaciones fueron marcadas como leídas.",
                "actualizadas": total,
            },
            status=status.HTTP_200_OK
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def registrar_token_push(request):
    serializer = DispositivoPushSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    DispositivoPush.objects.update_or_create(
        token=serializer.validated_data["token"],
        defaults={
            "usuario": request.user,
            "plataforma": serializer.validated_data.get("plataforma", "android"),
        },
    )

    return Response(
        {"mensaje": "Token de notificaciones registrado correctamente."},
        status=status.HTTP_200_OK,
    )