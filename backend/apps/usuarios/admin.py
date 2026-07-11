from django.contrib import admin
from .models import PerfilUsuario
# Register your models here.
@admin.register(PerfilUsuario)
class PerfilUsuarioAdmin(admin.ModelAdmin):
    list_display = ('id','usuario','telefono','cedula','rol','estado','fecha_creacion')
    list_filter = ('rol', 'estado','fecha_creacion')
    search_fields = ('usuario__username','usuario__email', 'telefono', 'cedula')
    readonly_fields = ('fecha_creacion','fecha_actualizacion')
