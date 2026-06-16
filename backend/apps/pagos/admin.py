from django.contrib import admin
from .models import Billetera, Transaccion
# Register your models here.

class TransaccionInline(admin.TabularInline):
    model = Transaccion
    extra = 0
    readonly_fields = ('fecha_hora',)


@admin.register(Billetera)
class BilleteraAdmin(admin.ModelAdmin):
    list_display = ('id','usuario','saldo','estado','fecha_creacion','fecha_actualizacion')
    list_filter = ('estado','fecha_creacion')
    search_fields = ('usuario__username','usuario__email',)
    readonly_fields = ('fecha_creacion','fecha_actualizacion',)

    inlines = (TransaccionInline,)

@admin.register(Transaccion)
class TransaccionAdmin(admin.ModelAdmin):
    list_display = ('id','billetera','paso_peaje','monto','tipo_transaccion','metodo_pago','estado','fecha_hora')
    list_filter = ('tipo_transaccion','estado','metodo_pago','fecha_hora',)
    search_fields = ('billetera__usuario__username','billetera__usuario__email','referencia_pago','paso_peaje__placa_detectada')
    readonly_fields = ('fecha_hora',)