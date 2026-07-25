import '../../../core/services/perfil_service.dart';
import 'perfil.dart';

/// Acceso a datos del perfil. Envuelve [PerfilService] (que conserva la lógica
/// HTTP existente) y expone objetos [Perfil] tipados a la capa de aplicación.
class PerfilRepository {
  PerfilRepository({PerfilService? service})
      : _service = service ?? PerfilService();

  final PerfilService _service;

  Future<Perfil> obtenerMiPerfil() async {
    final data = await _service.obtenerMiPerfil();
    return Perfil.fromJson(data);
  }

  Future<void> actualizarMiPerfil({
    required String firstName,
    required String lastName,
    required String email,
    required String telefono,
    required String cedula,
  }) {
    return _service.actualizarMiPerfil(
      firstName: firstName,
      lastName: lastName,
      email: email,
      telefono: telefono,
      cedula: cedula,
    );
  }

  Future<void> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
    required String confirmarPassword,
  }) {
    return _service.cambiarPassword(
      passwordActual: passwordActual,
      nuevaPassword: nuevaPassword,
      confirmarPassword: confirmarPassword,
    );
  }
}
