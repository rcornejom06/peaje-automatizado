from django.conf import settings
from django.db import models


class HistorialUsuario(models.Model):
    class Estado(models.TextChoices):
        EXITOSO = "exitoso", "Exitoso"
        FALLIDO = "fallido", "Fallido"
        PENDIENTE = "pendiente", "Pendiente"

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL,on_delete=models.SET_NULL,null=True,blank=True,related_name="historial")
    accion = models.CharField(max_length=120)
    descripcion = models.TextField(blank=True, null=True)
    modulo = models.CharField(max_length=80)
    direccion_ip = models.GenericIPAddressField(blank=True, null=True)
    dispositivo = models.CharField(max_length=100, blank=True, null=True)
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.EXITOSO)
    fecha_hora = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Historial de usuario"
        verbose_name_plural = "Historial de usuarios"
        ordering = ["-fecha_hora"]

    def __str__(self):
        usuario = self.usuario.username if self.usuario else "Sistema"
        return f"{usuario} - {self.accion}"