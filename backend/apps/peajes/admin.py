from django.contrib import admin
from .models import Peaje, Camara, PasoPeaje


@admin.register(Peaje)
class PeajeAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "nombre",
        "ciudad",
        "ubicacion",
        "tarifa",
        "estado",
    )
    search_fields = (
        "nombre",
        "ciudad",
        "ubicacion",
    )
    list_filter = (
        "estado",
        "ciudad",
    )


@admin.register(Camara)
class CamaraAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "codigo",
        "peaje",
        "ubicacion",
        "tipo_camara",
        "estado",
        "fecha_instalacion",
    )
    search_fields = (
        "codigo",
        "ubicacion",
        "peaje__nombre",
    )
    list_filter = (
        "estado",
        "tipo_camara",
        "peaje",
    )


@admin.register(PasoPeaje)
class PasoPeajeAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "placa_detectada",
        "vehiculo",
        "peaje",
        "camara",
        "estado_pago",
        "estado_seguridad",
        "tarifa_aplicada",
        "fecha_hora",
    )

    search_fields = (
        "placa_detectada",
        "vehiculo__placa",
        "peaje__nombre",
        "camara__codigo",
    )

    list_filter = (
        "estado_pago",
        "estado_seguridad",
        "peaje",
        "camara",
    )

    readonly_fields = (
        "fecha_hora",
    )

    ordering = (
        "-fecha_hora",
    )