from django.shortcuts import render
from django.contrib.auth.models import User
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import PerfilUsuario
from .serializers import UserSerializer, PerfilUsuarioSerializer, RegistroUsuarioSerializer
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

        telefono = request.data.get("telefono")
        cedula = request.data.get("cedula")
        first_name = request.data.get("first_name")
        last_name = request.data.get("last_name")
        email = request.data.get("email")

        if telefono is not None:
            perfil.telefono = telefono

        if cedula is not None:
            perfil.cedula = cedula

        perfil.save()

        user = request.user

        if first_name is not None:
            user.first_name = first_name

        if last_name is not None:
            user.last_name = last_name

        if email is not None:
            user.email = email

        user.save()

        return Response(
            {
                "mensaje": "Perfil actualizado correctamente.",
                "perfil": PerfilUsuarioSerializer(perfil).data,
            },
            status=status.HTTP_200_OK
        )

