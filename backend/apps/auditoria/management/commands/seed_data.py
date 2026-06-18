from datetime import date, timedelta

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.usuarios.models import PerfilUsuario
from apps.vehiculos.models import CategoriaVehiculo, Vehiculo
from apps.peajes.models import Peaje, Camara
from apps.pagos.models import Billetera
from apps.membresias.models import PlanMembresia, Membresia


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
            CategoriaVehiculo.objects.get_or_create(
                nombre=data["nombre"],
                defaults=data
            )

        self.stdout.write(self.style.SUCCESS("Categorías vehiculares creadas."))

    def crear_usuarios_administrativos(self):
        admin, creado_admin = User.objects.get_or_create(
            username="admin",
            defaults={
                "email": "admin@peaje.com",
                "is_staff": True,
                "is_superuser": True,
            }
        )

        if creado_admin:
            admin.set_password("Admin12345")
            admin.save()

        operador, creado_operador = User.objects.get_or_create(
            username="operador",
            defaults={
                "email": "operador@peaje.com",
                "is_staff": True,
                "is_superuser": False,
            }
        )

        if creado_operador:
            operador.set_password("Operador12345")
            operador.save()

        cliente, creado_cliente = User.objects.get_or_create(
            username="cliente1",
            defaults={
                "email": "cliente1@peaje.com",
                "first_name": "Cliente",
                "last_name": "Demo",
            }
        )

        if creado_cliente:
            cliente.set_password("Cliente12345")
            cliente.save()

        PerfilUsuario.objects.get_or_create(
            usuario=operador,
            defaults={
                "rol": PerfilUsuario.Rol.OPERADOR,
                "estado": True,
            }
        )

        PerfilUsuario.objects.get_or_create(
            usuario=cliente,
            defaults={
                "rol": PerfilUsuario.Rol.USUARIO,
                "estado": True,
            }
        )

        Billetera.objects.get_or_create(
            usuario=cliente,
            defaults={
                "saldo": "50.00",
                "estado": Billetera.Estado.ACTIVA,
            }
        )

        self.stdout.write(self.style.SUCCESS("Usuarios demo creados."))

    def crear_peajes_y_camaras(self):
        peaje, _ = Peaje.objects.get_or_create(
            nombre="Peaje Milagro",
            defaults={
                "ciudad": "Milagro",
                "ubicacion": "Vía Milagro - Guayaquil",
                "latitud": "-2.1345000",
                "longitud": "-79.5948000",
                "tarifa": "1.00",
                "estado": Peaje.Estado.ACTIVO,
            }
        )

        Camara.objects.get_or_create(
            codigo="CAM-001",
            defaults={
                "peaje": peaje,
                "ubicacion": "Carril 1",
                "tipo_camara": "ANPR",
                "estado": Camara.Estado.ACTIVA,
                "fecha_instalacion": date.today(),
            }
        )

        self.stdout.write(self.style.SUCCESS("Peajes y cámaras creados."))

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
