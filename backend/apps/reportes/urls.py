from django.urls import path

from .views import (
    ResumenReporteView,
    RecaudacionReporteView,
    PasosPorPeajeReporteView,
    AlertasReporteView,
    VehiculosDetectadosReporteView,
    UsoMembresiasReporteView,
)


urlpatterns = [
    path("resumen/", ResumenReporteView.as_view(), name="reporte-resumen"),
    path("recaudacion/", RecaudacionReporteView.as_view(), name="reporte-recaudacion"),
    path("pasos-por-peaje/", PasosPorPeajeReporteView.as_view(), name="reporte-pasos-peaje"),
    path("alertas/", AlertasReporteView.as_view(), name="reporte-alertas"),
    path("vehiculos-detectados/", VehiculosDetectadosReporteView.as_view(), name="reporte-vehiculos-detectados"),
    path("uso-membresias/", UsoMembresiasReporteView.as_view(), name="reporte-uso-membresias"),
]