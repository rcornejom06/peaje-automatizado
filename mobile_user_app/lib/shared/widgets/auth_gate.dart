import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/push_notification_service.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';

/// Decide la pantalla inicial de la app según si ya existe una sesión
/// guardada localmente (token en SharedPreferences), en lugar de forzar
/// siempre el login al reabrir la app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().estaAutenticado(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final autenticado = snapshot.data ?? false;

        if (autenticado) {
          // Sesión ya existía: renueva el registro del token push por si
          // cambió desde la última vez (reinstalación, etc.).
          PushNotificationService().registrarTokenEnBackend();
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}