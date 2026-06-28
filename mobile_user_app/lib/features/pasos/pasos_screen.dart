import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/paso_peaje_service.dart';

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

      setState(() {
        _pasos = data;
      });
    } catch (e) {
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

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  String _texto(dynamic valor) {
    if (valor == null || valor.toString().isEmpty) {
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

  Color _colorEstadoPago(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return Colors.green;
      case 'membresia':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      case 'fallido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _colorEstadoSeguridad(String estado) {
    switch (estado.toLowerCase()) {
      case 'alerta':
        return Colors.red;
      case 'normal':
        return Colors.green;
      default:
        return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color darkGray = Color(0xFF0F172A);
    const Color lightGray = Color(0xFFF8FAFC);
    const Color borderGray = Color(0xFFE2E8F0);

    final total = _pasos.length;
    final pagados = _pasos.where((p) => p['estado_pago']?.toString().toLowerCase() == 'pagado').length;
    final membresia =
        _pasos.where((p) => p['estado_pago']?.toString().toLowerCase() == 'membresia').length;
    final alertas = _pasos
        .where((p) => p['estado_seguridad']?.toString().toLowerCase() == 'alerta')
        .length;

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Historial de pasos',
          style: TextStyle(
            color: darkGray,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarPasos,
            icon: RotationTransition(
              turns: _refreshController,
              child: const Icon(Icons.refresh, color: primaryBlue),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Container(
                  color: lightGray,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: darkGray.withAlpha(180),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarPasos,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Resumen estadísticas
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Resumen',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: darkGray,
                                  letterSpacing: -0.3,
                                ),
                              ),
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
                                    color: primaryBlue,
                                  ),
                                  _ResumenCard(
                                    icon: Icons.check_circle,
                                    label: 'Pagados',
                                    value: pagados.toString(),
                                    color: Colors.green,
                                  ),
                                  _ResumenCard(
                                    icon: Icons.card_membership,
                                    label: 'Por membresía',
                                    value: membresia.toString(),
                                    color: Colors.blue,
                                  ),
                                  _ResumenCard(
                                    icon: Icons.warning_rounded,
                                    label: 'Alertas',
                                    value: alertas.toString(),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Pasos
                        Container(
                          color: lightGray,
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Últimos pasos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: darkGray,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_pasos.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: borderGray,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.history_toggle_off,
                                        size: 48,
                                        color: primaryBlue.withAlpha(150),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Sin pasos de peaje',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: darkGray,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Aún no hay registros de pasos',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: darkGray.withAlpha(150),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
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
                                              colorEstadoPago:
                                                  _colorEstadoPago,
                                              colorEstadoSeguridad:
                                                  _colorEstadoSeguridad,
                                              iconoEstadoPago:
                                                  _iconoEstadoPago,
                                            ),
                                            if (!isLast)
                                              const SizedBox(height: 12),
                                          ],
                                        );
                                      })
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// Widget: Tarjeta de resumen
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget: Tarjeta de paso
class _PasoCard extends StatelessWidget {
  final dynamic paso;
  final String Function(dynamic) dinero;
  final String Function(dynamic) texto;
  final String Function(dynamic) fecha;
  final String Function(dynamic) obtenerPeaje;
  final String Function(dynamic) obtenerCamara;
  final Color Function(String) colorEstadoPago;
  final Color Function(String) colorEstadoSeguridad;
  final IconData Function(String) iconoEstadoPago;

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
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color borderGray = Color(0xFFE2E8F0);

    final placa = texto(paso['placa_detectada']);
    final peaje = obtenerPeaje(paso);
    final camara = obtenerCamara(paso);
    final fechaStr = fecha(paso['fecha_hora']);
    final tarifa = dinero(paso['tarifa_aplicada']);
    final estadoPago = texto(paso['estado_pago']);
    final estadoSeguridad = texto(paso['estado_seguridad']);
    final observacion = texto(paso['observacion']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGray, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Placa y precio
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryBlue.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: primaryBlue,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Placa detectada',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A).withAlpha(150),
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tarifa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A).withAlpha(150),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Información detallada
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
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

          // Estados
          Row(
            children: [
              Expanded(
                child: _EstadoChip(
                  icon: iconoEstadoPago(estadoPago),
                  label: 'Pago',
                  value: estadoPago,
                  color: colorEstadoPago(estadoPago),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EstadoChip(
                  icon: Icons.shield,
                  label: 'Seguridad',
                  value: estadoSeguridad,
                  color: colorEstadoSeguridad(estadoSeguridad),
                ),
              ),
            ],
          ),

          // Observación
          if (observacion != 'Sin dato') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      observacion,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.orange.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget: Fila de información
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
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF1D4ED8),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Widget: Chip de estado
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
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha(50),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}