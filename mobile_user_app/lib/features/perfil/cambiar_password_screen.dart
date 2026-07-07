import 'package:flutter/material.dart';

import '../../core/services/perfil_service.dart';

class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final PerfilService _perfilService = PerfilService();

  final _passwordActualController = TextEditingController();
  final _nuevaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _guardando = false;
  bool _mostrarActual = false;
  bool _mostrarNueva = false;
  bool _mostrarConfirmar = false;

  String _error = '';

  @override
  void dispose() {
    _passwordActualController.dispose();
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
      _error = '';
    });

    try {
      await _perfilService.cambiarPassword(
        passwordActual: _passwordActualController.text.trim(),
        nuevaPassword: _nuevaPasswordController.text.trim(),
        confirmarPassword: _confirmarPasswordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente.'),
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

  Widget _campoPassword({
    required TextEditingController controller,
    required String label,
    required bool mostrar,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: !mostrar,
        validator: validator,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              mostrar ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: onToggle,
          ),
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
        title: const Text('Cambiar contraseña'),
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
                            Icons.password,
                            color: colors.onPrimaryContainer,
                            size: 38,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Actualiza tu contraseña',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Por seguridad, ingresa tu contraseña actual.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 24),

                        _campoPassword(
                          controller: _passwordActualController,
                          label: 'Contraseña actual',
                          mostrar: _mostrarActual,
                          onToggle: () {
                            setState(() {
                              _mostrarActual = !_mostrarActual;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese su contraseña actual';
                            }

                            return null;
                          },
                        ),

                        _campoPassword(
                          controller: _nuevaPasswordController,
                          label: 'Nueva contraseña',
                          mostrar: _mostrarNueva,
                          onToggle: () {
                            setState(() {
                              _mostrarNueva = !_mostrarNueva;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese la nueva contraseña';
                            }

                            if (value.trim().length < 8) {
                              return 'La contraseña debe tener mínimo 8 caracteres';
                            }

                            if (value.trim() ==
                                _passwordActualController.text.trim()) {
                              return 'La nueva contraseña debe ser diferente';
                            }

                            return null;
                          },
                        ),

                        _campoPassword(
                          controller: _confirmarPasswordController,
                          label: 'Confirmar nueva contraseña',
                          mostrar: _mostrarConfirmar,
                          onToggle: () {
                            setState(() {
                              _mostrarConfirmar = !_mostrarConfirmar;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Confirme la nueva contraseña';
                            }

                            if (value.trim() !=
                                _nuevaPasswordController.text.trim()) {
                              return 'Las contraseñas no coinciden';
                            }

                            return null;
                          },
                        ),

                        _bloqueError(context),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _guardando ? null : _cambiarPassword,
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
                                  : 'Cambiar contraseña',
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