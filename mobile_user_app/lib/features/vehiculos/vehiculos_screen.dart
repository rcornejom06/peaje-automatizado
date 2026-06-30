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

  Color _colorEstadoRevision(dynamic estado) {
    switch (estado) {
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      case 'en_revision':
        return Colors.orange;
      default:
        return Colors.orange;
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
    final estado = vehiculo['estado_revision'];
    final color = _colorEstadoRevision(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
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
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehiculoCard(dynamic vehiculo) {
    final placa = _obtenerTexto(vehiculo['placa']);
    final marca = _obtenerTexto(vehiculo['marca']);
    final modelo = _obtenerTexto(vehiculo['modelo']);
    final color = _obtenerTexto(vehiculo['color']);
    final anio = _obtenerTexto(vehiculo['anio']);
    final categoria = _obtenerCategoria(vehiculo);
    final estadoRevision = vehiculo['estado_revision'];
    final motivoRevision = vehiculo['motivo_revision'];
    final documentoUrl = _obtenerDocumentoUrl(vehiculo);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF2563EB),
              child: Icon(
                Icons.directions_car,
                color: Colors.white,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      _estadoRevisionChip(vehiculo),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$marca $modelo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text('Color: $color'),
                  Text('Año: $anio'),
                  Text('Categoría: $categoria'),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        documentoUrl == null
                            ? Icons.description_outlined
                            : Icons.attach_file,
                        size: 18,
                        color: documentoUrl == null ? Colors.grey : Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          documentoUrl == null
                              ? 'Sin documento de respaldo'
                              : 'Documento de respaldo adjuntado',
                          style: TextStyle(
                            color:
                                documentoUrl == null ? Colors.grey : Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (estadoRevision == 'en_revision') ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tu vehículo está pendiente de validación administrativa.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  if (estadoRevision == 'aprobado') ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Vehículo aprobado para uso en peajes.',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  if (estadoRevision == 'rechazado') ...[
                    const SizedBox(height: 8),
                    Text(
                      motivoRevision != null &&
                              motivoRevision.toString().trim().isNotEmpty
                          ? 'Motivo: $motivoRevision'
                          : 'Vehículo rechazado. Contacta con administración.',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _irAEditarVehiculo(vehiculo),
                      icon: const Icon(Icons.edit),
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

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_vehiculos.isEmpty) {
      return const Center(
        child: Text('No tienes vehículos registrados.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarVehiculos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehiculos.length,
        itemBuilder: (context, index) {
          return _vehiculoCard(_vehiculos[index]);
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