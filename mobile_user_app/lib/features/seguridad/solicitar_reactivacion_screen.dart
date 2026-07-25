import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/seguridad_service.dart';
import '../../core/services/vehiculo_service.dart';
import '../../shared/widgets/mobile_app_header.dart';

class SolicitarReactivacionScreen extends StatefulWidget {
  const SolicitarReactivacionScreen({super.key});

  @override
  State<SolicitarReactivacionScreen> createState() =>
      _SolicitarReactivacionScreenState();
}

class _SolicitarReactivacionScreenState
    extends State<SolicitarReactivacionScreen> {
  final _formKey = GlobalKey<FormState>();

  final VehiculoService _vehiculoService = VehiculoService();
  final SeguridadService _seguridadService = SeguridadService();

  final TextEditingController _motivoController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;

  String _error = '';
  String _mensaje = '';

  List<dynamic> _vehiculosRobados = [];
  int? _vehiculoSeleccionadoId;

  String? _documentoPath;
  String? _documentoNombre;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _cargarVehiculos() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
        _mensaje = '';
      });

      final data = await _vehiculoService.obtenerVehiculos();

      final vehiculosRobados = data.where((vehiculo) {
        final estado = vehiculo['estado']?.toString().toLowerCase().trim();
        return estado == 'aviso_robo';
      }).toList();

      if (!mounted) return;

      setState(() {
        _vehiculosRobados = vehiculosRobados;

        if (_vehiculosRobados.isNotEmpty) {
          _vehiculoSeleccionadoId = int.tryParse(
            _vehiculosRobados.first['id'].toString(),
          );
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

  Future<void> _seleccionarDocumento() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (resultado == null || resultado.files.isEmpty) {
      return;
    }

    final archivo = resultado.files.first;

    if (archivo.path == null) {
      setState(() {
        _error = 'No se pudo obtener la ruta del archivo seleccionado.';
      });
      return;
    }

    setState(() {
      _documentoPath = archivo.path;
      _documentoNombre = archivo.name;
      _error = '';
    });
  }

  Future<bool> _confirmarEnvio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar solicitud'),
          content: const Text(
            'Esta solicitud será revisada por un administrador.\n\n'
                'Si se aprueba, el vehículo volverá al estado activo y podrá generar cobros de peaje nuevamente.\n\n'
                '¿Deseas enviar la solicitud?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Enviar solicitud'),
            ),
          ],
        );
      },
    );

    return confirmar == true;
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_vehiculoSeleccionadoId == null) {
      setState(() {
        _error = 'Debes seleccionar un vehículo reportado como robado.';
        _mensaje = '';
      });
      return;
    }

    final confirmar = await _confirmarEnvio();

    if (!confirmar) {
      return;
    }

    try {
      setState(() {
        _guardando = true;
        _error = '';
        _mensaje = '';
      });

      await _seguridadService.solicitarReactivacionVehiculo(
        vehiculoId: _vehiculoSeleccionadoId!,
        motivo: _motivoController.text.trim(),
        documentoPath: _documentoPath,
      );

      if (!mounted) return;

      setState(() {
        _mensaje =
        'Solicitud enviada correctamente. Queda pendiente de aprobación administrativa.';
        _motivoController.clear();
        _documentoPath = null;
        _documentoNombre = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada correctamente.'),
        ),
      );

      await _cargarVehiculos();
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

  String _textoVehiculo(dynamic vehiculo) {
    final placa = vehiculo['placa']?.toString() ?? 'Sin placa';
    final marca = vehiculo['marca']?.toString() ?? '';
    final modelo = vehiculo['modelo']?.toString() ?? '';

    final detalle = '$marca $modelo'.trim();

    if (detalle.isEmpty) {
      return placa;
    }

    return '$placa · $detalle';
  }

  Widget _mensajeEstado({
    required String mensaje,
    required bool esError,
  }) {
    if (mensaje
        .trim()
        .isEmpty) {
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
        color: esError
            ? colors.errorContainer
            : colors.tertiaryContainer.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        mensaje,
        style: TextStyle(
          color: esError ? colors.onErrorContainer : colors.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _estadoVacio(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              Icons.directions_car_filled_outlined,
              color: colors.primary,
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes vehículos reportados como robados',
              textAlign: TextAlign.center,
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La solicitud de reactivación solo aplica para vehículos que actualmente tienen un aviso de robo activo.',
              textAlign: TextAlign.center,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(
                      context,
                      '/crear-aviso-robo',
                    ),
                icon: const Icon(Icons.report_gmailerrorred_outlined),
                label: const Text('Reportar vehículo robado'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;

    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datos de recuperación',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selecciona el vehículo recuperado e indica el motivo de la solicitud.',
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),

              DropdownButtonFormField<int>(
                value: _vehiculoSeleccionadoId,
                decoration: const InputDecoration(
                  labelText: 'Vehículo recuperado',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: _vehiculosRobados.map((vehiculo) {
                  return DropdownMenuItem<int>(
                    value: int.parse(vehiculo['id'].toString()),
                    child: Text(
                      _textoVehiculo(vehiculo),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _guardando
                    ? null
                    : (value) {
                  setState(() {
                    _vehiculoSeleccionadoId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona un vehículo.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _motivoController,
                enabled: !_guardando,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Motivo o detalle de recuperación',
                  hintText:
                  'Ejemplo: El vehículo fue recuperado y ya se encuentra nuevamente bajo mi posesión.',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value
                      .trim()
                      .isEmpty) {
                    return 'Ingresa el motivo de recuperación.';
                  }

                  if (value
                      .trim()
                      .length < 10) {
                    return 'El motivo debe tener al menos 10 caracteres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documento de respaldo',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _documentoNombre ??
                          'Puedes adjuntar PDF o imagen como respaldo opcional.',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                            _guardando ? null : _seleccionarDocumento,
                            icon: const Icon(Icons.attach_file),
                            label: Text(
                              _documentoNombre == null
                                  ? 'Seleccionar archivo'
                                  : 'Cambiar archivo',
                            ),
                          ),
                        ),
                        if (_documentoNombre != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _guardando
                                ? null
                                : () {
                              setState(() {
                                _documentoPath = null;
                                _documentoNombre = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Quitar archivo',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _mensajeEstado(
                mensaje: _error,
                esError: true,
              ),

              _mensajeEstado(
                mensaje: _mensaje,
                esError: false,
              ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _enviarSolicitud,
                  icon: _guardando
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.onPrimary,
                    ),
                  )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _guardando
                        ? 'Enviando solicitud...'
                        : 'Enviar solicitud de reactivación',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarVehiculos,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MobileAppHeader(
                title: 'Reactivar vehículo',
                subtitle: 'Solicita revisión de un vehículo recuperado',
                icon: Icons.restore,
                showBackButton: true,
                showNotifications: true,
                showRefresh: true,
                onRefresh: _cargarVehiculos,
                showLogout: false,
              ),
              const SizedBox(height: 18),

              if (_cargando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                if (_vehiculosRobados.isEmpty)
                  _estadoVacio(context)
                else
                  _formulario(context),
            ],
          ),
        ),
      ),
    );
  }
}