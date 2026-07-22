class ApiConfig {
  //static const String baseUrl = 'http://localhost:8000/api';
  static const String baseUrl = 'http://172.20.10.2:8000/api';
  //static const String baseUrl = 'http://192.168.1.117:8000/api';

  static const String token = '/auth/token/';
  static const String tokenRefresh = '/auth/token/refresh/';

  static const String registro = '/usuarios/registro/';
  static const String miPerfil = '/usuarios/perfiles/mi-perfil/';
  static const String actualizarMiPerfil = '/usuarios/perfiles/actualizar-mi-perfil/';
  static const String cambiarPassword = '/usuarios/perfiles/cambiar-password/';

  static const String verificarCorreo = '/usuarios/verificar-correo/';
  static const String reenviarCodigo = '/usuarios/reenviar-codigo/';
  static const String solicitarResetPassword = '/usuarios/solicitar-reset-password/';
  static const String confirmarResetPassword = '/usuarios/confirmar-reset-password/';


  static const String vehiculos = '/vehiculos/';
  static const String categoriasVehiculo = '/vehiculos/categorias/';
  static const String registrarVehiculoPropio = '/vehiculos/registrar-propio/';

  static const String pasosPeaje = '/peajes/pasos-peaje/';

  static const String planesMembresia = '/membresias/planes/';
  static const String comprarMembresia = '/membresias/comprar/';
  static const String miMembresiaActiva =
      '/membresias/mi-membresia-activa/';

  static const String crearAvisoRobo = '/seguridad/avisos-robo/crear-aviso/';
  static const String avisosRobo = '/seguridad/avisos-robo/';
  static const String alertas = '/seguridad/alertas/';

  static const String miBilletera = '/pagos/billeteras/mi-billetera/';
  static const String tarjetas = '/pagos/tarjetas/';
  static const String recargarBilletera = '/pagos/billeteras/recargar/';

  static const String notificaciones = '/notificaciones/';
static const String notificacionesNoLeidas =
    '/notificaciones/no-leidas/';
  static const String registrarTokenPush =
      '/notificaciones/dispositivos/registrar-token/';
}