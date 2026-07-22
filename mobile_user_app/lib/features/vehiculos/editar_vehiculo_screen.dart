import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    if (valor == null || valor
        .toString()
        .trim()
        .isEmpty) {
      return 'Sin dato';
    }

    return valor.toString();
  }

  String _capitalizar(String valor) {
    final texto = valor.trim().replaceAll('_', ' ');

    if (texto.isEmpty) {
      return '';
    }

    return texto
        .split(RegExp(r'\s+'))
        .map((palabra) {
      if (palabra.isEmpty) return palabra;

      return palabra[0].toUpperCase() +
          palabra.substring(1).toLowerCase();
    })
        .join(' ');
  }

  String _nombreCategoria(dynamic categoria) {
    final tipo = _capitalizar(
      categoria['tipo']?.toString() ?? '',
    );

    final ejes = categoria['numero_ejes']?.toString();

    if (tipo.isNotEmpty && ejes != null && ejes
        .trim()
        .isNotEmpty) {
      return '$tipo · $ejes ejes';
    }

    if (tipo.isNotEmpty) {
      return tipo;
    }

    return categoria['nombre']?.toString() ?? 'Categoría';
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.words,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator ??
                (value) {
              if (value == null || value
                  .trim()
                  .isEmpty) {
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

  Widget _documentoActual(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    final documentoUrl = widget.vehiculo['documento_respaldo_url'] ??
        widget.vehiculo['documento_respaldo'];

    final tieneDocumento =
        documentoUrl != null && documentoUrl
            .toString()
            .trim()
            .isNotEmpty;

    return Row(
      children: [
        Icon(
          tieneDocumento ? Icons.check_circle_outline : Icons.error_outline,
          color: tieneDocumento ? colors.secondary : colors.error,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tieneDocumento
                ? 'Documento actual: Registrado'
                : 'Documento actual: No registrado',
            style: textTheme.bodyMedium?.copyWith(
              color: tieneDocumento ? colors.secondary : colors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectorDocumento(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documento de respaldo',
            style: textTheme.titleSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _documentoActual(context),
          const SizedBox(height: 10),
          Text(
            'Puedes adjuntar un nuevo documento si deseas corregir o actualizar el respaldo.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cargando ? null : _seleccionarDocumento,
            icon: const Icon(Icons.attach_file),
            label: Text(
              _nombreDocumento == null
                  ? 'Seleccionar nuevo documento'
                  : _nombreDocumento!,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_nombreDocumento != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: colors.secondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nuevo archivo seleccionado: $_nombreDocumento',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
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

  Widget _bloqueError(BuildContext context) {
    if (_error.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme
        .of(context)
        .colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: colors.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisoRevision(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: colors.onTertiaryContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Al guardar cambios, el vehículo volverá a revisión administrativa.',
              textAlign: TextAlign.left,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placa = _texto(widget.vehiculo['placa']);

    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar vehículo'),
      ),
      body: _cargandoCategorias
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: colors.onPrimaryContainer,
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          placa,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _avisoRevision(context),

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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value == null || value
                                .trim()
                                .isEmpty) {
                              return 'Ingrese el año';
                            }

                            final anio = int.tryParse(value.trim());

                            if (anio == null) {
                              return 'Ingrese un año válido';
                            }

                            if (anio < 1980 ||
                                anio > DateTime
                                    .now()
                                    .year + 1) {
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
                                child: Text(
                                  _nombreCategoria(categoria),
                                  overflow: TextOverflow.ellipsis,
                                ),
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

                        _selectorDocumento(context),

                        _bloqueError(context),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed:
                            _cargando ? null : _guardarCambios,
                            icon: _cargando
                                ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _cargando
                                  ? 'Guardando...'
                                  : 'Guardar cambios',
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: _cargando
                              ? null
                              : () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}