from django.db import models


class AvisoVehiculoRobado(models.Model):
    class Estado(models.TextChoices):
        ACTIVO = "activo", "Activo"
        DETECTADO = "detectado", "Detectado"
        DERIVADO_AUTORIDAD = "derivado_autoridad", "Derivado a autoridad"
        CERRADO = "cerrado", "Cerrado"
        CANCELADO = "cancelado", "Cancelado"

    vehiculo = models.ForeignKey(
        "vehiculos.Vehiculo",
        on_delete=models.CASCADE,
        related_name="avisos_robo"
    )
    numero_denuncia = models.CharField(max_length=100, blank=True, null=True)
    entidad_denuncia = models.CharField(max_length=120, blank=True, null=True)
    fecha_denuncia = models.DateField(blank=True, null=True)
    fecha_aviso = models.DateTimeField(auto_now_add=True)
    lugar_robo = models.CharField(max_length=255, blank=True, null=True)
    descripcion = models.TextField(blank=True, null=True)
    latitud_robo = models.DecimalField(max_digits=10,decimal_places=7,blank=True,null=True)
    longitud_robo = models.DecimalField(max_digits=10,decimal_places=7,blank=True,null=True)
    documento_respaldo = models.FileField(upload_to="documentos_denuncia/",blank=True,null=True)
    estado = models.CharField(max_length=30,choices=Estado.choices,default=Estado.ACTIVO)

    class Meta:
        verbose_name = "Aviso de vehículo robado"
        verbose_name_plural = "Avisos de vehículos robados"
        ordering = ["-fecha_aviso"]

    def __str__(self):
        return f"Aviso robo - {self.vehiculo.placa} - {self.estado}"


class AlertaSeguridad(models.Model):
    class Estado(models.TextChoices):
        PENDIENTE = "pendiente", "Pendiente de revisión"
        VALIDADA = "validada", "Validada por operador"
        DERIVADA = "derivada", "Derivada a autoridad"
        ATENDIDA = "atendida", "Atendida"
        DESCARTADA = "descartada", "Descartada"

    aviso = models.ForeignKey(AvisoVehiculoRobado,on_delete=models.CASCADE,related_name="alertas")
    vehiculo = models.ForeignKey("vehiculos.Vehiculo",on_delete=models.CASCADE,related_name="alertas_seguridad")
    peaje = models.ForeignKey("peajes.Peaje",on_delete=models.CASCADE,related_name="alertas_seguridad")
    paso_peaje = models.OneToOneField("peajes.PasoPeaje",on_delete=models.SET_NULL,null=True,blank=True,related_name="alerta_seguridad")
    tipo_alerta = models.CharField(max_length=100,default="Vehículo con aviso interno de robo")
    descripcion = models.TextField(blank=True, null=True)
    fecha_hora = models.DateTimeField(auto_now_add=True)
    estado = models.CharField(max_length=30,choices=Estado.choices,default=Estado.PENDIENTE)
    latitud_deteccion = models.DecimalField(max_digits=10,decimal_places=7,blank=True,null=True)
    longitud_deteccion = models.DecimalField(max_digits=10,decimal_places=7,blank=True,null=True)

    class Meta:
        verbose_name = "Alerta de seguridad"
        verbose_name_plural = "Alertas de seguridad"
        ordering = ["-fecha_hora"]

    def __str__(self):
        return f"Alerta {self.vehiculo.placa} - {self.peaje.nombre}"


class UbicacionDeteccion(models.Model):
    alerta = models.OneToOneField(AlertaSeguridad,on_delete=models.CASCADE,related_name="ubicacion")
    peaje = models.ForeignKey("peajes.Peaje",on_delete=models.CASCADE,related_name="ubicaciones_deteccion")
    latitud = models.DecimalField(max_digits=10, decimal_places=7)
    longitud = models.DecimalField(max_digits=10, decimal_places=7)
    direccion_referencial = models.CharField(max_length=255, blank=True, null=True)
    url_maps = models.URLField(blank=True, null=True)
    fecha_hora = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Ubicación de detección"
        verbose_name_plural = "Ubicaciones de detección"
        ordering = ["-fecha_hora"]

    def __str__(self):
        return f"Ubicación alerta {self.alerta.id} - {self.peaje.nombre}"