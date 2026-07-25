import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/push_notification_service.dart';

/// Arranque común a todos los entrypoints (dev/prod).
Future<void> bootstrap(Environment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setEnvironment(environment);

  // Firebase/push NO deben impedir que la app arranque: en web no hay
  // google-services (Firebase.initializeApp exige FirebaseOptions y lanza),
  // y ante cualquier fallo preferimos cargar la UI sin notificaciones push.
  try {
    await Firebase.initializeApp();
    await PushNotificationService().inicializar();
  } catch (e) {
    debugPrint('Firebase/push no se inicializó (se continúa sin push): $e');
  }

  // ProviderScope habilita Riverpod en toda la app.
  runApp(const ProviderScope(child: PeajeUserApp()));
}

/// Entrypoint por defecto (equivale a dev). Los builds usan
/// `lib/main/main_dev.dart` y `lib/main/main_prod.dart`.
Future<void> main() => bootstrap(Environment.dev);
