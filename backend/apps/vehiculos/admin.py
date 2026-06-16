from django.contrib import admin
from .models import Vehiculo


@admin.register(Vehiculo)
class VehiculoAdmin(admin.ModelAdmin):
    list_display = (
        "id","placa","usuario","marca","modelo","color","anio","estado","fecha_registro",)
    list_filter = ("estado","marca","fecha_registro",)
    search_fields = ("placa","marca","modelo","usuario__username","usuario__email",)
    readonly_fields = ("fecha_registro","fecha_actualizacion",)