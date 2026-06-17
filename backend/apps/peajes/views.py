from decimal import Decimal

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Peaje, Camara, PasoPeaje
from .serializers import PeajeSerializer, CamaraSerializer, PasoPeajeSerializer


class PeajeViewSet(viewsets.ModelViewSet):
    queryset = Peaje.objects.all().order_by("nombre")
    serializer_class = PeajeSerializer
    permission_classes = [IsAuthenticated]


class CamaraViewSet(viewsets.ModelViewSet):
    queryset = Camara.objects.all().order_by("codigo")
    serializer_class = CamaraSerializer
    permission_classes = [IsAuthenticated]


class PasoPeajeViewSet(viewsets.ModelViewSet):
    queryset = PasoPeaje.objects.all().order_by("-fecha_hora")
    serializer_class = PasoPeajeSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["post"], url_path="simular")
    def simular(self, request):
        placa_detectada = request.data.get("placa_detectada")
        peaje_id = request.data.get("peaje")
        camara_id = request.data.get("camara")

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

        if vehiculo:
            billetera = Billetera.objects.filter(usuario=vehiculo.usuario).first()

            if billetera and billetera.estado == Billetera.Estado.ACTIVA:
                if billetera.saldo >= peaje.tarifa:
                    billetera.saldo -= peaje.tarifa
                    billetera.save()

                    estado_pago = PasoPeaje.EstadoPago.PAGADO

                    transaccion = Transaccion.objects.create(
                        billetera=billetera,
                        monto=peaje.tarifa,
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