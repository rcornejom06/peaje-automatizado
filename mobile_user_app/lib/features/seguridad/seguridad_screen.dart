import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/seguridad_service.dart';

class SeguridadScreen extends StatefulWidget {
  const SeguridadScreen({super.key});

  @override
  State<SeguridadScreen> createState() => _SeguridadScreenState();
}

class _SeguridadScreenState extends State<SeguridadScreen> {
  final SeguridadService _seguridadService = SeguridadService();

  bool _cargando = true;
  String _error = '';

  List<dynamic> _avisos = [];
  List<dynamic> _alertas = [];

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
      });

      final resultados = await Future.wait([
        _seguridadService.obtenerAvisosRobo(),
        _seguridadService.obtenerAlertas(),
      ]);

      setState(() {
        _avisos = resultados[0];
        _alertas = resultados[1];
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
      }
    }
  }

  Future<void> _irCrearAviso() async {
    final resultado = await Navigator.pushNamed(context, '/crear-aviso-robo');

    if (resultado == true) {
      await _cargarDatos();
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  String _texto(dynamic valor) {
    if (valor == null || valor.toString().isEmpty) {
      return 'Sin dato';
    }

    return valor.toString();
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

  String _obtenerPlaca(dynamic item) {
    if (item['vehiculo_placa'] != null) {
      return item['vehiculo_placa'].toString();
    }

    if (item['placa'] != null) {
      return item['placa'].toString();
    }

    if (item['vehiculo_detalle'] is Map) {
      return item['vehiculo_detalle']['placa']?.toString() ?? 'Sin placa';
    }

    if (item['vehiculo'] is Map) {
      return item['vehiculo']['placa']?.toString() ?? 'Sin placa';
    }

    return _texto(item['vehiculo']);
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'activo':
      case 'pendiente':
        return Colors.orange;
      case 'detectado':
      case 'derivada':
        return Colors.red;
      case 'cerrado':
      case 'cerrada':
        return Colors.green;
      case 'cancelado':
      case 'descartada':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _resumen() {
    return Card(
      color: const Color(0xFF2563EB),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _resumenItem('Avisos', _avisos.length.toString()),
            _resumenItem('Alertas', _alertas.length.toString()),
            _resumenItem(
              'Activos',
              _avisos.where((a) => a['estado'] == 'activo').length.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenItem(String titulo, String valor) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _avisoCard(dynamic aviso) {
    final estado = _texto(aviso['estado']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _colorEstado(estado),
          child: const Icon(Icons.directions_car, color: Colors.white),
        ),
        title: Text(
          _obtenerPlaca(aviso),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Denuncia: ${_texto(aviso['numero_denuncia'])}\n'
          'Entidad: ${_texto(aviso['entidad_denuncia'])}\n'
          'Lugar: ${_texto(aviso['lugar_robo'])}\n'
          'Estado: $estado',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _alertaCard(dynamic alerta) {
    final estado = _texto(alerta['estado']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _colorEstado(estado),
                  child: const Icon(Icons.warning, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _obtenerPlaca(alerta),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    estado,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _colorEstado(estado),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Tipo: ${_texto(alerta['tipo_alerta'])}'),
            Text('Peaje: ${_texto(alerta['peaje_nombre'] ?? alerta['peaje'])}'),
            Text('Fecha: ${_fecha(alerta['fecha_hora'])}'),
            const SizedBox(height: 8),
            Text(
              _texto(alerta['descripcion']),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionAvisos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis avisos de robo',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_avisos.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No tienes avisos de robo registrados.'),
            ),
          )
        else
          ..._avisos.map(_avisoCard),
      ],
    );
  }

  Widget _seccionAlertas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas relacionadas',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_alertas.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No tienes alertas registradas.'),
            ),
          )
        else
          ..._alertas.map(_alertaCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguridad'),
        actions: [
          IconButton(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irCrearAviso,
        icon: const Icon(Icons.add),
        label: const Text('Aviso'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _resumen(),
                      const SizedBox(height: 18),
                      _seccionAvisos(),
                      const SizedBox(height: 18),
                      _seccionAlertas(),
                      const SizedBox(height: 70),
                    ],
                  ),
                ),
    );
  }
}