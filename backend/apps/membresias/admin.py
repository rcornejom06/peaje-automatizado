from django.contrib import admin
from .models import PlanMembresia, Membresia


@admin.register(PlanMembresia)
class PlanMembresiaAdmin(admin.ModelAdmin):
    list_display = ( "id","nombre","precio","pases_incluidos","descuento_porcentaje","estado",)
    list_filter = ("estado","pases_incluidos",)
    search_fields = ("nombre","descripcion",)

@admin.register(Membresia)
class MembresiaAdmin(admin.ModelAdmin):
    list_display = ("id","usuario","plan","fecha_inicio","pases_restantes","estado","fecha_creacion",)
    list_filter = ("estado","plan","fecha_inicio",)
    search_fields = ("usuario__username","usuario__email","plan__nombre",)
    readonly_fields = ("fecha_creacion",)