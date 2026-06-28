class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api';

  static const String token = '/auth/token/';
  static const String tokenRefresh = '/auth/token/refresh/';

  static const String registro = '/usuarios/usuarios/registro/';
  static const String miPerfil = '/usuarios/perfiles/mi-perfil/';
  static const String actualizarMiPerfil =
      '/usuarios/perfiles/actualizar-mi-perfil/';

  static const String categoriasVehiculo = '/vehiculos/categorias/';
  static const String vehiculos = '/vehiculos/vehiculos/';
  static const String registrarVehiculoPropio =
      '/vehiculos/vehiculos/registrar-propio/';

  static const String pasosPeaje = '/peajes/pasos-peaje/';

  static const String planesMembresia = '/membresias/planes/';
  static const String comprarMembresia = '/membresias/membresias/comprar/';
  static const String miMembresiaActiva =
      '/membresias/membresias/mi-membresia-activa/';

  static const String crearAvisoRobo = '/seguridad/avisos-robo/crear-aviso/';
  static const String avisosRobo = '/seguridad/avisos-robo/';
  static const String alertas = '/seguridad/alertas/';

  static const String miBilletera = '/pagos/billeteras/mi-billetera/';
  static const String recargarBilletera = '/pagos/billeteras/recargar/';
}