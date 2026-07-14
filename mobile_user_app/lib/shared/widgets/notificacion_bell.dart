import 'package:flutter/material.dart';

import '../../core/services/notificacion_service.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final NotificacionService _notificacionService = NotificacionService();

  int _noLeidas = 0;
  bool _cargando = false;

  Future<void> _cargarNoLeidas() async {
    if (_cargando) return;

    try {
      _cargando = true;
      final total = await _notificacionService.obtenerNoLeidas();

      if (!mounted) return;

      setState(() {
        _noLeidas = total;
      });
    } catch (_) {
      // No bloqueamos la pantalla si falla el contador.
    } finally {
      _cargando = false;
    }
  }

  Future<void> _abrirNotificaciones() async {
    await Navigator.pushNamed(context, '/notificaciones');
    await _cargarNoLeidas();
  }

  @override
  void initState() {
    super.initState();
    _cargarNoLeidas();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notificaciones',
      onPressed: _abrirNotificaciones,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (_noLeidas > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  _noLeidas > 99 ? '99+' : _noLeidas.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}