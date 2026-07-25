import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/notificacion_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final NotificacionService _notificacionService = NotificacionService();

  bool _cargando = true;
  String _error = '';
  List<dynamic> _notificaciones = [];
  Timer? _timer;

  Future<void> _cargarNotificaciones() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
      });

      final data = await _notificacionService.obtenerNotificaciones();

      if (!mounted) return;

      setState(() {
        _notificaciones = data;
      });
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

  // Igual que _cargarNotificaciones pero sin mostrar el spinner de carga,
  // para poder llamarla cada 2 segundos sin que la pantalla parpadee.
  Future<void> _actualizarSilenciosamente() async {
    try {
      final data = await _notificacionService.obtenerNotificaciones();

      if (!mounted) return;

      setState(() {
        _notificaciones = data;
      });
    } catch (_) {
      // Si falla una actualización en segundo plano no interrumpimos al
      // usuario; el próximo intento (2s después) lo resuelve solo.
    }
  }

  Future<void> _marcarTodasLeidas() async {
    try {
      await _notificacionService.marcarTodasLeidas();
      await _cargarNotificaciones();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron marcar las notificaciones.'),
        ),
      );
    }
  }

  Future<void> _marcarLeida(dynamic notificacion) async {
    final id = notificacion['id'];

    if (id == null) return;

    try {
      await _notificacionService.marcarLeida(id);
      await _cargarNotificaciones();
    } catch (_) {}
  }

  void _abrirAccionInterna(String tipoAccion) {
    switch (tipoAccion) {
      case 'vehiculos':
        Navigator.pushNamed(context, '/vehiculos');
        break;

      case 'membresias':
        Navigator.pushNamed(context, '/membresias');
        break;

      case 'pasos':
        Navigator.pushNamed(context, '/pasos');
        break;

      case 'seguridad':
        Navigator.pushNamed(context, '/seguridad');
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No hay una acción disponible para esta notificación.'),
          ),
        );
    }
  }

  String _fecha(dynamic valor) {
    if (valor == null) return 'Sin fecha';

    try {
      final fecha = DateTime.parse(valor.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (_) {
      return valor.toString();
    }
  }

  Color _colorTipo(String tipo, ColorScheme colors) {
    switch (tipo.toLowerCase()) {
      case 'alerta':
        return colors.error;
      case 'pago':
        return colors.primary;
      case 'membresia':
        return colors.secondary;
      default:
        return colors.tertiary;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'alerta':
        return Icons.warning_amber_rounded;
      case 'pago':
        return Icons.payments_outlined;
      case 'membresia':
        return Icons.card_membership;
      default:
        return Icons.notifications_none;
    }
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La URL no es válida.')),
      );
      return;
    }

    final abierto = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  Widget _notificacionCard(dynamic notificacion) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    final tipo = notificacion['tipo']?.toString() ?? 'sistema';
    final leida = notificacion['leida'] == true;
    final color = _colorTipo(tipo, colors);
    final urlAccion = notificacion['url_accion']?.toString();
    final tipoAccion = notificacion['tipo_accion']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: leida ? null : () => _marcarLeida(notificacion),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withAlpha(24),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconoTipo(tipo),
                      color: color,
                    ),
                  ),
                  if (!leida)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion['titulo']?.toString() ?? 'Notificación',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificacion['mensaje']?.toString() ?? '',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fecha(notificacion['fecha_hora']),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.outline,
                      ),
                    ),
                    if (urlAccion != null && urlAccion
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _abrirUrl(urlAccion),
                        icon: Icon(
                          tipoAccion == 'mapa'
                              ? Icons.location_on_outlined
                              : Icons.open_in_new,
                        ),
                        label: Text(
                          tipoAccion == 'mapa'
                              ? 'Ver ubicación'
                              : 'Abrir enlace',
                        ),
                      ),
                    ] else
                      if (tipoAccion != null && tipoAccion
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _abrirAccionInterna(tipoAccion),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Ver detalle'),
                        ),
                      ],

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _actualizarSilenciosamente(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            tooltip: 'Marcar todas como leídas',
            onPressed: _marcarTodasLeidas,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarNotificaciones,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error,
            textAlign: TextAlign.center,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _cargarNotificaciones,
        child: _notificaciones.isEmpty
            ? ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.notifications_none, size: 64),
            SizedBox(height: 16),
            Text(
              'No tienes notificaciones.',
              textAlign: TextAlign.center,
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notificaciones.length,
          itemBuilder: (context, index) {
            return _notificacionCard(
              _notificaciones[index],
            );
          },
        ),
      ),
    );
  }
}