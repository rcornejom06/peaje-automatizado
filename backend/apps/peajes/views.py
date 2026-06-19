from decimal import Decimal
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone
from ..membresias.models import Membresia
from .models import Peaje, Camara, PasoPeaje
from .serializers import PeajeSerializer, CamaraSerializer, PasoPeajeSerializer
from ..usuarios.permissions import obtener_rol_usuario

class PeajeViewSet(viewsets.ModelViewSet):
    serializer_class = PeajeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Peaje.objects.all().order_by("nombre")

    def create(self, request, *args, **kwargs):
        if obtener_rol_usuario(self.request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede crear peajes."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede actualizar peajes."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede eliminar peajes."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().destroy(request, *args, **kwargs)


class CamaraViewSet(viewsets.ModelViewSet):
    serializer_class = CamaraSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Camara.objects.all().order_by("codigo")

    def create(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede crear cámaras."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede actualizar cámaras."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if obtener_rol_usuario(request.user) != "administrador":
            return Response(
                {"error": "Solo el administrador puede eliminar cámaras."},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().destroy(request, *args, **kwargs)


class PasoPeajeViewSet(viewsets.ModelViewSet):
    serializer_class = PasoPeajeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        rol = obtener_rol_usuario(self.request.user)

        if rol in ["operador", "administrador"]:
            return PasoPeaje.objects.all().order_by("-fecha_hora")

        return PasoPeaje.objects.filter(
            vehiculo__usuario=self.request.user
        ).order_by("-fecha_hora")

    @action(detail=False, methods=["post"], url_path="simular")
    def simular(self, request):
        placa_detectada = request.data.get("placa_detectada")
        peaje_id = request.data.get("peaje")
        camara_id = request.data.get("camara")
        rol = obtener_rol_usuario(request.user)

        if rol not in ["operador", "administrador"]:
            return Response(
                {"error": "Solo operadores o administradores pueden simular pasos por peaje."},
                status=status.HTTP_403_FORBIDDEN
            )

        if not placa_detectada or not peaje_id:
            return Response(
                {
                    "error": "Los campos placa_detectada y peaje son obligatorios."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        placa_detectada = placa_detectada.upper().strip()

        try:
            peaje = Peaje.objects.get(id=peaje_id)
        except Peaje.DoesNotExist:
            return Response(
                {"error": "El peaje indicado no existe."},
                status=status.HTTP_404_NOT_FOUND
            )

        camara = None
        if camara_id:
            try:
                camara = Camara.objects.get(id=camara_id, peaje=peaje)
            except Camara.DoesNotExist:
                return Response(
                    {"error": "La cámara indicada no existe o no pertenece al peaje."},
                    status=status.HTTP_404_NOT_FOUND
                )

        from apps.vehiculos.models import Vehiculo
        from apps.pagos.models import Billetera, Transaccion
        from apps.seguridad.models import (
            AvisoVehiculoRobado,
            AlertaSeguridad,
            UbicacionDeteccion,
        )

        vehiculo = Vehiculo.objects.filter(placa=placa_detectada).first()

        estado_pago = PasoPeaje.EstadoPago.PENDIENTE
        estado_seguridad = PasoPeaje.EstadoSeguridad.NORMAL
        transaccion = None
        tarifa_aplicada = Decimal("0.00")
        membresia_utilizada = None

        if vehiculo:
            if vehiculo.categoria:
                tarifa_aplicada = vehiculo.categoria.tarifa
            else:
                tarifa_aplicada = peaje.tarifa


            hoy = timezone.localdate()

            membresia_activa = Membresia.objects.filter(
                usuario=vehiculo.usuario,
                estado=Membresia.Estado.ACTIVA,
                fecha_inicio__lte=hoy,
                fecha_fin__gte=hoy,
                pases_restantes__gt=0
            ).order_by("fecha_fin").first()

            billetera = Billetera.objects.filter(usuario=vehiculo.usuario).first()

            if membresia_activa:
                membresia_activa.consumir_pase()
                membresia_utilizada = membresia_activa
                estado_pago = PasoPeaje.EstadoPago.MEMBRESIA

                transaccion = Transaccion.objects.create(
                    billetera=billetera,
                    membresia=membresia_activa,
                    monto=Decimal("0.00"),
                    tipo_transaccion=Transaccion.Tipo.USO_MEMBRESIA,
                    metodo_pago="Membresía",
                    referencia_pago=f"Uso de membresía en {peaje.nombre}",
                    estado=Transaccion.Estado.APROBADA,
                )

            elif billetera and billetera.estado == Billetera.Estado.ACTIVA:
                if billetera.saldo >= tarifa_aplicada:
                    billetera.saldo -= tarifa_aplicada
                    billetera.save()

                    estado_pago = PasoPeaje.EstadoPago.PAGADO

                    transaccion = Transaccion.objects.create(
                        billetera=billetera,
                        monto=tarifa_aplicada,
                        tipo_transaccion=Transaccion.Tipo.PAGO_PEAJE,
                        metodo_pago="Billetera virtual",
                        referencia_pago=f"Pago peaje {peaje.nombre}",
                        estado=Transaccion.Estado.APROBADA,
                    )
                else:
                    estado_pago = PasoPeaje.EstadoPago.FALLIDO

        paso = PasoPeaje.objects.create(
            vehiculo=vehiculo,
            peaje=peaje,
            camara=camara,
            placa_detectada=placa_detectada,
            estado_pago=estado_pago,
            tarifa_aplicada=tarifa_aplicada,
            membresia_utilizada=membresia_utilizada,
            estado_seguridad=estado_seguridad,
            observacion="Paso por peaje simulado desde API.",
        )

        if transaccion:
            transaccion.paso_peaje = paso
            transaccion.save()

        alerta_generada = None
        ubicacion_generada = None
        maps_url = None

        if vehiculo:
            aviso_activo = AvisoVehiculoRobado.objects.filter(
                vehiculo=vehiculo,
                estado=AvisoVehiculoRobado.Estado.ACTIVO
            ).first()

            if aviso_activo:
                paso.estado_seguridad = PasoPeaje.EstadoSeguridad.ALERTA
                paso.save()

                alerta_generada = AlertaSeguridad.objects.create(
                    aviso=aviso_activo,
                    vehiculo=vehiculo,
                    peaje=peaje,
                    paso_peaje=paso,
                    tipo_alerta="Vehículo con aviso interno de robo",
                    descripcion=(
                        f"El vehículo con placa {placa_detectada} "
                        f"fue detectado en el peaje {peaje.nombre}."
                    ),
                    estado=AlertaSeguridad.Estado.PENDIENTE,
                    latitud_deteccion=peaje.latitud,
                    longitud_deteccion=peaje.longitud,
                )

                maps_url = f"https://www.google.com/maps?q={peaje.latitud},{peaje.longitud}"

                ubicacion_generada = UbicacionDeteccion.objects.create(
                    alerta=alerta_generada,
                    peaje=peaje,
                    latitud=peaje.latitud,
                    longitud=peaje.longitud,
                    direccion_referencial=peaje.ubicacion,
                    url_maps=maps_url,
                )

                aviso_activo.estado = AvisoVehiculoRobado.Estado.DETECTADO
                aviso_activo.save()

                try:
                    from apps.notificaciones.models import Notificacion

                    Notificacion.objects.create(
                        usuario=vehiculo.usuario,
                        alerta=alerta_generada,
                        titulo="Vehículo detectado en peaje",
                        mensaje=(
                            f"Tu vehículo con placa {placa_detectada} "
                            f"fue detectado en {peaje.nombre}."
                        ),
                        tipo=Notificacion.Tipo.ALERTA,
                    )
                except Exception:
                    pass

        try:
            from apps.auditoria.models import HistorialUsuario

            HistorialUsuario.objects.create(
                usuario=request.user,
                accion="Simulación de paso por peaje",
                descripcion=f"Se simuló el paso de la placa {placa_detectada} por {peaje.nombre}.",
                modulo="Peajes",
                dispositivo="API",
                estado=HistorialUsuario.Estado.EXITOSO,
            )
        except Exception:
            pass

        return Response(
            {
                "mensaje": "Paso por peaje simulado correctamente.",
                "paso": PasoPeajeSerializer(paso).data,
                "vehiculo_registrado": bool(vehiculo),
                "estado_pago": paso.estado_pago,
                "alerta_generada": bool(alerta_generada),
                "id_alerta": alerta_generada.id if alerta_generada else None,
                "id_ubicacion": ubicacion_generada.id if ubicacion_generada else None,
                "url_maps": maps_url,
            },
            status=status.HTTP_201_CREATED
        )