import 'package:flutter/material.dart';
import '../../shared/widgets/mobile_app_header.dart';
import 'cambiar_password_screen.dart';
import '../../core/constants/api_config.dart';
import '../../core/services/api_service.dart';
import 'editar_perfil_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ApiService _apiService = ApiService();

  bool _cargando = true;
  String _error = '';
  Map<String, dynamic>? _perfil;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
      });

      final data = await _apiService.get(ApiConfig.miPerfil);

      if (!mounted) return;

      setState(() {
        _perfil = Map<String, dynamic>.from(data);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _irAEditarPerfil() async {
    if (_perfil == null) return;

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditarPerfilScreen(
              perfil: _perfil!,
            ),
      ),
    );

    if (resultado == true) {
      await _cargarPerfil();
    }
  }

  Future<void> _irACambiarPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CambiarPasswordScreen(),
      ),
    );
  }

  String _texto(dynamic valor) {
    if (valor == null || valor
        .toString()
        .trim()
        .isEmpty) {
      return 'Sin dato';
    }

    return valor.toString();
  }

  dynamic _usuarioCampo(String campo) {
    final usuario = _perfil?['usuario'];

    if (usuario is Map && usuario[campo] != null) {
      return usuario[campo];
    }

    final usuarioDetalle = _perfil?['usuario_detalle'];

    if (usuarioDetalle is Map && usuarioDetalle[campo] != null) {
      return usuarioDetalle[campo];
    }

    return null;
  }

  String _username() {
    return _texto(
      _usuarioCampo('username') ??
          _perfil?['usuario_username'] ??
          _perfil?['username'],
    );
  }

  String _nombre() {
    return _texto(
      _usuarioCampo('first_name') ??
          _perfil?['first_name'] ??
          _perfil?['nombre'],
    );
  }

  String _apellido() {
    return _texto(
      _usuarioCampo('last_name') ??
          _perfil?['last_name'] ??
          _perfil?['apellido'],
    );
  }

  String _correo() {
    return _texto(
      _usuarioCampo('email') ??
          _perfil?['email'] ??
          _perfil?['correo'],
    );
  }

  Widget _dato({
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

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
          child: Icon(
            icono,
            color: colors.onPrimaryContainer,
            size: 22,
          ),
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

  Widget _headerPerfil() {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            colors.secondary,
          ],
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
            child: Icon(
              Icons.person,
              size: 50,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _username(),
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _correo(),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onPrimary.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonEditarPerfil() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _perfil == null ? null : _irAEditarPerfil,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Editar datos personales'),
      ),
    );
  }

  Widget _botonCambiarPassword() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _irACambiarPassword,
        icon: const Icon(Icons.lock_outline),
        label: const Text('Cambiar contraseña'),
      ),
    );
  }

  Widget _tituloSeccion(String titulo) {
    return Text(
      titulo,
      style: Theme
          .of(context)
          .textTheme
          .titleLarge
          ?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _contenidoPerfil() {
    return RefreshIndicator(
      onRefresh: _cargarPerfil,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerPerfil(),

                  const SizedBox(height: 18),

                  _botonEditarPerfil(),

                  const SizedBox(height: 10),

                  _botonCambiarPassword(),

                  const SizedBox(height: 24),

                  _tituloSeccion('Información personal'),

                  const SizedBox(height: 12),

                  _dato(
                    titulo: 'Nombre',
                    valor: _nombre(),
                    icono: Icons.badge,
                  ),

                  _dato(
                    titulo: 'Apellido',
                    valor: _apellido(),
                    icono: Icons.badge_outlined,
                  ),

                  _dato(
                    titulo: 'Correo',
                    valor: _correo(),
                    icono: Icons.email_outlined,
                  ),

                  _dato(
                    titulo: 'Cédula',
                    valor: _texto(_perfil?['cedula']),
                    icono: Icons.credit_card,
                  ),

                  _dato(
                    titulo: 'Teléfono',
                    valor: _texto(_perfil?['telefono']),
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

  Widget _errorView(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 52,
                  color: colors.error,
                ),
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
                  _error,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _cargarPerfil,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppHeader(
        title: 'Mi perfil',
        subtitle: 'Datos personales',
        icon: Icons.person,
        showBackButton: true,
        showRefresh: true,
        onRefresh: _cargarPerfil,
        showNotifications: true,
        showLogout: false,
      ),

      body: _cargando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error.isNotEmpty
          ? _errorView(context)
          : _contenidoPerfil(),
    );
  }
}