from django.db import models


class Peaje(models.Model):
    class Estado(models.TextChoices):
        ACTIVO = "activo", "Activo"
        INACTIVO = "inactivo", "Inactivo"
        MANTENIMIENTO = "mantenimiento", "Mantenimiento"

    nombre = models.CharField(max_length=120)
    ciudad = models.CharField(max_length=100)
    ubicacion = models.CharField(max_length=255)
    latitud = models.DecimalField(max_digits=10, decimal_places=7)
    longitud = models.DecimalField(max_digits=10, decimal_places=7)
    tarifa = models.DecimalField(max_digits=8, decimal_places=2)
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.ACTIVO)
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Peaje"
        verbose_name_plural = "Peajes"
        ordering = ["nombre"]

    def __str__(self):
        return f"{self.nombre} - {self.ciudad}"


class Camara(models.Model):
    class Estado(models.TextChoices):
        ACTIVA = "activa", "Activa"
        INACTIVA = "inactiva", "Inactiva"
        MANTENIMIENTO = "mantenimiento", "Mantenimiento"

    peaje = models.ForeignKey(Peaje,on_delete=models.CASCADE,related_name="camaras")
    codigo = models.CharField(max_length=50, unique=True)
    ubicacion = models.CharField(max_length=150)
    tipo_camara = models.CharField(max_length=80, blank=True, null=True)
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.ACTIVA)
    fecha_instalacion = models.DateField(blank=True, null=True)

    class Meta:
        verbose_name = "Cámara"
        verbose_name_plural = "Cámaras"
        ordering = ["codigo"]

    def __str__(self):
        return f"{self.codigo} - {self.peaje.nombre}"


class PasoPeaje(models.Model):
    class EstadoPago(models.TextChoices):
        PENDIENTE = "pendiente", "Pendiente"
        PAGADO = "pagado", "Pagado"
        EXONERADO = "exonerado", "Exonerado"
        FALLIDO = "fallido", "Fallido"

    class EstadoSeguridad(models.TextChoices):
        NORMAL = "normal", "Normal"
        ALERTA = "alerta", "Alerta"
        REVISION = "revision", "Revisión"

    vehiculo = models.ForeignKey("vehiculos.Vehiculo",on_delete=models.SET_NULL,null=True,blank=True,related_name="pasos_peaje")
    peaje = models.ForeignKey(Peaje,on_delete=models.CASCADE,related_name="pasos")
    camara = models.ForeignKey(Camara,on_delete=models.SET_NULL,null=True,blank=True,related_name="capturas")
    placa_detectada = models.CharField(max_length=15)
    fecha_hora = models.DateTimeField(auto_now_add=True)
    estado_pago = models.CharField(max_length=20,choices=EstadoPago.choices,default=EstadoPago.PENDIENTE)
    estado_seguridad = models.CharField(max_length=20,choices=EstadoSeguridad.choices,default=EstadoSeguridad.NORMAL)
    imagen_capturada = models.ImageField(upload_to="capturas_placas/",blank=True,null=True)
    observacion = models.TextField(blank=True, null=True)

    class Meta:
        verbose_name = "Paso por peaje"
        verbose_name_plural = "Pasos por peaje"
        ordering = ["-fecha_hora"]

    def save(self, *args, **kwargs):
        self.placa_detectada = self.placa_detectada.upper().strip()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.placa_detectada} - {self.peaje.nombre}"