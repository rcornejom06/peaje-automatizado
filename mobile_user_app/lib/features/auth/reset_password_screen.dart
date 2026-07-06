import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _cargando = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;
  String _error = '';
  String _mensaje = '';

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = '';
      _mensaje = '';
    });

    try {
      await _authService.confirmarResetPassword(
        email: widget.email,
        codigo: _codigoController.text.trim(),
        nuevaPassword: _passwordController.text.trim(),
        confirmarPassword: _confirmPasswordController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _mensaje = 'Contraseña restablecida correctamente.';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
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

  @override
  void dispose() {
    _codigoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva contraseña'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 32),

              const Icon(
                Icons.mark_email_read_outlined,
                size: 72,
                color: primaryBlue,
              ),

              const SizedBox(height: 24),

              Text(
                'Código enviado a:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 32),

              TextFormField(
                controller: _codigoController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Código de seguridad',
                  prefixIcon: Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el código';
                  }

                  if (value.trim().length != 6) {
                    return 'El código debe tener 6 dígitos';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: !_mostrarPassword,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarPassword = !_mostrarPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La contraseña es obligatoria';
                  }

                  if (value.length < 8) {
                    return 'Mínimo 8 caracteres';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_mostrarConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarConfirmPassword = !_mostrarConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Confirma tu contraseña';
                  }

                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              if (_error.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.red.shade50,
                  child: Text(
                    _error,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),

              if (_mensaje.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.green.shade50,
                  child: Text(
                    _mensaje,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _cambiarPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Cambiar contraseña'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}