from django.contrib import admin
from .models import Peaje, Camara, PasoPeaje
# Register your models here.

class CamaraInline(admin.TabularInline):
    model = Camara
    extra = 1

@admin.register(Peaje)
class PeajeAdmin(admin.ModelAdmin):
    list_display =('id','nombre','ciudad','ubicacion','tarifa','estado','fecha_creacion')
    list_filter = ('estado','ciudad','fecha_creacion')
    search_fields = ('nombre','ciudad','ubicacion')
    readonly_fields = ('fecha_creacion',)

    inlines = (CamaraInline,)

@admin.register(Camara)
class CamaraAdmin(admin.ModelAdmin):
    list_display = ('id','codigo','peaje','ubicacion','tipo_camara','estado','fecha_instalacion')
    list_filter = ('tipo_camara','estado','peaje',)
    search_fields = ('codigo','peaje__nombre','ubicacion')

@admin.register(PasoPeaje)
class PasoPeajeAdmin(admin.ModelAdmin):
    list_display = ('id','placa_detectada','peaje','camara','tarifa_aplicada','membresia_utilizada', 'estado_pago','estado_seguridad','fecha_hora')
    list_filter = ('estado_pago','estado_seguridad','peaje','membresia_utilizada','fecha_hora',)
    search_fields = ('placa_detectada','vehiculo_placa','peaje__nombre','camara__codigo')
    readonly_fields = ('fecha_hora',)
