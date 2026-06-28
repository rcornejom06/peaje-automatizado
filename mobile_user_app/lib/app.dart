import 'package:flutter/material.dart';
import 'features/perfil/perfil_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/vehiculos/vehiculos_screen.dart';
import 'features/vehiculos/registrar_vehiculo_screen.dart';
import 'features/billetera/billetera_screen.dart';
import 'features/membresias/membresias_screen.dart';
import 'features/pasos/pasos_screen.dart';
import 'features/seguridad/seguridad_screen.dart';
import 'features/seguridad/crear_aviso_robo_screen.dart';

class PeajeUserApp extends StatelessWidget {
  const PeajeUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peaje Automatizado',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/registro': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/perfil': (_) => const PerfilScreen(),
        '/vehiculos': (_) => const VehiculosScreen(),
        '/registrar-vehiculo': (_) => const RegistrarVehiculoScreen(),
        '/billetera': (_) => const BilleteraScreen(),
        '/membresias': (_) => const MembresiasScreen(),
        '/pasos': (_) => const PasosScreen(),
        '/seguridad': (_) => const SeguridadScreen(),
        '/crear-aviso-robo': (_) => const CrearAvisoRoboScreen(),
      },
    );
  }
}