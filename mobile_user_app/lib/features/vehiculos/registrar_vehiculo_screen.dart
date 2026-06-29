import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/vehiculo_service.dart';

class RegistrarVehiculoScreen extends StatefulWidget {
  const RegistrarVehiculoScreen({super.key});

  @override
  State<RegistrarVehiculoScreen> createState() =>
      _RegistrarVehiculoScreenState();
}

class _RegistrarVehiculoScreenState extends State<RegistrarVehiculoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _colorController = TextEditingController();
  final _anioController = TextEditingController();

  final VehiculoService _vehiculoService = VehiculoService();

  bool _cargando = false;
  bool _cargandoCategorias = true;
  String _error = '';
  List<dynamic> _categorias = [];
  int? _categoriaSeleccionada;

  File? _documentoRespaldo;
  String? _nombreDocumento;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _colorController.dispose();
    _anioController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final data = await _vehiculoService.obtenerCategorias();

      if (!mounted) return;

      setState(() {
        _categorias = data;
        if (_categorias.isNotEmpty) {
          _categoriaSeleccionada = _categorias.first['id'];
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargandoCategorias = false;
        });
      }
    }
  }

  Future<void> _seleccionarDocumento() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (resultado == null || resultado.files.single.path == null) {
      return;
    }

    setState(() {
      _documentoRespaldo = File(resultado.files.single.path!);
      _nombreDocumento = resultado.files.single.name;
    });
  }

  Future<void> _registrarVehiculo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSeleccionada == null) {
      setState(() {
        _error = 'Debe seleccionar una categoría.';
      });
      return;
    }

    if (_documentoRespaldo == null) {
      setState(() {
        _error = 'Debe adjuntar un documento de respaldo.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      await _vehiculoService.registrarVehiculo(
        placa: _placaController.text.trim().toUpperCase(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        color: _colorController.text.trim(),
        anio: int.parse(_anioController.text.trim()),
        categoriaId: _categoriaSeleccionada!,
        documentoRespaldo: _documentoRespaldo!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehículo registrado correctamente. Queda en revisión hasta aprobación administrativa.',
          ),
        ),
      );

      Navigator.pop(context, true);
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

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.characters,
        validator: validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo es obligatorio';
              }

              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  String _nombreCategoria(dynamic categoria) {
    final nombre = categoria['nombre']?.toString() ?? 'Categoría';
    final tarifa = categoria['tarifa']?.toString();

    if (tarifa != null) {
      return '$nombre - \$$tarifa';
    }

    return nombre;
  }

  Widget _selectorDocumento() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documento de respaldo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Adjunta matrícula, cédula del propietario, autorización o documento que respalde el registro del vehículo.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _cargando ? null : _seleccionarDocumento,
            icon: const Icon(Icons.attach_file),
            label: Text(
              _nombreDocumento == null
                  ? 'Seleccionar documento'
                  : _nombreDocumento!,
            ),
          ),
          if (_nombreDocumento != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Archivo seleccionado: $_nombreDocumento',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bloqueError() {
    if (_error.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _error,
        style: TextStyle(color: Colors.red.shade700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar vehículo'),
      ),
      body: _cargandoCategorias
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.directions_car_filled,
                          size: 64,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nuevo vehículo',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        _campoTexto(
                          controller: _placaController,
                          label: 'Placa',
                          icon: Icons.confirmation_number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese la placa';
                            }

                            final placa = value.trim().toUpperCase();

                            if (placa.length < 6) {
                              return 'Ingrese una placa válida';
                            }

                            return null;
                          },
                        ),

                        _campoTexto(
                          controller: _marcaController,
                          label: 'Marca',
                          icon: Icons.car_rental,
                        ),

                        _campoTexto(
                          controller: _modeloController,
                          label: 'Modelo',
                          icon: Icons.directions_car,
                        ),

                        _campoTexto(
                          controller: _colorController,
                          label: 'Color',
                          icon: Icons.color_lens,
                        ),

                        _campoTexto(
                          controller: _anioController,
                          label: 'Año',
                          icon: Icons.calendar_month,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese el año';
                            }

                            final anio = int.tryParse(value.trim());

                            if (anio == null) {
                              return 'Ingrese un año válido';
                            }

                            if (anio < 1980 ||
                                anio > DateTime.now().year + 1) {
                              return 'Año fuera de rango';
                            }

                            return null;
                          },
                        ),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: DropdownButtonFormField<int>(
                            value: _categoriaSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _categorias.map((categoria) {
                              return DropdownMenuItem<int>(
                                value: categoria['id'],
                                child: Text(_nombreCategoria(categoria)),
                              );
                            }).toList(),
                            onChanged: _cargando
                                ? null
                                : (value) {
                                    setState(() {
                                      _categoriaSeleccionada = value;
                                    });
                                  },
                            validator: (value) {
                              if (value == null) {
                                return 'Seleccione una categoría';
                              }

                              return null;
                            },
                          ),
                        ),

                        _selectorDocumento(),

                        _bloqueError(),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _cargando ? null : _registrarVehiculo,
                            child: _cargando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Registrar vehículo'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}