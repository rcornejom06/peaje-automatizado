import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

      Navigator.pop(context);
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

  Future<void> _reenviarCodigo() async {
    setState(() {
      _reenviando = true;
      _error = '';
      _mensaje = '';
    });

    try {
      await _authService.reenviarCodigo(email: widget.email);

      if (!mounted) return;

      setState(() {
        _mensaje = 'Código reenviado correctamente. Revisa tu correo.';
      });
    } catch (e) {
      if (!mounted) return;

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

  Widget _mensajeEstado({
    required BuildContext context,
    required String mensaje,
    required bool esError,
  }) {
    if (mensaje.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    final backgroundColor =
        esError ? colors.errorContainer : colors.secondaryContainer;
    final foregroundColor =
        esError ? colors.onErrorContainer : colors.onSecondaryContainer;

    final icon = esError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: foregroundColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
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
        title: const Text('Verificar correo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            color: colors.onPrimaryContainer,
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Revisa tu correo',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Enviamos un código de verificación a:',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),

                        const SizedBox(height: 32),

                        TextFormField(
                          controller: _codigoController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Código de verificación',
                            hintText: '123456',
                            prefixIcon: Icon(Icons.lock_outline),
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
                          onFieldSubmitted: (_) => _verificarCodigo(),
                        ),

                        const SizedBox(height: 20),

                        _mensajeEstado(
                          context: context,
                          mensaje: _error,
                          esError: true,
                        ),

                        _mensajeEstado(
                          context: context,
                          mensaje: _mensaje,
                          esError: false,
                        ),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _cargando ? null : _verificarCodigo,
                            icon: _cargando
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: colors.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.verified_outlined),
                            label: Text(
                              _cargando
                                  ? 'Verificando...'
                                  : 'Verificar código',
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton.icon(
                          onPressed: _reenviando ? null : _reenviarCodigo,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            _reenviando
                                ? 'Reenviando...'
                                : 'Reenviar código',
                          ),
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