from django.db import models
##from ..vehiculos.models import CategoriaVehiculo, Vehiculo

class ViaConcesionada(models.Model):
    nombre = models.CharField(max_length=150)
    codigo = models.CharField(max_length=50, unique=True)
    descripcion = models.TextField(blank=True, null=True)
    tiempo_validez_minutos = models.PositiveIntegerField(default=120,help_text="Tiempo durante el cual un pago previo permite pasar por otros peajes de la misma vía.")
    cobro_unico_por_trayecto = models.BooleanField(default=True,help_text="Si está activo, un pago previo exonera otros peajes de la misma vía dentro del tiempo definido.")
    estado = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Vía concesionada"
        verbose_name_plural = "Vías concesionadas"
        ordering = ["nombre"]

    def __str__(self):
        return self.nombre


class Peaje(models.Model):
    class Estado(models.TextChoices):
        ACTIVO = "activo", "Activo"
        INACTIVO = "inactivo", "Inactivo"
        MANTENIMIENTO = "mantenimiento", "Mantenimiento"

    nombre = models.CharField(max_length=120)
    ciudad = models.CharField(max_length=100)
    ubicacion = models.CharField(max_length=255)
    latitud = models.DecimalField(max_digits=50, decimal_places=20)
    longitud = models.DecimalField(max_digits=50, decimal_places=20)
    tarifa = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.ACTIVO)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    via_concesionada = models.ForeignKey(ViaConcesionada,on_delete=models.SET_NULL,null=True,blank=True,related_name="peajes")
    orden_en_via = models.PositiveIntegerField(default=0, help_text="Orden del peaje dentro de la vía concesionada.")

    class Meta:
        verbose_name = "Peaje"
        verbose_name_plural = "Peajes"
        ordering = ["nombre"]

    def __str__(self):
        return f"{self.nombre} - {self.ciudad}"


class TarifaPeajeCategoria(models.Model):
    peaje = models.ForeignKey(Peaje,on_delete=models.CASCADE,related_name="tarifas_categoria")
    categoria = models.ForeignKey("vehiculos.CategoriaVehiculo",on_delete=models.PROTECT,related_name="tarifas_por_peaje")
    valor = models.DecimalField(max_digits=8,decimal_places=2)
    estado = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Tarifa por peaje y categoría"
        verbose_name_plural = "Tarifas por peaje y categoría"
        unique_together = ("peaje", "categoria")
        ordering = ["peaje__nombre", "categoria__numero_ejes", "valor"]

    def __str__(self):
        return f"{self.peaje.nombre} - {self.categoria.nombre}: ${self.valor}"


class Camara(models.Model):
    class TipoFuente(models.TextChoices):
        RTSP = "rtsp", "RTSP / Camara IP"
        HTTP = "http", "HTTP / MJPEG"
        USB = "usb", "Webcam USB"
        VIDEO = "video", "Archivo de video"

    class Estado(models.TextChoices):
        ACTIVA = "activa", "Activa"
        INACTIVA = "inactiva", "Inactiva"
        MANTENIMIENTO = "mantenimiento", "Mantenimiento"

    peaje = models.ForeignKey(Peaje, on_delete=models.CASCADE, related_name="camaras")
    codigo = models.CharField(max_length=50, unique=True)
    ubicacion = models.CharField(max_length=150)
    tipo_camara = models.CharField(max_length=80, blank=True, null=True)
    tipo_fuente = models.CharField(max_length=20, choices=TipoFuente.choices, default=TipoFuente.RTSP)
    stream_url = models.CharField(
        max_length=500,
        blank=True,
        null=True,
        help_text="URL RTSP, HTTP, índice de webcam USB o ruta de video.",
    )
    procesar_anpr = models.BooleanField(default=True,
                                        help_text="Indica si esta camara sera usada para detenccion automatica de placas.")
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.ACTIVA)
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
        MEMBRESIA = "membresia", "Membresía"
        EXONERADO = "exonerado", "Exonerado"
        FALLIDO = "fallido", "Fallido"

    class EstadoSeguridad(models.TextChoices):
        NORMAL = "normal", "Normal"
        ALERTA = "alerta", "Alerta"
        REVISION = "revision", "Revisión"

    vehiculo = models.ForeignKey("vehiculos.Vehiculo", on_delete=models.SET_NULL, null=True, blank=True,
                                 related_name="pasos_peaje")
    peaje = models.ForeignKey(Peaje, on_delete=models.CASCADE, related_name="pasos")
    camara = models.ForeignKey(Camara, on_delete=models.SET_NULL, null=True, blank=True, related_name="capturas")
    placa_detectada = models.CharField(max_length=15)
    fecha_hora = models.DateTimeField(auto_now_add=True)
    estado_pago = models.CharField(max_length=20, choices=EstadoPago.choices, default=EstadoPago.PENDIENTE)
    tarifa_aplicada = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    membresia_utilizada = models.ForeignKey("membresias.Membresia", on_delete=models.SET_NULL, null=True, blank=True,
                                            related_name="pasos_peaje")
    estado_seguridad = models.CharField(max_length=20, choices=EstadoSeguridad.choices, default=EstadoSeguridad.NORMAL)
    imagen_capturada = models.ImageField(upload_to="capturas_placas/", blank=True, null=True)
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
