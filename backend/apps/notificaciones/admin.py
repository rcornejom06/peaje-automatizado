from django.contrib import admin
from .models import Notificacion


@admin.register(Notificacion)
class NotificacionAdmin(admin.ModelAdmin):
    list_display = ("id","usuario","titulo","tipo","leida","fecha_hora",)
    list_filter = ("tipo","leida","fecha_hora",)
    search_fields = ("usuario__username","usuario__email","titulo","mensaje",)
    readonly_fields = ("fecha_hora",)
