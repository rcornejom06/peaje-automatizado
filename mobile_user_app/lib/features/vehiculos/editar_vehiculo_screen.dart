import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/vehiculo_service.dart';

class EditarVehiculoScreen extends StatefulWidget {
  final Map<String, dynamic> vehiculo;

  const EditarVehiculoScreen({
    super.key,
    required this.vehiculo,
  });

  @override
  State<EditarVehiculoScreen> createState() => _EditarVehiculoScreenState();
}

class _EditarVehiculoScreenState extends State<EditarVehiculoScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehiculoService _vehiculoService = VehiculoService();

  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _colorController = TextEditingController();
  final _anioController = TextEditingController();

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
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _colorController.dispose();
    _anioController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    _marcaController.text = widget.vehiculo['marca']?.toString() ?? '';
    _modeloController.text = widget.vehiculo['modelo']?.toString() ?? '';
    _colorController.text = widget.vehiculo['color']?.toString() ?? '';
    _anioController.text = widget.vehiculo['anio']?.toString() ?? '';

    final categoria = widget.vehiculo['categoria'];

    if (categoria is int) {
      _categoriaSeleccionada = categoria;
    } else if (categoria != null) {
      _categoriaSeleccionada = int.tryParse(categoria.toString());
    }

    try {
      final data = await _vehiculoService.obtenerCategorias();

      if (!mounted) return;

      setState(() {
        _categorias = data;

        if (_categoriaSeleccionada == null && _categorias.isNotEmpty) {
          _categoriaSeleccionada = _categorias.first['id'];
        }

        _cargandoCategorias = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargandoCategorias = false;
      });
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

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSeleccionada == null) {
      setState(() {
        _error = 'Debe seleccionar una categoría.';
      });
      return;
    }

    final vehiculoId = widget.vehiculo['id'];

    if (vehiculoId == null) {
      setState(() {
        _error = 'No se encontró el ID del vehículo.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      await _vehiculoService.actualizarVehiculo(
        vehiculoId: int.parse(vehiculoId.toString()),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        color: _colorController.text.trim(),
        anio: int.parse(_anioController.text.trim()),
        categoriaId: _categoriaSeleccionada!,
        documentoRespaldo: _documentoRespaldo,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehículo actualizado correctamente. Queda nuevamente en revisión.',
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

  String _texto(dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return 'Sin dato';
    }

    return valor.toString();
  }

  String _nombreCategoria(dynamic categoria) {
    final nombre = categoria['nombre']?.toString() ?? 'Categoría';
    final tarifa = categoria['tarifa']?.toString();

    if (tarifa != null) {
      return '$nombre - \$$tarifa';
    }

    return nombre;
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
        textCapitalization: TextCapitalization.words,
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

  Widget _documentoActual() {
    final documentoUrl = widget.vehiculo['documento_respaldo_url'] ??
        widget.vehiculo['documento_respaldo'];

    if (documentoUrl == null || documentoUrl.toString().trim().isEmpty) {
      return const Text(
        'Documento actual: No registrado',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return const Text(
      'Documento actual: Registrado',
      style: TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.w600,
      ),
    );
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
          _documentoActual(),
          const SizedBox(height: 8),
          const Text(
            'Puedes adjuntar un nuevo documento si deseas corregir o actualizar el respaldo.',
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
                  ? 'Seleccionar nuevo documento'
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
                    'Nuevo archivo seleccionado: $_nombreDocumento',
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        _error,
        style: TextStyle(
          color: Colors.red.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placa = _texto(widget.vehiculo['placa']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar vehículo'),
      ),
      body: _cargandoCategorias
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0xFF2563EB),
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          placa,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Al guardar cambios, el vehículo volverá a revisión administrativa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),

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
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _cargando ? null : _guardarCambios,
                            icon: _cargando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _cargando
                                  ? 'Guardando...'
                                  : 'Guardar cambios',
                            ),
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