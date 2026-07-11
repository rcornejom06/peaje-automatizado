import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/cedula_validator.dart';
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

  bool _soloLetras(String texto) {
    final regex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$");
    return regex.hasMatch(texto.trim());
  }

  String _capitalizarPalabras(String texto) {
    texto = texto.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (texto.isEmpty) {
      return texto;
    }

    return texto.split(' ').map((palabra) {
      if (palabra.isEmpty) return palabra;

      final primeraLetra = palabra.substring(0, 1).toUpperCase();
      final resto =
          palabra.length > 1 ? palabra.substring(1).toLowerCase() : '';

      return '$primeraLetra$resto';
    }).join(' ');
  }

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

    final nombreFormateado = _capitalizarPalabras(_nombreController.text);
    final apellidoFormateado = _capitalizarPalabras(_apellidoController.text);

    _nombreController.text = nombreFormateado;
    _apellidoController.text = apellidoFormateado;

    setState(() {
      _guardando = true;
      _error = '';
    });

    try {
      await _perfilService.actualizarMiPerfil(
        firstName: nombreFormateado,
        lastName: apellidoFormateado,
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
    List<TextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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

  Widget _bloqueError(BuildContext context) {
    if (_error.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: colors.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar datos personales'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: colors.onPrimaryContainer,
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Actualizar información',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Modifica tus datos personales y guarda los cambios.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 24),

                        _campoTexto(
                          controller: _nombreController,
                          label: 'Nombre',
                          icon: Icons.person_outline,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]"),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese su nombre';
                            }

                            if (!_soloLetras(value)) {
                              return 'El nombre solo debe contener letras';
                            }

                            if (value.trim().length < 2) {
                              return 'El nombre debe tener mínimo 2 letras';
                            }

                            return null;
                          },
                        ),

                        _campoTexto(
                          controller: _apellidoController,
                          label: 'Apellido',
                          icon: Icons.badge_outlined,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]"),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese su apellido';
                            }

                            if (!_soloLetras(value)) {
                              return 'El apellido solo debe contener letras';
                            }

                            if (value.trim().length < 2) {
                              return 'El apellido debe tener mínimo 2 letras';
                            }

                            return null;
                          },
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese su teléfono';
                            }

                            if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                              return 'El teléfono solo debe contener números';
                            }

                            if (value.trim().length != 10) {
                              return 'El teléfono debe tener 10 dígitos';
                            }

                            if (!value.trim().startsWith('09')) {
                              return 'El celular debe iniciar con 09';
                            }

                            return null;
                          },
                        ),

                        _campoTexto(
                          controller: _cedulaController,
                          label: 'Cédula',
                          icon: Icons.credit_card,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese su cédula';
                            }

                            if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                              return 'La cédula solo debe contener números';
                            }

                            if (value.trim().length != 10) {
                              return 'La cédula debe tener 10 dígitos';
                            }

                            if (!validarCedulaEcuatoriana(value.trim())) {
                              return 'La cédula ingresada no es válida para Ecuador';
                            }

                            return null;
                          },
                        ),

                        _bloqueError(context),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _guardando ? null : _guardarCambios,
                            icon: _guardando
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _guardando
                                  ? 'Guardando...'
                                  : 'Guardar cambios',
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: _guardando
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}