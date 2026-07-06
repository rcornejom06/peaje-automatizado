import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import '../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _cargando = false;
  String _error = '';
  bool _mostrarPassword = false;

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
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  Future<void> _login() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      await _authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
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
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color darkGray = Color(0xFF0F172A);
    const Color lightGray = Color(0xFFF8FAFC);
    const Color borderGray = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: lightGray,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 64),

                  // Logo y titulo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryBlue, Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withAlpha(30),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_parking,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Mi Peaje',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: darkGray,
                      letterSpacing: -0.8,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Accede a tu cuenta de peajes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: darkGray.withAlpha(180),
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Campo usuario
                  _CustomTextField(
                    controller: _usernameController,
                    label: 'Usuario o email',
                    icon: Icons.person_outline,
                    hint: 'ejemplo@email.com',
                    enabled: !_cargando,
                  ),

                  const SizedBox(height: 16),

                  // Campo contraseña
                  _CustomTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    hint: '••••••••',
                    obscureText: !_mostrarPassword,
                    enabled: !_cargando,
                    onSuffixTap: () {
                      setState(() {
                        _mostrarPassword = !_mostrarPassword;
                      });
                    },
                    suffixIcon: _mostrarPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),

                  const SizedBox(height: 12),

                  // Link olvido contraseña
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),

                  const SizedBox(height: 24),

                  // Mensaje de error
                  if (_error.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Botón login
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: primaryBlue.withAlpha(150),
                      ),
                      child: _cargando
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                          AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                          : const Text(
                        'Ingresar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: borderGray,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'o',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: darkGray.withAlpha(150),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: borderGray,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botón crear cuenta
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: !_cargando
                          ? () {
                        Navigator.pushNamed(context, '/registro');
                      }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlue,
                        side: const BorderSide(
                          color: borderGray,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledForegroundColor: primaryBlue.withAlpha(150),
                      ),
                      child: const Text(
                        'Crear nueva cuenta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Text(
                    '© 2024 Mi Peaje. Todos los derechos reservados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: darkGray.withAlpha(120),
                      letterSpacing: 0.1,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final bool enabled;
  final VoidCallback? onSuffixTap;
  final IconData? suffixIcon;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.onSuffixTap,
    this.suffixIcon,
  });

  @override
  State<_CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<_CustomTextField> {
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
    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color borderGray = Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
          BoxShadow(
            color: primaryBlue.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused ? primaryBlue : const Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: widget.suffixIcon != null
              ? IconButton(
            icon: Icon(
              widget.suffixIcon,
              color: _isFocused ? primaryBlue : const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: widget.onSuffixTap,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderGray, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderGray, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: borderGray.withAlpha(100),
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            letterSpacing: 0.1,
          ),
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF94A3B8).withAlpha(150),
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}