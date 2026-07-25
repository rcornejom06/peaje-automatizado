from rest_framework import serializers
from django.utils import timezone
from .models import Billetera, Transaccion, TarjetaBancaria


def validar_luhn(numero):
    digitos = [int(d) for d in numero if d.isdigit()]
    checksum = 0
    paridad = len(digitos) % 2

    for i, digito in enumerate(digitos):
        if i % 2 == paridad:
            digito *= 2
            if digito > 9:
                digito -= 9
        checksum += digito

    return checksum % 10 == 0


def detectar_marca(numero):
    if numero.startswith("4"):
        return TarjetaBancaria.Marca.VISA

    if numero[:2].isdigit() and 51 <= int(numero[:2]) <= 55:
        return TarjetaBancaria.Marca.MASTERCARD

    if numero.startswith(("34", "37")):
        return TarjetaBancaria.Marca.AMEX

    if numero.startswith(("300", "301", "302", "303", "304", "305", "36", "38")):
        return TarjetaBancaria.Marca.DINERS

    return TarjetaBancaria.Marca.DESCONOCIDA


class TarjetaBancariaSerializer(serializers.ModelSerializer):
    marca_display = serializers.CharField(source="get_marca_display", read_only=True)
    numero_enmascarado = serializers.SerializerMethodField()
    vencida = serializers.SerializerMethodField()

    class Meta:
        model = TarjetaBancaria
        fields = [
            "id",
            "alias",
            "titular",
            "marca",
            "marca_display",
            "numero_enmascarado",
            "ultimos4",
            "mes_expiracion",
            "anio_expiracion",
            "principal",
            "estado",
            "vencida",
            "fecha_creacion",
        ]
        read_only_fields = [
            "id",
            "marca",
            "marca_display",
            "numero_enmascarado",
            "ultimos4",
            "vencida",
            "fecha_creacion",
        ]

    def get_numero_enmascarado(self, obj):
        return f"**** **** **** {obj.ultimos4}"

    def get_vencida(self, obj):
        return obj.esta_vencida()


class CrearTarjetaBancariaSerializer(serializers.Serializer):
    numero_tarjeta = serializers.CharField(write_only=True)
    titular = serializers.CharField(max_length=120)
    mes_expiracion = serializers.IntegerField(min_value=1, max_value=12)
    anio_expiracion = serializers.IntegerField(min_value=2024)
    alias = serializers.CharField(max_length=80, required=False, allow_blank=True)
    principal = serializers.BooleanField(default=False)

    def validate_numero_tarjeta(self, value):
        numero = value.replace(" ", "").replace("-", "")

        if not numero.isdigit():
            raise serializers.ValidationError(
                "El número de tarjeta solo debe contener dígitos."
            )

        if len(numero) < 13 or len(numero) > 19:
            raise serializers.ValidationError(
                "El número de tarjeta debe tener entre 13 y 19 dígitos."
            )

        if not validar_luhn(numero):
            raise serializers.ValidationError(
                "El número de tarjeta no es válido."
            )

        return numero

    def validate(self, attrs):
        mes = attrs["mes_expiracion"]
        anio = attrs["anio_expiracion"]

        hoy = timezone.now().date()

        if anio < hoy.year or (anio == hoy.year and mes < hoy.month):
            raise serializers.ValidationError(
                "La tarjeta está vencida."
            )

        return attrs

    def create(self, validated_data):
        request = self.context["request"]
        usuario = request.user

        numero = validated_data.pop("numero_tarjeta")
        principal = validated_data.pop("principal", False)

        if principal:
            TarjetaBancaria.objects.filter(
                usuario=usuario,
                principal=True
            ).update(principal=False)

        if not TarjetaBancaria.objects.filter(usuario=usuario).exists():
            principal = True

        tarjeta = TarjetaBancaria.objects.create(
            usuario=usuario,
            marca=detectar_marca(numero),
            ultimos4=numero[-4:],
            principal=principal,
            **validated_data
        )

        return tarjeta


class RecargaConTarjetaSerializer(serializers.Serializer):
    monto = serializers.DecimalField(max_digits=10, decimal_places=2)
    tarjeta_id = serializers.IntegerField()
    cvv = serializers.CharField(write_only=True, min_length=3, max_length=4)

    def validate_monto(self, value):
        if value <= 0:
            raise serializers.ValidationError(
                "El monto debe ser mayor a 0."
            )

        return value

    def validate_cvv(self, value):
        if not value.isdigit():
            raise serializers.ValidationError(
                "El CVV solo debe contener números."
            )

        return value


class BilleteraSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(source="usuario.username", read_only=True)

    class Meta:
        model = Billetera
        fields = "__all__"


class TransaccionSerializer(serializers.ModelSerializer):
    usuario = serializers.CharField(source="billetera.usuario.username", read_only=True)

    class Meta:
        model = Transaccion
        fields = "__all__"
