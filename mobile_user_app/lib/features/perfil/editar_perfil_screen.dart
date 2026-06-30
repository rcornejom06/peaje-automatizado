import 'package:flutter/material.dart';

import '../../core/services/perfil_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> perfil;

  const EditarPerfilScreen({
    super.key,
    required this.perfil,
  });

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final PerfilService _perfilService = PerfilService();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _cedulaController = TextEditingController();

  bool _guardando = false;
  String _error = '';

  @override
  void initState() {
    super.initState();

    final usuarioDetalle = widget.perfil['usuario_detalle'];
    final usuario = widget.perfil['usuario'];

    Map<String, dynamic> datosUsuario = {};

    if (usuarioDetalle is Map<String, dynamic>) {
      datosUsuario = usuarioDetalle;
    } else if (usuario is Map<String, dynamic>) {
      datosUsuario = usuario;
    }

    _nombreController.text = datosUsuario['first_name']?.toString() ?? '';
    _apellidoController.text = datosUsuario['last_name']?.toString() ?? '';
    _correoController.text = datosUsuario['email']?.toString() ?? '';
    _telefonoController.text = widget.perfil['telefono']?.toString() ?? '';
    _cedulaController.text = widget.perfil['cedula']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
      _error = '';
    });

    try {
      await _perfilService.actualizarMiPerfil(
        firstName: _nombreController.text.trim(),
        lastName: _apellidoController.text.trim(),
        email: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        cedula: _cedulaController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo es obligatorio';
              }

              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget _bloqueError() {
    if (_error.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        _error,
        style: TextStyle(
          color: Colors.red.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar datos personales'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: primaryBlue,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Actualizar información',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 22),

                  _campoTexto(
                    controller: _nombreController,
                    label: 'Nombre',
                    icon: Icons.person_outline,
                  ),

                  _campoTexto(
                    controller: _apellidoController,
                    label: 'Apellido',
                    icon: Icons.badge_outlined,
                  ),

                  _campoTexto(
                    controller: _correoController,
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese su correo';
                      }

                      if (!value.contains('@')) {
                        return 'Ingrese un correo válido';
                      }

                      return null;
                    },
                  ),

                  _campoTexto(
                    controller: _telefonoController,
                    label: 'Teléfono',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  _campoTexto(
                    controller: _cedulaController,
                    label: 'Cédula',
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number,
                  ),

                  _bloqueError(),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardarCambios,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _guardando ? 'Guardando...' : 'Guardar cambios',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}