from django.shortcuts import render
from django.contrib.auth.models import User
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import PerfilUsuario
from .serializers import UserSerializer, PerfilUsuarioSerializer, RegistroUsuarioSerializer, \
    ActualizarMiPerfilSerializer
from rest_framework.decorators import action
from rest_framework.response import Response


# Create your views here.
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by("id")
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    @action(
        detail=False,
        methods=["post"],
        permission_classes=[AllowAny],
        url_path="registro"
    )
    def registro(self, request):
        serializer = RegistroUsuarioSerializer(data=request.data)

        if serializer.is_valid():
            user = serializer.save()

            return Response(
                {
                    "mensaje": "Usuario registrado correctamente.",
                    "usuario": UserSerializer(user).data,
                    "perfil": PerfilUsuarioSerializer(user.perfil).data,
                },
                status=status.HTTP_201_CREATED
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )


class PerfilUsuarioViewSet(viewsets.ModelViewSet):
    queryset = PerfilUsuario.objects.all().order_by("id")
    serializer_class = PerfilUsuarioSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["get"], url_path="mi-perfil")
    def mi_perfil(self, request):
        perfil = request.user.perfil

        return Response(
            PerfilUsuarioSerializer(perfil).data,
            status=status.HTTP_200_OK
        )

    @action(detail=False, methods=["patch"], url_path="actualizar-mi-perfil")
    def actualizar_mi_perfil(self, request):
        perfil = request.user.perfil

        serializer = ActualizarMiPerfilSerializer(
            perfil,
            data=request.data,
            partial=True,
            context={"request": request}
        )

        serializer.is_valid(raise_exception=True)
        serializer.save()

        perfil_actualizado = PerfilUsuarioSerializer(
            perfil,
            context={"request": request}
        )

        return Response(
            {
                "mensaje": "Perfil actualizado correctamente.",
                "perfil": perfil_actualizado.data,
            },
            status=status.HTTP_200_OK
        )
