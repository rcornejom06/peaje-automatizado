import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/perfil.dart';
import '../data/perfil_repository.dart';

/// Repositorio de perfil (inyectable/override-able en tests).
final perfilRepositoryProvider = Provider<PerfilRepository>(
  (ref) => PerfilRepository(),
);

/// Estado del perfil del usuario: carga inicial + refresco manual.
final perfilControllerProvider =
    AsyncNotifierProvider<PerfilController, Perfil>(PerfilController.new);

class PerfilController extends AsyncNotifier<Perfil> {
  @override
  Future<Perfil> build() {
    return ref.read(perfilRepositoryProvider).obtenerMiPerfil();
  }

  /// Vuelve a pedir el perfil al backend (pull-to-refresh, tras editar, etc.).
  Future<void> refrescar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(perfilRepositoryProvider).obtenerMiPerfil(),
    );
  }
}
