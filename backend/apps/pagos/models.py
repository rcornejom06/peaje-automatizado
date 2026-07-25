import uuid
from django.utils import timezone
from django.conf import settings
from django.db import models


class Billetera(models.Model):
    class Estado(models.TextChoices):
        ACTIVA = "activa", "Activa"
        BLOQUEADA = "bloqueada", "Bloqueada"
        INACTIVA = "inactiva", "Inactiva"

    usuario = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="billetera")
    saldo = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.ACTIVA)
    fecha_creacion = models.DateTimeField(auto_now_add=True,)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Billetera"
        verbose_name_plural = "Billeteras"

    def __str__(self):
        return f"Billetera de {self.usuario.username} - Saldo: {self.saldo}"


class TarjetaBancaria(models.Model):
    class Estado(models.TextChoices):
        ACTIVA = "activa", "Activa"
        INACTIVA = "inactiva", "Inactiva"

    class Marca(models.TextChoices):
        VISA = "visa", "Visa"
        MASTERCARD = "mastercard", "Mastercard"
        AMEX = "amex", "American Express"
        DINERS = "diners", "Diners Club"
        DESCONOCIDA = "desconocida", "Desconocida"

    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="tarjetas_bancarias"
    )

    alias = models.CharField(max_length=80, blank=True, null=True)
    titular = models.CharField(max_length=120)
    marca = models.CharField(
        max_length=30,
        choices=Marca.choices,
        default=Marca.DESCONOCIDA
    )

    ultimos4 = models.CharField(max_length=4)

    mes_expiracion = models.PositiveSmallIntegerField()
    anio_expiracion = models.PositiveSmallIntegerField()

    token_simulado = models.UUIDField(default=uuid.uuid4, editable=False)

    principal = models.BooleanField(default=False)
    estado = models.CharField(
        max_length=20,
        choices=Estado.choices,
        default=Estado.ACTIVA
    )

    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Tarjeta bancaria"
        verbose_name_plural = "Tarjetas bancarias"
        ordering = ["-principal", "-fecha_creacion"]

    def esta_vencida(self):
        hoy = timezone.now().date()
        anio_actual = hoy.year
        mes_actual = hoy.month

        return (
                self.anio_expiracion < anio_actual or
                (
                        self.anio_expiracion == anio_actual and
                        self.mes_expiracion < mes_actual
                )
        )

    def __str__(self):
        return f"{self.get_marca_display()} terminada en {self.ultimos4}"


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
        FALLIDA = "fallida", "Fallida"
        ANULADA = "anulada", "Anulada"

    billetera = models.ForeignKey(Billetera, on_delete=models.CASCADE, related_name="transacciones")
    paso_peaje = models.OneToOneField("peajes.PasoPeaje", on_delete=models.SET_NULL, null=True, blank=True,
                                      related_name="transaccion")
    monto = models.DecimalField(max_digits=10, decimal_places=2)
    membresia = models.ForeignKey("membresias.Membresia", on_delete=models.SET_NULL, null=True, blank=True,
                                  related_name="transacciones")
    tipo_transaccion = models.CharField(max_length=20, choices=Tipo.choices)
    metodo_pago = models.CharField(max_length=50, default="Billetera virtual")
    referencia_pago = models.CharField(max_length=120, blank=True, null=True)
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.PENDIENTE)
    fecha_hora = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Transacción"
        verbose_name_plural = "Transacciones"
        ordering = ["-fecha_hora"]

    def __str__(self):
        return f"{self.tipo_transaccion} - {self.monto} - {self.estado}"
