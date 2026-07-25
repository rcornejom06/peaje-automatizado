import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  Uint8List? _documentoBytes;
  String? _nombreDocumento;

  String _normalizarTexto(String texto) {
    return texto.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizarPlaca(String texto) {
    return texto
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  bool _soloLetras(String texto) {
    final valor = _normalizarTexto(texto);

    final regex = RegExp(
      r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$",
    );

    return regex.hasMatch(valor);
  }

  bool _letrasYNumeros(String texto) {
    final valor = _normalizarTexto(texto);

    final regex = RegExp(
      r"^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ\s]+$",
    );

    return regex.hasMatch(valor);
  }

  bool _validarPlacaEcuatoriana(String placa) {
    final valor = _normalizarPlaca(placa);

    // Formato común Ecuador:
    // 3 letras + 3 o 4 números
    final formato = RegExp(r'^[A-Z]{3}[0-9]{3,4}$');

    if (!formato.hasMatch(valor)) {
      return false;
    }

    // Primera letra según códigos provinciales comunes de Ecuador.
    const letrasProvincia = {
      'A', // Azuay
      'B', // Bolívar
      'C', // Carchi
      'E', // Esmeraldas
      'G', // Guayas
      'H', // Chimborazo
      'I', // Imbabura
      'J', // Santo Domingo
      'K', // Sucumbíos
      'L', // Loja
      'M', // Manabí
      'N', // Napo
      'O', // El Oro
      'P', // Pichincha
      'Q', // Orellana
      'R', // Los Ríos
      'S', // Pastaza
      'T', // Tungurahua
      'U', // Cañar
      'V', // Morona Santiago
      'W', // Galápagos
      'X', // Cotopaxi
      'Y', // Santa Elena
      'Z', // Zamora Chinchipe
    };

    return letrasProvincia.contains(valor[0]);
  }

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
      withData: true,
    );

    if (resultado == null) {
      return;
    }

    final archivo = resultado.files.single;

    setState(() {
      _nombreDocumento = archivo.name;
      _documentoBytes = archivo.bytes;

      if (kIsWeb) {
        _documentoRespaldo = null;
      } else {
        if (archivo.path != null) {
          _documentoRespaldo = File(archivo.path!);
        }
      }
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

    if (_documentoRespaldo == null && _documentoBytes == null) {
      setState(() {
        _error = 'Debe adjuntar un documento de respaldo.';
      });
      return;
    }

    final placaFormateada = _normalizarPlaca(_placaController.text);
    final marcaFormateada = _normalizarTexto(_marcaController.text);
    final modeloFormateado = _normalizarTexto(_modeloController.text);
    final colorFormateado = _normalizarTexto(_colorController.text);

    _placaController.text = placaFormateada;
    _marcaController.text = marcaFormateada;
    _modeloController.text = modeloFormateado;
    _colorController.text = colorFormateado;

    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      await _vehiculoService.registrarVehiculo(
        placa: placaFormateada,
        marca: marcaFormateada,
        modelo: modeloFormateado,
        color: colorFormateado,
        anio: int.parse(_anioController.text.trim()),
        categoriaId: _categoriaSeleccionada!,
        documentoRespaldo: _documentoRespaldo,
        documentoBytes: _documentoBytes,
        nombreDocumento: _nombreDocumento,
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
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
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

          Text(
            'Adjunta matrícula, cédula del propietario, autorización o documento que respalde el registro del vehículo.',
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
                  ? 'Seleccionar documento'
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
                    'Archivo seleccionado: $_nombreDocumento',
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
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
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

  Widget _header(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.directions_car_filled,
            size: 42,
            color: colors.onPrimaryContainer,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Nuevo vehículo',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Registra los datos del vehículo y adjunta un documento de respaldo.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
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
              'El vehículo quedará en revisión hasta aprobación administrativa.',
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

  Widget _formulario(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                      _header(context),

                      const SizedBox(height: 18),

                      _avisoRevision(context),

                      const SizedBox(height: 22),

                      _campoTexto(
                        controller: _placaController,
                        label: 'Placa',
                        icon: Icons.confirmation_number,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'),
                          ),
                          LengthLimitingTextInputFormatter(7),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final texto = newValue.text.toUpperCase();

                            return TextEditingValue(
                              text: texto,
                              selection: TextSelection.collapsed(
                                  offset: texto.length),
                            );
                          }),
                        ],
                        validator: (value) {
                          if (value == null || value
                              .trim()
                              .isEmpty) {
                            return 'Ingrese la placa';
                          }

                          final placa = _normalizarPlaca(value);

                          if (!_validarPlacaEcuatoriana(placa)) {
                            return 'Ingrese una placa ecuatoriana válida. Ejemplo: ABC1234';
                          }

                          return null;
                        },
                      ),

                      _campoTexto(
                        controller: _marcaController,
                        label: 'Marca',
                        icon: Icons.car_rental,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]"),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value
                              .trim()
                              .isEmpty) {
                            return 'Ingrese la marca';
                          }

                          if (!_soloLetras(value)) {
                            return 'La marca solo debe contener letras';
                          }

                          if (value
                              .trim()
                              .length < 2) {
                            return 'La marca debe tener mínimo 2 letras';
                          }

                          return null;
                        },
                      ),

                      _campoTexto(
                        controller: _modeloController,
                        label: 'Modelo',
                        icon: Icons.directions_car,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r"[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ\s]"),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value
                              .trim()
                              .isEmpty) {
                            return 'Ingrese el modelo';
                          }

                          if (!_letrasYNumeros(value)) {
                            return 'El modelo solo debe contener letras y números';
                          }

                          if (value
                              .trim()
                              .length < 2) {
                            return 'El modelo debe tener mínimo 2 caracteres';
                          }

                          return null;
                        },
                      ),

                      _campoTexto(
                        controller: _colorController,
                        label: 'Color',
                        icon: Icons.color_lens,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]"),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value
                              .trim()
                              .isEmpty) {
                            return 'Ingrese el color';
                          }

                          if (!_soloLetras(value)) {
                            return 'El color solo debe contener letras';
                          }

                          if (value
                              .trim()
                              .length < 3) {
                            return 'Ingrese un color válido';
                          }

                          return null;
                        },
                      ),

                      _campoTexto(
                        controller: _anioController,
                        label: 'Año',
                        icon: Icons.calendar_month,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
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

                          if (!RegExp(r'^\d{4}$').hasMatch(value.trim())) {
                            return 'El año debe tener 4 dígitos';
                          }

                          final anio = int.tryParse(value.trim());

                          if (anio == null) {
                            return 'Ingrese un año válido';
                          }

                          final anioActual = DateTime
                              .now()
                              .year;

                          if (anio < 1980 || anio > anioActual + 1) {
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
                          onPressed: _cargando ? null : _registrarVehiculo,
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
                                ? 'Registrando...'
                                : 'Registrar vehículo',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar vehículo'),
      ),
      body: _cargandoCategorias
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _formulario(context),
    );
  }
}