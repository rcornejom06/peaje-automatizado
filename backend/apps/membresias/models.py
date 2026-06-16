from django.conf import settings
from django.db import models


class PlanMembresia(models.Model):
    class Estado(models.TextChoices):
        ACTIVO = "activo", "Activo"
        INACTIVO = "inactivo", "Inactivo"

    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True, null=True)
    precio = models.DecimalField(max_digits=10, decimal_places=2)
    duracion_dias = models.PositiveIntegerField()
    descuento_porcentaje = models.DecimalField(max_digits=5,decimal_places=2,default=0.00)
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.ACTIVO)

    class Meta:
        verbose_name = "Plan de membresía"
        verbose_name_plural = "Planes de membresía"
        ordering = ["nombre"]

    def __str__(self):
        return self.nombre


class Membresia(models.Model):
    class Estado(models.TextChoices):
        ACTIVA = "activa", "Activa"
        VENCIDA = "vencida", "Vencida"
        CANCELADA = "cancelada", "Cancelada"

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL,on_delete=models.CASCADE,related_name="membresias")
    plan = models.ForeignKey(PlanMembresia,on_delete=models.PROTECT,related_name="membresias")
    fecha_inicio = models.DateField()
    fecha_fin = models.DateField()
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.ACTIVA)
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Membresía"
        verbose_name_plural = "Membresías"
        ordering = ["-fecha_creacion"]

    def __str__(self):
        return f"{self.usuario.username} - {self.plan.nombre}"