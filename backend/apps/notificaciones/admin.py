from django.contrib import admin
from .models import DispositivoPush, Notificacion


@admin.register(Notificacion)
class NotificacionAdmin(admin.ModelAdmin):
    list_display = ("id","usuario","titulo","tipo","leida","fecha_hora",)
    list_filter = ("tipo","leida","fecha_hora",)
    search_fields = ("usuario__username","usuario__email","titulo","mensaje",)
    readonly_fields = ("fecha_hora",)


@admin.register(DispositivoPush)
class DispositivoPushAdmin(admin.ModelAdmin):
    list_display = ("id", "usuario", "plataforma", "actualizado")
    list_filter = ("plataforma",)
    search_fields = ("usuario__username", "usuario__email", "token")
    readonly_fields = ("creado", "actualizado")