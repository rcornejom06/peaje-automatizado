import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/mobile_app_header.dart';
import '../../core/services/paso_peaje_service.dart';
import 'comprobante_paso_screen.dart';

class PasosScreen extends StatefulWidget {
  const PasosScreen({super.key});

  @override
  State<PasosScreen> createState() => _PasosScreenState();
}

class _PasosScreenState extends State<PasosScreen>
    with SingleTickerProviderStateMixin {
  final PasoPeajeService _pasoPeajeService = PasoPeajeService();

  late AnimationController _refreshController;

  bool _cargando = true;
  String _error = '';
  List<dynamic> _pasos = [];

  @override
  void initState() {
    super.initState();

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _cargarPasos();
  }

  Future<void> _cargarPasos() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
      });

      _refreshController.forward();

      final data = await _pasoPeajeService.obtenerPasosPeaje();

      if (!mounted) return;

      setState(() {
        _pasos = data;
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

        _refreshController.reset();
      }
    }
  }

  int? _obtenerPasoId(dynamic paso) {
    if (paso is! Map) return null;

    final valor = paso['id'] ?? paso['id_paso'] ?? paso['paso_id'];

    if (valor is int) return valor;

    return int.tryParse(valor?.toString() ?? '');
  }

  void _abrirComprobante(dynamic paso) {
    final pasoId = _obtenerPasoId(paso);

    if (pasoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el ID del paso.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ComprobantePasoScreen(
              pasoId: pasoId,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  String _texto(dynamic valor) {
    if (valor == null || valor
        .toString()
        .trim()
        .isEmpty) {
      return 'Sin dato';
    }

    return valor.toString();
  }

  String _dinero(dynamic valor) {
    final numero = double.tryParse(valor?.toString() ?? '0') ?? 0;
    return '\$${numero.toStringAsFixed(2)}';
  }

  String _fecha(dynamic valor) {
    if (valor == null) {
      return 'Sin fecha';
    }

    try {
      final fecha = DateTime.parse(valor.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (_) {
      return valor.toString();
    }
  }

  String _obtenerPeaje(dynamic paso) {
    if (paso['peaje_nombre'] != null) {
      return paso['peaje_nombre'].toString();
    }

    if (paso['peaje_detalle'] is Map) {
      return paso['peaje_detalle']['nombre']?.toString() ?? 'Sin peaje';
    }

    if (paso['peaje'] != null) {
      return paso['peaje'].toString();
    }

    return 'Sin peaje';
  }

  String _obtenerCamara(dynamic paso) {
    if (paso['camara_codigo'] != null) {
      return paso['camara_codigo'].toString();
    }

    if (paso['camara_detalle'] is Map) {
      return paso['camara_detalle']['codigo']?.toString() ?? 'Sin cámara';
    }

    if (paso['camara'] != null) {
      return paso['camara'].toString();
    }

    return 'Sin cámara';
  }

  Color _colorEstadoPago(String estado, ColorScheme colors) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return colors.secondary;
      case 'membresia':
        return colors.primary;
      case 'pendiente':
        return colors.tertiary;
      case 'fallido':
        return colors.error;
      default:
        return colors.outline;
    }
  }

  Color _colorEstadoSeguridad(String estado, ColorScheme colors) {
    switch (estado.toLowerCase()) {
      case 'alerta':
        return colors.error;
      case 'normal':
        return colors.secondary;
      default:
        return colors.outline;
    }
  }

  IconData _iconoEstadoPago(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return Icons.check_circle;
      case 'membresia':
        return Icons.card_membership;
      case 'pendiente':
        return Icons.schedule;
      case 'fallido':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Widget _errorView(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 52,
                  color: colors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _cargarPasos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Intentar nuevamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyView(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 52,
              color: colors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin pasos de peaje',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aún no hay registros de pasos',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(String titulo) {
    return Text(
      titulo,
      style: Theme
          .of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;

    final total = _pasos.length;
    final pagados = _pasos
        .where((p) => p['estado_pago']?.toString().toLowerCase() == 'pagado')
        .length;
    final membresia = _pasos
        .where(
          (p) => p['estado_pago']?.toString().toLowerCase() == 'membresia',
    )
        .length;
    final alertas = _pasos
        .where(
          (p) =>
      p['estado_seguridad']?.toString().toLowerCase() == 'alerta',
    )
        .length;

    return Scaffold(
      appBar: MobileAppHeader(
        title: 'Historial de pasos',
        subtitle: 'Pasos registrados',
        icon: Icons.history,
        showBackButton: true,
        showRefresh: false,
        showNotifications: true,
        showLogout: false,
        extraActions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarPasos,
            icon: RotationTransition(
              turns: _refreshController,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),

      body: _cargando

          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? _errorView(context)
          : RefreshIndicator(
        onRefresh: _cargarPasos,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tituloSeccion('Resumen'),

                    const SizedBox(height: 16),

                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ResumenCard(
                          icon: Icons.receipt_long,
                          label: 'Total de pasos',
                          value: total.toString(),
                          color: colors.primary,
                        ),
                        _ResumenCard(
                          icon: Icons.check_circle,
                          label: 'Pagados',
                          value: pagados.toString(),
                          color: colors.secondary,
                        ),
                        _ResumenCard(
                          icon: Icons.card_membership,
                          label: 'Por membresía',
                          value: membresia.toString(),
                          color: colors.primary,
                        ),
                        _ResumenCard(
                          icon: Icons.warning_rounded,
                          label: 'Alertas',
                          value: alertas.toString(),
                          color: colors.error,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _tituloSeccion('Últimos pasos'),

                    const SizedBox(height: 16),

                    if (_pasos.isEmpty)
                      _emptyView(context)
                    else
                      Column(
                        children: _pasos
                            .asMap()
                            .entries
                            .map((entry) {
                          final paso = entry.value;
                          final index = entry.key;
                          final isLast = index == _pasos.length - 1;

                          return Column(
                            children: [
                              _PasoCard(
                                paso: paso,
                                dinero: _dinero,
                                texto: _texto,
                                fecha: _fecha,
                                obtenerPeaje: _obtenerPeaje,
                                obtenerCamara: _obtenerCamara,
                                colorEstadoPago: _colorEstadoPago,
                                colorEstadoSeguridad:
                                _colorEstadoSeguridad,
                                iconoEstadoPago: _iconoEstadoPago,
                                onVerComprobante: _abrirComprobante,

                              ),
                              if (!isLast)
                                const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
      ,
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResumenCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasoCard extends StatelessWidget {
  final dynamic paso;
  final String Function(dynamic) dinero;
  final String Function(dynamic) texto;
  final String Function(dynamic) fecha;
  final String Function(dynamic) obtenerPeaje;
  final String Function(dynamic) obtenerCamara;
  final Color Function(String, ColorScheme) colorEstadoPago;
  final Color Function(String, ColorScheme) colorEstadoSeguridad;
  final IconData Function(String) iconoEstadoPago;
  final void Function(dynamic paso) onVerComprobante;

  const _PasoCard({
    required this.paso,
    required this.dinero,
    required this.texto,
    required this.fecha,
    required this.obtenerPeaje,
    required this.obtenerCamara,
    required this.colorEstadoPago,
    required this.colorEstadoSeguridad,
    required this.iconoEstadoPago,
    required this.onVerComprobante,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    final placa = texto(paso['placa_detectada']);
    final peaje = obtenerPeaje(paso);
    final camara = obtenerCamara(paso);
    final fechaStr = fecha(paso['fecha_hora']);
    final tarifa = dinero(paso['tarifa_aplicada']);
    final estadoPago = texto(paso['estado_pago']);
    final estadoSeguridad = texto(paso['estado_seguridad']);
    final observacion = texto(paso['observacion']);

    final pagoColor = colorEstadoPago(estadoPago, colors);
    final seguridadColor = colorEstadoSeguridad(estadoSeguridad, colors);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: colors.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placa,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Placa detectada',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tarifa,
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tarifa',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Peaje',
                    value: peaje,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.videocam,
                    label: 'Cámara',
                    value: camara,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Fecha',
                    value: fechaStr,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _EstadoChip(
                    icon: iconoEstadoPago(estadoPago),
                    label: 'Pago',
                    value: estadoPago,
                    color: pagoColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _EstadoChip(
                    icon: Icons.shield,
                    label: 'Seguridad',
                    value: estadoSeguridad,
                    color: seguridadColor,
                  ),
                ),
              ],
            ),

            if (observacion != 'Sin dato') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colors.onTertiaryContainer,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        observacion,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onTertiaryContainer,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onVerComprobante(paso),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Ver comprobante'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _EstadoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withAlpha(55),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.toUpperCase(),
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}