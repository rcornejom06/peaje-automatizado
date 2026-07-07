import 'package:flutter/material.dart';

import '../../core/services/seguridad_service.dart';
import '../../core/services/vehiculo_service.dart';

class CrearAvisoRoboScreen extends StatefulWidget {
  const CrearAvisoRoboScreen({super.key});

  @override
  State<CrearAvisoRoboScreen> createState() => _CrearAvisoRoboScreenState();
}

class _CrearAvisoRoboScreenState extends State<CrearAvisoRoboScreen> {
  final _formKey = GlobalKey<FormState>();

  final VehiculoService _vehiculoService = VehiculoService();
  final SeguridadService _seguridadService = SeguridadService();

  final _numeroDenunciaController = TextEditingController();
  final _entidadDenunciaController = TextEditingController();
  final _fechaDenunciaController = TextEditingController();
  final _lugarRoboController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  String _error = '';

  List<dynamic> _vehiculos = [];
  int? _vehiculoSeleccionado;

  Future<void> _cargarVehiculos() async {
    try {
      final data = await _vehiculoService.obtenerVehiculos();

      if (!mounted) return;

      setState(() {
        _vehiculos = data;

        if (_vehiculos.isNotEmpty) {
          _vehiculoSeleccionado = _vehiculos.first['id'];
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
          _cargando = false;
        });
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      _fechaDenunciaController.text =
          '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_vehiculoSeleccionado == null) {
      setState(() {
        _error = 'Debe seleccionar un vehículo.';
      });
      return;
    }

    try {
      setState(() {
        _guardando = true;
        _error = '';
      });

      await _seguridadService.crearAvisoRobo(
        vehiculoId: _vehiculoSeleccionado!,
        numeroDenuncia: _numeroDenunciaController.text.trim(),
        entidadDenuncia: _entidadDenunciaController.text.trim(),
        fechaDenuncia: _fechaDenunciaController.text.trim(),
        lugarRobo: _lugarRoboController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        latitudRobo: _latitudController.text.trim(),
        longitudRobo: _longitudController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aviso de robo creado correctamente.'),
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
          _guardando = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  @override
  void dispose() {
    _numeroDenunciaController.dispose();
    _entidadDenunciaController.dispose();
    _fechaDenunciaController.dispose();
    _lugarRoboController.dispose();
    _descripcionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  String _vehiculoNombre(dynamic vehiculo) {
    final placa = vehiculo['placa']?.toString() ?? 'Sin placa';
    final marca = vehiculo['marca']?.toString() ?? '';
    final modelo = vehiculo['modelo']?.toString() ?? '';

    return '$placa - $marca $modelo';
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool soloLectura = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: soloLectura,
        onTap: onTap,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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

  Widget _bloqueError(BuildContext context) {
    if (_error.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sinVehiculosView(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  Icons.directions_car_outlined,
                  size: 56,
                  color: colors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin vehículos registrados',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Primero debe registrar un vehículo para crear un aviso de robo.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: colors.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 42,
            color: colors.onErrorContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Aviso de vehículo robado',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa la información de la denuncia para generar el aviso.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear aviso de robo'),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _vehiculos.isEmpty
              ? _sinVehiculosView(context)
              : SafeArea(
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

                                  const SizedBox(height: 26),

                                  DropdownButtonFormField<int>(
                                    value: _vehiculoSeleccionado,
                                    decoration: const InputDecoration(
                                      labelText: 'Vehículo',
                                      prefixIcon: Icon(Icons.directions_car),
                                    ),
                                    items: _vehiculos.map((vehiculo) {
                                      return DropdownMenuItem<int>(
                                        value: vehiculo['id'],
                                        child: Text(
                                          _vehiculoNombre(vehiculo),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _guardando
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _vehiculoSeleccionado = value;
                                            });
                                          },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Seleccione un vehículo';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  _campoTexto(
                                    controller: _numeroDenunciaController,
                                    label: 'Número de denuncia',
                                    icon: Icons.confirmation_number,
                                  ),

                                  _campoTexto(
                                    controller: _entidadDenunciaController,
                                    label: 'Entidad de denuncia',
                                    icon: Icons.account_balance,
                                  ),

                                  _campoTexto(
                                    controller: _fechaDenunciaController,
                                    label: 'Fecha de denuncia',
                                    icon: Icons.calendar_month,
                                    soloLectura: true,
                                    onTap: _seleccionarFecha,
                                  ),

                                  _campoTexto(
                                    controller: _lugarRoboController,
                                    label: 'Lugar del robo',
                                    icon: Icons.location_on,
                                  ),

                                  _campoTexto(
                                    controller: _descripcionController,
                                    label: 'Descripción',
                                    icon: Icons.description,
                                    maxLines: 3,
                                  ),

                                  _campoTexto(
                                    controller: _latitudController,
                                    label: 'Latitud del robo (opcional)',
                                    icon: Icons.map,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                    validator: (_) => null,
                                  ),

                                  _campoTexto(
                                    controller: _longitudController,
                                    label: 'Longitud del robo (opcional)',
                                    icon: Icons.map_outlined,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                    textInputAction: TextInputAction.done,
                                    validator: (_) => null,
                                  ),

                                  _bloqueError(context),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: _guardando ? null : _guardar,
                                      icon: _guardando
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colors.onPrimary,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.warning_amber_rounded,
                                            ),
                                      label: Text(
                                        _guardando
                                            ? 'Guardando...'
                                            : 'Crear aviso',
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  TextButton(
                                    onPressed: _guardando
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