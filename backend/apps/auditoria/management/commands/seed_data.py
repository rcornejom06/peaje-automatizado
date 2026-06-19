from datetime import date
from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from ....usuarios.models import PerfilUsuario
from ....vehiculos.models import CategoriaVehiculo
from ....peajes.models import Peaje, Camara
from ....pagos.models import Billetera
from ....membresias.models import PlanMembresia


class Command(BaseCommand):
    help = "Carga datos iniciales para demostración del sistema de peaje automatizado."

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.WARNING("Iniciando carga de datos iniciales..."))

        self.crear_categorias_vehiculares()
        self.crear_usuarios_administrativos()
        self.crear_peajes_y_camaras()
        self.crear_planes_membresia()

        self.stdout.write(self.style.SUCCESS("Datos iniciales cargados correctamente."))

    def crear_categorias_vehiculares(self):
        categorias = [
            {
                "nombre": "Liviano 2 ejes",
                "tipo": CategoriaVehiculo.Tipo.LIVIANO,
                "numero_ejes": 2,
                "tarifa": "1.00",
            },
            {
                "nombre": "Pesado 2 ejes",
                "tipo": CategoriaVehiculo.Tipo.PESADO,
                "numero_ejes": 2,
                "tarifa": "2.00",
            },
            {
                "nombre": "Pesado 3 ejes",
                "tipo": CategoriaVehiculo.Tipo.PESADO,
                "numero_ejes": 3,
                "tarifa": "3.00",
            },
            {
                "nombre": "Pesado 4 ejes",
                "tipo": CategoriaVehiculo.Tipo.PESADO,
                "numero_ejes": 4,
                "tarifa": "4.00",
            },
            {
                "nombre": "Extrapesado 5 ejes",
                "tipo": CategoriaVehiculo.Tipo.EXTRAPESADO,
                "numero_ejes": 5,
                "tarifa": "5.00",
            },
            {
                "nombre": "Extrapesado 6 ejes",
                "tipo": CategoriaVehiculo.Tipo.EXTRAPESADO,
                "numero_ejes": 6,
                "tarifa": "6.00",
            },
        ]

        for data in categorias:
            categoria, creada = CategoriaVehiculo.objects.get_or_create(
                nombre=data["nombre"],
                defaults=data
            )

            if not creada:
                categoria.tipo = data["tipo"]
                categoria.numero_ejes = data["numero_ejes"]
                categoria.tarifa = data["tarifa"]
                categoria.estado = True
                categoria.save()

        self.stdout.write(self.style.SUCCESS("Categorías vehiculares creadas o actualizadas."))


    def crear_planes_membresia(self):
        PlanMembresia.objects.get_or_create(
            nombre="Membresía mensual",
            defaults={
                "descripcion": "Membresía mensual con 30 pases incluidos.",
                "precio": "25.00",
                "duracion_dias": 30,
                "pases_incluidos": 30,
                "descuento_porcentaje": "0.00",
                "estado": PlanMembresia.Estado.ACTIVO,
            }
        )

        PlanMembresia.objects.get_or_create(
            nombre="Membresía semanal",
            defaults={
                "descripcion": "Membresía semanal con 7 pases incluidos.",
                "precio": "7.00",
                "duracion_dias": 7,
                "pases_incluidos": 7,
                "descuento_porcentaje": "0.00",
                "estado": PlanMembresia.Estado.ACTIVO,
            }
        )

        self.stdout.write(self.style.SUCCESS("Planes de membresía creados."))
