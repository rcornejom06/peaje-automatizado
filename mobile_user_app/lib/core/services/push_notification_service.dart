import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';
import '../constants/api_config.dart';

@pragma('vm:entry-point')
Future<void> manejarMensajeEnSegundoPlano(RemoteMessage mensaje) async {
  // Handler requerido para Firebase Messaging en segundo plano.
}

class PushNotificationService {
  static final PushNotificationService _instancia =
      PushNotificationService._interno();

  factory PushNotificationService() => _instancia;

  PushNotificationService._interno();

  final FirebaseMessaging _mensajeria = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _notificacionesLocales =
      FlutterLocalNotificationsPlugin();

  final ApiService _apiService = ApiService();

  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'viasmart_notificaciones',
    'Notificaciones de ViaSmart',
    description: 'Alertas, pagos y avisos del sistema de peaje.',
    importance: Importance.high,
  );

  bool _inicializado = false;

  Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;

    FirebaseMessaging.onBackgroundMessage(manejarMensajeEnSegundoPlano);

    await _mensajeria.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings inicializacionAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings inicializacionIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings inicializacion = InitializationSettings(
      android: inicializacionAndroid,
      iOS: inicializacionIOS,
    );

    await _notificacionesLocales.initialize(
      settings: inicializacion,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notificación tocada: ${response.payload}');
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificacionesLocales.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_canal);

    FirebaseMessaging.onMessage.listen((RemoteMessage mensaje) {
      mostrarNotificacionLocal(mensaje);
    });
  }

  Future<void> mostrarNotificacionLocal(RemoteMessage mensaje) async {
    final RemoteNotification? notificacion = mensaje.notification;

    final String titulo =
        notificacion?.title ??
        mensaje.data['titulo']?.toString() ??
        mensaje.data['title']?.toString() ??
        'VíaSmart';

    final String cuerpo =
        notificacion?.body ??
        mensaje.data['mensaje']?.toString() ??
        mensaje.data['body']?.toString() ??
        'Tienes una nueva notificación.';

    const AndroidNotificationDetails detallesAndroid =
        AndroidNotificationDetails(
      'viasmart_notificaciones',
      'Notificaciones de ViaSmart',
      channelDescription: 'Alertas, pagos y avisos del sistema de peaje.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails detallesIOS = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails detalles = NotificationDetails(
      android: detallesAndroid,
      iOS: detallesIOS,
    );

    await _notificacionesLocales.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: titulo,
      body: cuerpo,
      notificationDetails: detalles,
      payload: mensaje.data.toString(),
    );
  }

  Future<void> registrarTokenEnBackend() async {
    try {
      final String? token = await _mensajeria.getToken();

      if (token == null || token.isEmpty) return;

      await _apiService.post(
        ApiConfig.registrarTokenPush,
        body: {
          'token': token,
          'plataforma': Platform.isAndroid ? 'android' : 'ios',
        },
      );
    } catch (error) {
      debugPrint('Error registrando token push: $error');
    }
  }
}