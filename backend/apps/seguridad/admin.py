from django.contrib import admin
from .models import AvisoVehiculoRobado, AlertaSeguridad, UbicacionDeteccion


class AlertaSeguridadInline(admin.TabularInline):
    model = AlertaSeguridad
    extra = 0
    readonly_fields = ("fecha_hora",)

@admin.register(AvisoVehiculoRobado)
class AvisoVehiculoRobadoAdmin(admin.ModelAdmin):
    list_display = ("id","vehiculo","numero_denuncia","entidad_denuncia","fecha_denuncia","estado","fecha_aviso",)
    list_filter = ("estado","entidad_denuncia","fecha_denuncia","fecha_aviso",)
    search_fields = ("vehiculo__placa","numero_denuncia","entidad_denuncia","lugar_robo",)
    readonly_fields = ("fecha_aviso",)
    inlines = [AlertaSeguridadInline]

@admin.register(AlertaSeguridad)
class AlertaSeguridadAdmin(admin.ModelAdmin):
    list_display = ("id","vehiculo","peaje","aviso","tipo_alerta","estado","fecha_hora",)
    list_filter = ("estado","peaje","tipo_alerta","fecha_hora",)
    search_fields = ("vehiculo__placa","peaje__nombre","aviso__numero_denuncia","descripcion",)
    readonly_fields = ("fecha_hora",)

@admin.register(UbicacionDeteccion)
class UbicacionDeteccionAdmin(admin.ModelAdmin):
    list_display = ("id","alerta","peaje","latitud","longitud","direccion_referencial","fecha_hora",)
    list_filter = ("peaje","fecha_hora",)
    search_fields = ("peaje__nombre","direccion_referencial","alerta__vehiculo__placa",)
    readonly_fields = ("fecha_hora",)