import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/auth/verificar_correo_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/cedula_validator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _cargando = false;
  String _error = '';
  String _mensaje = '';
  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;
  bool _aceptaTerminos = false;

  bool _soloLetras(String texto) {
    final regex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$");
    return regex.hasMatch(texto.trim());
  }

  bool _soloNumeros(String texto) {
    final regex = RegExp(r"^\d+$");
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

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_aceptaTerminos) {
      setState(() {
        _error = 'Debes aceptar los términos y condiciones para registrarte.';
        _mensaje = '';
      });

      await Future.delayed(const Duration(milliseconds: 150));

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }

      return;
    }

    final email = _emailController.text.trim();
    final nombreFormateado = _capitalizarPalabras(_firstNameController.text);
    final apellidoFormateado = _capitalizarPalabras(_lastNameController.text);

    _firstNameController.text = nombreFormateado;
    _lastNameController.text = apellidoFormateado;

    setState(() {
      _cargando = true;
      _error = '';
      _mensaje = '';
    });

    try {
      await _authService.registrarUsuario(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        email: email,
        firstName: nombreFormateado,
        lastName: apellidoFormateado,
        cedula: _cedulaController.text.trim(),
        telefono: _telefonoController.text.trim(),
        aceptaTerminos: _aceptaTerminos,
      );

      if (!mounted) return;

      setState(() {
        _mensaje = 'Cuenta creada. Revisa tu correo para verificarla.';
      });

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerificarCorreoScreen(email: email),
        ),
      );
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

  void _mostrarTerminosCondiciones() {
    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Términos y condiciones'),
          content: const SingleChildScrollView(
            child: Text(
              'Al registrarte en VíaSmart aceptas que tus datos personales, '
              'vehículos registrados, movimientos de billetera, membresías y pasos '
              'por peaje sean utilizados únicamente para la operación del sistema '
              'de peaje automatizado.\n\n'
              'El usuario declara que la información registrada es verdadera y se '
              'compromete a mantener actualizados sus datos personales, vehículos '
              'y métodos de pago registrados.\n\n'
              'El sistema podrá registrar eventos de paso por peaje, cobros '
              'automáticos, uso de membresías, recargas de billetera y '
              'notificaciones relacionadas con la cuenta.\n\n'
              'Las recargas y pagos realizados en la aplicación forman parte del '
              'historial de movimientos de la billetera virtual del usuario.\n\n'
              'No se almacenará información sensible completa de tarjetas bancarias '
              'ni códigos CVV. Las tarjetas se guardan de forma simulada mostrando '
              'solo los últimos cuatro dígitos.\n\n'
              'El usuario acepta recibir notificaciones relacionadas con el estado '
              'de sus vehículos, pagos, membresías, avisos de seguridad y pasos '
              'por peaje.\n\n'
              'Al continuar, aceptas estos términos y condiciones.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);

                if (!mounted) return;

                setState(() {
                  _aceptaTerminos = true;
                  _error = '';
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
              ),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
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

  Widget _terminosCheckbox(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: _aceptaTerminos
            ? colors.primaryContainer.withAlpha(80)
            : colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _aceptaTerminos ? colors.primary : colors.outline.withAlpha(80),
        ),
      ),
      child: CheckboxListTile(
        value: _aceptaTerminos,
        onChanged: _cargando
            ? null
            : (value) {
                setState(() {
                  _aceptaTerminos = value ?? false;

                  if (_aceptaTerminos) {
                    _error = '';
                  }
                });
              },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Acepto los '),
            GestureDetector(
              onTap: _mostrarTerminosCondiciones,
              child: Text(
                'términos y condiciones',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        subtitle: const Text(
          'Debes aceptarlos para poder crear tu cuenta.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              controller: _scrollController,
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
                            const SizedBox(height: 16),

                            Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors.primary,
                                    colors.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary.withAlpha(35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_add,
                                size: 38,
                                color: colors.onPrimary,
                              ),
                            ),

                            const SizedBox(height: 24),

                            Text(
                              'Crear tu cuenta',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Únete a Mi Peaje en segundos',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium,
                            ),

                            const SizedBox(height: 32),

                            _FormSection(
                              title: 'Información de acceso',
                              children: [
                                _CustomTextFormField(
                                  controller: _usernameController,
                                  label: 'Usuario',
                                  hint: 'tu_usuario',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'El usuario es obligatorio';
                                    }

                                    if (value.trim().length < 3) {
                                      return 'El usuario debe tener mínimo 3 caracteres';
                                    }

                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _CustomTextFormField(
                                  controller: _emailController,
                                  label: 'Correo electrónico',
                                  hint: 'tu@email.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'El correo es obligatorio';
                                    }

                                    if (!value.contains('@')) {
                                      return 'Ingresa un correo válido';
                                    }

                                    return null;
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            _FormSection(
                              title: 'Información personal',
                              children: [
                                _CustomTextFormField(
                                  controller: _firstNameController,
                                  label: 'Nombre',
                                  hint: 'Juan',
                                  icon: Icons.badge_outlined,
                                  keyboardType: TextInputType.name,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(
                                        r"[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]",
                                      ),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'El nombre es obligatorio';
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
                                const SizedBox(height: 12),
                                _CustomTextFormField(
                                  controller: _lastNameController,
                                  label: 'Apellido',
                                  hint: 'Pérez',
                                  icon: Icons.badge_outlined,
                                  keyboardType: TextInputType.name,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(
                                        r"[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]",
                                      ),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'El apellido es obligatorio';
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
                                const SizedBox(height: 12),
                                _CustomTextFormField(
                                  controller: _cedulaController,
                                  label: 'Cédula de identidad',
                                  hint: '1234567890',
                                  icon: Icons.credit_card_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'La cédula es obligatoria';
                                    }

                                    if (!_soloNumeros(value)) {
                                      return 'La cédula solo debe contener números';
                                    }

                                    if (value.trim().length != 10) {
                                      return 'La cédula debe tener 10 dígitos';
                                    }

                                    if (!validarCedulaEcuatoriana(value)) {
                                      return 'Verifica que la cédula tenga 10 dígitos y sea válida para Ecuador';
                                    }

                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _CustomTextFormField(
                                  controller: _telefonoController,
                                  label: 'Teléfono',
                                  hint: '0999999999',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'El teléfono es obligatorio';
                                    }

                                    if (!_soloNumeros(value)) {
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
                              ],
                            ),

                            const SizedBox(height: 22),

                            _FormSection(
                              title: 'Contraseña',
                              children: [
                                _CustomTextFormField(
                                  controller: _passwordController,
                                  label: 'Contraseña',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  obscureText: !_mostrarPassword,
                                  suffixIcon: _mostrarPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  onSuffixTap: () {
                                    setState(() {
                                      _mostrarPassword = !_mostrarPassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'La contraseña es obligatoria';
                                    }

                                    if (value.length < 8) {
                                      return 'Mínimo 8 caracteres';
                                    }

                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _CustomTextFormField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirmar contraseña',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  obscureText: !_mostrarConfirmPassword,
                                  suffixIcon: _mostrarConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  onSuffixTap: () {
                                    setState(() {
                                      _mostrarConfirmPassword =
                                          !_mostrarConfirmPassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Confirma tu contraseña';
                                    }

                                    if (value != _passwordController.text) {
                                      return 'Las contraseñas no coinciden';
                                    }

                                    return null;
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            _terminosCheckbox(context),

                            const SizedBox(height: 16),

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
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _registrar,
                                child: _cargando
                                    ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: colors.onPrimary,
                                        ),
                                      )
                                    : const Text('Crear cuenta'),
                              ),
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: !_cargando
                                    ? () {
                                        Navigator.pop(context);
                                      }
                                    : null,
                                child: const Text('Ya tengo cuenta'),
                              ),
                            ),

                            const SizedBox(height: 30),

                            Text(
                              'Tu registro requiere aceptar los términos y condiciones.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall,
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
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

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final List<TextInputFormatter>? inputFormatters;

  const _CustomTextFormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.onSuffixTap,
    this.inputFormatters,
  });

  @override
  State<_CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<_CustomTextFormField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: colors.primary.withAlpha(22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: widget.validator,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused ? colors.primary : colors.onSurfaceVariant,
          ),
          suffixIcon: widget.suffixIcon != null
              ? IconButton(
                  icon: Icon(
                    widget.suffixIcon,
                    color: _isFocused
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  onPressed: widget.onSuffixTap,
                )
              : null,
        ),
      ),
    );
  }
}