import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/mobile_app_header.dart';
import 'application/perfil_providers.dart';
import 'cambiar_password_screen.dart';
import 'data/perfil.dart';
import 'editar_perfil_screen.dart';

/// Pantalla "Mi perfil". El estado (carga / error / datos) vive en
/// [perfilControllerProvider]; aquí solo se pinta según ese estado.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilControllerProvider);

    Future<void> refrescar() =>
        ref.read(perfilControllerProvider.notifier).refrescar();

    return Scaffold(
      appBar: MobileAppHeader(
        title: 'Mi perfil',
        subtitle: 'Datos personales',
        icon: Icons.person,
        showBackButton: true,
        showRefresh: true,
        onRefresh: refrescar,
        showNotifications: true,
        showLogout: false,
      ),
      body: perfilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          mensaje: error.toString().replaceFirst('Exception: ', ''),
          onReintentar: refrescar,
        ),
        data: (perfil) => _ContenidoPerfil(
          perfil: perfil,
          onRefrescar: refrescar,
          onEditar: () => _irAEditarPerfil(context, ref, perfil),
          onCambiarPassword: () => _irACambiarPassword(context),
        ),
      ),
    );
  }

  Future<void> _irAEditarPerfil(
    BuildContext context,
    WidgetRef ref,
    Perfil perfil,
  ) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPerfilScreen(perfil: perfil),
      ),
    );

    if (resultado == true) {
      await ref.read(perfilControllerProvider.notifier).refrescar();
    }
  }

  Future<void> _irACambiarPassword(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CambiarPasswordScreen(),
      ),
    );
  }
}

/// Muestra el valor o "Sin dato" cuando viene vacío.
String _texto(String valor) => valor.trim().isEmpty ? 'Sin dato' : valor;

class _ContenidoPerfil extends StatelessWidget {
  const _ContenidoPerfil({
    required this.perfil,
    required this.onRefrescar,
    required this.onEditar,
    required this.onCambiarPassword,
  });

  final Perfil perfil;
  final Future<void> Function() onRefrescar;
  final VoidCallback onEditar;
  final VoidCallback onCambiarPassword;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefrescar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderPerfil(perfil: perfil),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onEditar,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar datos personales'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: onCambiarPassword,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Cambiar contraseña'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Información personal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _DatoCard(
                    titulo: 'Nombre',
                    valor: _texto(perfil.nombre),
                    icono: Icons.badge,
                  ),
                  _DatoCard(
                    titulo: 'Apellido',
                    valor: _texto(perfil.apellido),
                    icono: Icons.badge_outlined,
                  ),
                  _DatoCard(
                    titulo: 'Correo',
                    valor: _texto(perfil.correo),
                    icono: Icons.email_outlined,
                  ),
                  _DatoCard(
                    titulo: 'Cédula',
                    valor: _texto(perfil.cedula),
                    icono: Icons.credit_card,
                  ),
                  _DatoCard(
                    titulo: 'Teléfono',
                    valor: _texto(perfil.telefono),
                    icono: Icons.phone_outlined,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPerfil extends StatelessWidget {
  const _HeaderPerfil({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: colors.onPrimary,
            child: Icon(Icons.person, size: 50, color: colors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            _texto(perfil.username),
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _texto(perfil.correo),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onPrimary.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoCard extends StatelessWidget {
  const _DatoCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: colors.onPrimaryContainer, size: 22),
        ),
        title: Text(
          titulo,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        subtitle: Text(
          valor,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 52, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  'No se pudo cargar el perfil',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onReintentar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Intentar nuevamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
