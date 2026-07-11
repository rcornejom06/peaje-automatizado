import random
from datetime import timezone, timedelta
from django.conf import settings
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model

User = get_user_model()

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
    correo_verificado = models.BooleanField(default=False)
    codigo_verificacion = models.CharField(max_length=6, blank=True, null=True)
    codigo_expira = models.DateTimeField(blank=True, null=True)
    requiere_cambio_password = models.BooleanField(default=False)

    class Meta:
        verbose_name = "Perfil de usuario"
        verbose_name_plural = "Perfiles de usuarios"

    def __str__(self):
        return f"{self.usuario.username} - {self.rol}"

    def generar_codigo_verificacion(self):
        codigo = str(random.randint(100000, 999999))
        self.codigo_verificacion = codigo
        self.codigo_expira = timezone.now() + timedelta(minutes=10)
        self.correo_verificado = False
        self.save()
        return codigo

    def codigo_es_valido(self, codigo):
        if not self.codigo_verificacion:
            return False

        if not self.codigo_expira:
            return False

        if timezone.now() > self.codigo_expira:
            return False

        return self.codigo_verificacion == codigo

@receiver(post_save, sender=User)
def crear_perfil_usuario(sender, instance, created, **kwargs):
    if created:
        PerfilUsuario.objects.get_or_create(usuario=instance)