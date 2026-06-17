from django.conf import settings
from django.db import models

class CategoriaVehiculo(models.Model):
    class Tipo(models.TextChoices):
        LIVIANO = "liviando", "Liviano"
        PESADO = "pesado", "Pesado"
        EXTRAPESADO = "extrapesado", "Extrapesado"
    nombre = models.CharField(max_length=100)
    tipo = models.CharField(max_length=20, choices=Tipo.choices)
    numero_ejes = models.PositiveIntegerField()
    tarifa = models.DecimalField(max_digits=8, decimal_places=2)
    estado = models.BooleanField(default=True)

    class Meta:
        verbose_name = "Categoría de Vehículo"
        verbose_name_plural = "Categorías de Vehículos"
        ordering = ["numero_ejes", "tarifa"]

    def __str__(self):
        return f"{self.nombre} - {self.numero_ejes} ejes - Tarifa: ${self.tarifa}"

class Vehiculo(models.Model):
    class Estado(models.TextChoices):
        ACTIVO = "activo", "Activo"
        INACTIVO = "inactivo", "Inactivo"
        AVISO_ROBO = "aviso_robo", "Aviso de robo"
        RECUPERADO = "recuperado", "Recuperado"

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL,on_delete=models.CASCADE,related_name="vehiculos")
    categoria = models.ForeignKey(CategoriaVehiculo,on_delete=models.PROTECT,related_name="vehiculos", null=True,blank=True)
    placa = models.CharField(max_length=15, unique=True)
    marca = models.CharField(max_length=80)
    modelo = models.CharField(max_length=80)
    color = models.CharField(max_length=50, blank=True, null=True)
    anio = models.PositiveIntegerField(blank=True, null=True)
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.ACTIVO)
    fecha_registro = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Vehículo"
        verbose_name_plural = "Vehículos"
        ordering = ["placa"]

    def save(self, *args, **kwargs):
        self.placa = self.placa.upper().strip()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.placa} - {self.marca} {self.modelo}"