from rest_framework.permissions import BasePermission


def obtener_rol_usuario(user):
    if not user or not user.is_authenticated:
        return None

    if user.is_superuser:
        return "administrador"

    if hasattr(user, "perfil"):
        return user.perfil.rol

    return None


class EsAdministrador(BasePermission):
    def has_permission(self, request, view):
        return obtener_rol_usuario(request.user) == "administrador"


class EsOperador(BasePermission):
    def has_permission(self, request, view):
        return obtener_rol_usuario(request.user) == "operador"


class EsUsuario(BasePermission):
    def has_permission(self, request, view):
        return obtener_rol_usuario(request.user) == "usuario"


class EsOperadorOAdministrador(BasePermission):
    def has_permission(self, request, view):
        rol = obtener_rol_usuario(request.user)
        return rol in ["operador", "administrador"]


class EsUsuarioOAdministrador(BasePermission):
    def has_permission(self, request, view):
        rol = obtener_rol_usuario(request.user)
        return rol in ["usuario", "administrador"]


class EsCualquierRolAutenticado(BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated