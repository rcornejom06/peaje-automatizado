import 'package:flutter/material.dart';

import '../../core/services/vehiculo_service.dart';
import 'editar_vehiculo_screen.dart';

class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  final VehiculoService _vehiculoService = VehiculoService();

  bool _cargando = true;
  String _error = '';
  List<dynamic> _vehiculos = [];

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
      });

      final data = await _vehiculoService.obtenerVehiculos();

      if (!mounted) return;

      setState(() {
        _vehiculos = data;
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

  Future<void> _irAEditarVehiculo(dynamic vehiculo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarVehiculoScreen(
          vehiculo: Map<String, dynamic>.from(vehiculo),
        ),
      ),
    );

    if (resultado == true) {
      await _cargarVehiculos();
    }
  }

  Future<void> _irARegistrar() async {
    final resultado = await Navigator.pushNamed(context, '/registrar-vehiculo');

    if (resultado == true) {
      await _cargarVehiculos();
    }
  }

  String _obtenerCategoria(dynamic vehiculo) {
    if (vehiculo['categoria_nombre'] != null) {
      return vehiculo['categoria_nombre'].toString();
    }

    if (vehiculo['categoria_detalle'] is Map) {
      return vehiculo['categoria_detalle']['nombre']?.toString() ??
          'Sin categoría';
    }

    if (vehiculo['categoria'] != null) {
      return vehiculo['categoria'].toString();
    }

    return 'Sin categoría';
  }

  String _obtenerTexto(dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return 'Sin dato';
    }

    return valor.toString();
  }

  String _textoEstadoRevision(dynamic estado) {
    switch (estado) {
      case 'aprobado':
        return 'Aprobado';
      case 'rechazado':
        return 'Rechazado';
      case 'en_revision':
        return 'En revisión';
      default:
        return 'En revisión';
    }
  }

  Color _colorEstadoRevision(dynamic estado, ColorScheme colors) {
    switch (estado) {
      case 'aprobado':
        return colors.secondary;
      case 'rechazado':
        return colors.error;
      case 'en_revision':
        return colors.tertiary;
      default:
        return colors.tertiary;
    }
  }

  IconData _iconoEstadoRevision(dynamic estado) {
    switch (estado) {
      case 'aprobado':
        return Icons.check_circle;
      case 'rechazado':
        return Icons.cancel;
      case 'en_revision':
        return Icons.hourglass_top;
      default:
        return Icons.hourglass_top;
    }
  }

  String? _obtenerDocumentoUrl(dynamic vehiculo) {
    final url = vehiculo['documento_respaldo_url'];

    if (url != null && url.toString().trim().isNotEmpty) {
      return url.toString();
    }

    final documento = vehiculo['documento_respaldo'];

    if (documento != null && documento.toString().trim().isNotEmpty) {
      return documento.toString();
    }

    return null;
  }

  Widget _estadoRevisionChip(dynamic vehiculo) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final estado = vehiculo['estado_revision'];
    final color = _colorEstadoRevision(estado, colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withAlpha(55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconoEstadoRevision(estado),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            _textoEstadoRevision(estado),
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentoEstado(String? documentoUrl) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tieneDocumento = documentoUrl != null;
    final color = tieneDocumento ? colors.primary : colors.outline;

    return Row(
      children: [
        Icon(
          tieneDocumento ? Icons.attach_file : Icons.description_outlined,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            tieneDocumento
                ? 'Documento de respaldo adjuntado'
                : 'Sin documento de respaldo',
            style: textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mensajeRevision({
    required dynamic estadoRevision,
    required dynamic motivoRevision,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String mensaje;

    if (estadoRevision == 'aprobado') {
      backgroundColor = colors.secondaryContainer;
      foregroundColor = colors.onSecondaryContainer;
      icon = Icons.check_circle_outline;
      mensaje = 'Vehículo aprobado para uso en peajes.';
    } else if (estadoRevision == 'rechazado') {
      backgroundColor = colors.errorContainer;
      foregroundColor = colors.onErrorContainer;
      icon = Icons.cancel_outlined;
      mensaje = motivoRevision != null &&
              motivoRevision.toString().trim().isNotEmpty
          ? 'Motivo: $motivoRevision'
          : 'Vehículo rechazado. Contacta con administración.';
    } else {
      backgroundColor = colors.tertiaryContainer;
      foregroundColor = colors.onTertiaryContainer;
      icon = Icons.hourglass_top;
      mensaje = 'Tu vehículo está pendiente de validación administrativa.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: foregroundColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehiculoCard(dynamic vehiculo) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final placa = _obtenerTexto(vehiculo['placa']);
    final marca = _obtenerTexto(vehiculo['marca']);
    final modelo = _obtenerTexto(vehiculo['modelo']);
    final colorVehiculo = _obtenerTexto(vehiculo['color']);
    final anio = _obtenerTexto(vehiculo['anio']);
    final categoria = _obtenerCategoria(vehiculo);
    final estadoRevision = vehiculo['estado_revision'];
    final motivoRevision = vehiculo['motivo_revision'];
    final documentoUrl = _obtenerDocumentoUrl(vehiculo);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car,
                color: colors.onPrimaryContainer,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          placa,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      _estadoRevisionChip(vehiculo),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$marca $modelo',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Color: $colorVehiculo',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Año: $anio',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Categoría: $categoria',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _documentoEstado(documentoUrl),

                  const SizedBox(height: 12),

                  _mensajeRevision(
                    estadoRevision: estadoRevision,
                    motivoRevision: motivoRevision,
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _irAEditarVehiculo(vehiculo),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar vehículo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colors.error,
                  size: 52,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudieron cargar los vehículos',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _cargarVehiculos,
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

  Widget _emptyView() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  color: colors.primary,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes vehículos registrados',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Registra tu primer vehículo para usarlo en el sistema de peaje.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _irARegistrar,
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar vehículo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return _errorView();
    }

    if (_vehiculos.isEmpty) {
      return _emptyView();
    }

    return RefreshIndicator(
      onRefresh: _cargarVehiculos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehiculos.length,
        itemBuilder: (context, index) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: _vehiculoCard(_vehiculos[index]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis vehículos'),
        actions: [
          IconButton(
            onPressed: _cargarVehiculos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irARegistrar,
        child: const Icon(Icons.add),
      ),
      body: _contenido(),
    );
  }
}