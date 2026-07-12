
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
    pases_incluidos = models.PositiveIntegerField(default=30)
    descuento_porcentaje = models.DecimalField(max_digits=5,decimal_places=2,default=0.00)
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.ACTIVO)

    class Meta:
        verbose_name = "Plan de membresía"
        verbose_name_plural = "Planes de membresía"
        ordering = ["nombre"]

    def __str__(self):
        return f"{self.nombre} - {self.pases_incluidos} pases"


class Membresia(models.Model):
    class Estado(models.TextChoices):
        ACTIVA = "activa", "Activa"
        VENCIDA = "vencida", "Vencida"
        CANCELADA = "cancelada", "Cancelada"

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL,on_delete=models.CASCADE,related_name="membresias")
    plan = models.ForeignKey(PlanMembresia,on_delete=models.PROTECT,related_name="membresias")
    fecha_inicio = models.DateField()
    pases_restantes = models.PositiveIntegerField(default=0)
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.ACTIVA)
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Membresía"
        verbose_name_plural = "Membresías"
        ordering = ["-fecha_creacion"]

    def save(self, *args, **kwargs):
        if not self.pk and self.pases_restantes == 0:
            self.pases_restantes = self.plan.pases_incluidos
        super().save(*args, **kwargs)

    def consumir_pase(self):
        if self.pases_restantes > 0:
            self.pases_restantes -= 1

            if self.pases_restantes == 0:
                self.estado = self.Estado.VENCIDA

            self.save()

    def __str__(self):
        return f"{self.usuario.username} - {self.plan.nombre} - {self.pases_restantes} pases"