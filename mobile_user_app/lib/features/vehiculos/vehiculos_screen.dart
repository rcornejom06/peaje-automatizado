import 'package:flutter/material.dart';

import '../../core/services/vehiculo_service.dart';

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

  Future<void> _cargarVehiculos() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
      });

      final data = await _vehiculoService.obtenerVehiculos();

      setState(() {
        _vehiculos = data;
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

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  String _obtenerCategoria(dynamic vehiculo) {
    if (vehiculo['categoria_nombre'] != null) {
      return vehiculo['categoria_nombre'].toString();
    }

    if (vehiculo['categoria_detalle'] is Map) {
      return vehiculo['categoria_detalle']['nombre']?.toString() ?? 'Sin categoría';
    }

    if (vehiculo['categoria'] != null) {
      return vehiculo['categoria'].toString();
    }

    return 'Sin categoría';
  }

  String _obtenerTexto(dynamic valor) {
    if (valor == null || valor.toString().isEmpty) {
      return 'Sin dato';
    }

    return valor.toString();
  }

  Future<void> _irARegistrar() async {
    final resultado = await Navigator.pushNamed(context, '/registrar-vehiculo');

    if (resultado == true) {
      await _cargarVehiculos();
    }
  }

  Widget _vehiculoCard(dynamic vehiculo) {
    final placa = _obtenerTexto(vehiculo['placa']);
    final marca = _obtenerTexto(vehiculo['marca']);
    final modelo = _obtenerTexto(vehiculo['modelo']);
    final color = _obtenerTexto(vehiculo['color']);
    final anio = _obtenerTexto(vehiculo['anio']);
    final categoria = _obtenerCategoria(vehiculo);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF2563EB),
          child: Icon(
            Icons.directions_car,
            color: Colors.white,
          ),
        ),
        title: Text(
          placa,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$marca $modelo\nColor: $color | Año: $anio\nCategoría: $categoria',
          ),
        ),
        isThreeLine: true,
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
              : _vehiculos.isEmpty
                  ? const Center(
                      child: Text('No tienes vehículos registrados.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vehiculos.length,
                      itemBuilder: (context, index) {
                        return _vehiculoCard(_vehiculos[index]);
                      },
                    ),
    );
  }
}