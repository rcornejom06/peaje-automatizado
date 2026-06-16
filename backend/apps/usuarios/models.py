from django.conf import settings
from django.db import models


class PerfilUsuario(models.Model):
    class Rol(models.TextChoices):
        USUARIO = "usuario", "Usuario"
        OPERADOR = "operador", "Operador"
        ADMINISTRADOR = "administrador", "Administrador"

    usuario = models.OneToOneField(settings.AUTH_USER_MODEL,on_delete=models.CASCADE,related_name="perfil")
    telefono = models.CharField(max_length=20, blank=True, null=True)
    cedula = models.CharField(max_length=20, blank=True, null=True)
    rol = models.CharField(max_length=20,choices=Rol.choices,default=Rol.USUARIO)
    estado = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Perfil de usuario"
        verbose_name_plural = "Perfiles de usuarios"

    def __str__(self):
        return f"{self.usuario.username} - {self.rol}"
