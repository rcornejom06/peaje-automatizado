from django.conf import settings
from django.db import models


class Notificacion(models.Model):
    class Tipo(models.TextChoices):
        PAGO = "pago", "Pago"
        ALERTA = "alerta", "Alerta"
        MEMBRESIA = "membresia", "Membresía"
        SISTEMA = "sistema", "Sistema"

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL,on_delete=models.CASCADE,related_name="notificaciones")
    alerta = models.ForeignKey("seguridad.AlertaSeguridad",on_delete=models.SET_NULL,null=True,blank=True,related_name="notificaciones")
    titulo = models.CharField(max_length=150)
    mensaje = models.TextField()
    tipo = models.CharField(max_length=20,choices=Tipo.choices,default=Tipo.SISTEMA)
    leida = models.BooleanField(default=False)
    fecha_hora = models.DateTimeField(auto_now_add=True)
    url_accion = models.URLField(blank=True, null=True)
    tipo_accion = models.CharField(max_length=50, blank=True, null=True)

    class Meta:
        verbose_name = "Notificación"
        verbose_name_plural = "Notificaciones"
        ordering = ["-fecha_hora"]

    def __str__(self):
        return f"{self.titulo} - {self.usuario.username}"