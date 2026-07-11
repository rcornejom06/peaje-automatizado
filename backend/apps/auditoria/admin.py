from django.contrib import admin
from .models import HistorialUsuario


@admin.register(HistorialUsuario)
class HistorialUsuarioAdmin(admin.ModelAdmin):
    list_display = ("id","usuario","accion","modulo","estado","dispositivo","direccion_ip","fecha_hora",)
    list_filter = ("estado","modulo","dispositivo","fecha_hora",)
    search_fields = ("usuario__username","usuario__email","accion","descripcion","modulo",)
    readonly_fields = ("fecha_hora",)