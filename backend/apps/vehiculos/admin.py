from django.contrib import admin
from .models import CategoriaVehiculo,Vehiculo

@admin.register(CategoriaVehiculo)
class CategoriaVehiculoAdmin(admin.ModelAdmin):
    list_display = ("id","nombre","tipo","numero_ejes","tarifa","estado",)
    list_filter = ("tipo","numero_ejes","estado",)
    search_fields = ("nombre","tipo",)



@admin.register(Vehiculo)
class VehiculoAdmin(admin.ModelAdmin):
    list_display = ("id","placa","usuario","marca","modelo","color","anio","estado","fecha_registro",)
    list_filter = ("estado","marca","fecha_registro",)
    search_fields = ("placa","marca","modelo","usuario__username","usuario__email",)
    readonly_fields = ("fecha_registro","fecha_actualizacion",)