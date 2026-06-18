from django.conf import settings
from django.db import models


class Billetera(models.Model):
    class Estado(models.TextChoices):
        ACTIVA = "activa", "Activa"
        BLOQUEADA = "bloqueada", "Bloqueada"
        INACTIVA = "inactiva", "Inactiva"

    usuario = models.OneToOneField(settings.AUTH_USER_MODEL,on_delete=models.CASCADE,related_name="billetera")
    saldo = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.ACTIVA)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Billetera"
        verbose_name_plural = "Billeteras"

    def __str__(self):
        return f"Billetera de {self.usuario.username} - Saldo: {self.saldo}"


class Transaccion(models.Model):
    class Tipo(models.TextChoices):
        RECARGA = "recarga", "Recarga"
        PAGO_PEAJE = "pago_peaje", "Pago de peaje"
        COMPRA_MEMBRESIA = "compra_membresia", "Compra de membresía"
        USO_MEMBRESIA = "uso_membresia", "Uso de membresía"
        DEVOLUCION = "devolucion", "Devolución"

    class Estado(models.TextChoices):
        PENDIENTE = "pendiente", "Pendiente"
        APROBADA = "aprobada", "Aprobada"
        RECHAZADA = "rechazada", "Rechazada"
        ANULADA = "anulada", "Anulada"

    billetera = models.ForeignKey(Billetera,on_delete=models.CASCADE,related_name="transacciones")
    paso_peaje = models.OneToOneField("peajes.PasoPeaje",on_delete=models.SET_NULL,null=True,blank=True,related_name="transaccion")
    monto = models.DecimalField(max_digits=10, decimal_places=2)
    membresia = models.ForeignKey("membresias.Membresia",on_delete=models.SET_NULL,null=True,blank=True,related_name="transacciones")
    tipo_transaccion = models.CharField(max_length=20,choices=Tipo.choices)
    metodo_pago = models.CharField(max_length=50, default="Billetera virtual")
    referencia_pago = models.CharField(max_length=120, blank=True, null=True)
    estado = models.CharField(max_length=20,choices=Estado.choices,default=Estado.PENDIENTE)
    fecha_hora = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Transacción"
        verbose_name_plural = "Transacciones"
        ordering = ["-fecha_hora"]

    def __str__(self):
        return f"{self.tipo_transaccion} - {self.monto} - {self.estado}"