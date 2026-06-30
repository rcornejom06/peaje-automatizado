import 'package:flutter/material.dart';

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
        builder: (_) => EditarPerfilScreen(
          perfil: _perfil!,
        ),
      ),
    );

    if (resultado == true) {
      await _cargarPerfil();
    }
  }

  String _texto(dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) {
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

  String _rol() {
    return _texto(_perfil?['rol']);
  }

  Widget _dato({
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icono,
          color: const Color(0xFF1D4ED8),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          valor,
          style: const TextStyle(
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _headerPerfil() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 48,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _username(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _correo(),
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonEditarPerfil() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _perfil == null ? null : _irAEditarPerfil,
        icon: const Icon(Icons.edit),
        label: const Text('Editar datos personales'),
      ),
    );
  }

  Widget _contenidoPerfil() {
    return RefreshIndicator(
      onRefresh: _cargarPerfil,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerPerfil(),

          const SizedBox(height: 18),

          _botonEditarPerfil(),

          const SizedBox(height: 18),

          const Text(
            'Información personal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

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
            icono: Icons.email,
          ),

          _dato(
            titulo: 'Cédula',
            valor: _texto(_perfil?['cedula']),
            icono: Icons.credit_card,
          ),

          _dato(
            titulo: 'Teléfono',
            valor: _texto(_perfil?['telefono']),
            icono: Icons.phone,
          ),

          _dato(
            titulo: 'Rol',
            valor: _rol(),
            icono: Icons.security,
          ),

          _dato(
            titulo: 'Estado',
            valor: _texto(_perfil?['estado']),
            icono: Icons.verified,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            onPressed: _cargarPerfil,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _contenidoPerfil(),
    );
  }
}