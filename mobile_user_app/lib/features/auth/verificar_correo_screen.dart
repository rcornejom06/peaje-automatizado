import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

class VerificarCorreoScreen extends StatefulWidget {
  final String email;

  const VerificarCorreoScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerificarCorreoScreen> createState() => _VerificarCorreoScreenState();
}

class _VerificarCorreoScreenState extends State<VerificarCorreoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _cargando = false;
  bool _reenviando = false;
  String _error = '';
  String _mensaje = '';

  Future<void> _verificarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = '';
      _mensaje = '';
    });

    try {
      await _authService.verificarCorreo(
        email: widget.email,
        codigo: _codigoController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _mensaje = 'Correo verificado correctamente. Ya puedes iniciar sesión.';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.pop(context); // vuelve al login

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

  Future<void> _reenviarCodigo() async {
    setState(() {
      _reenviando = true;
      _error = '';
      _mensaje = '';
    });

    try {
      await _authService.reenviarCodigo(email: widget.email);

      setState(() {
        _mensaje = 'Código reenviado correctamente. Revisa tu correo.';
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _reenviando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color darkGray = Color(0xFF0F172A);
    const Color lightGray = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: const Text('Verificar correo'),
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

              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.white,
                  size: 38,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Revisa tu correo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: darkGray,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Enviamos un código de verificación a:\n${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: darkGray.withAlpha(170),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              TextFormField(
                controller: _codigoController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Código de verificación',
                  hintText: '123456',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

              const SizedBox(height: 20),

              if (_error.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
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
                ),

              if (_mensaje.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    _mensaje,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _verificarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        )
                      : const Text(
                          'Verificar código',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _reenviando ? null : _reenviarCodigo,
                child: Text(
                  _reenviando
                      ? 'Reenviando...'
                      : 'Reenviar código',
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}