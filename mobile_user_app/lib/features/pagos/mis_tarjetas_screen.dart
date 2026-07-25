import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/tarjeta_bancaria_service.dart';
import '../../shared/widgets/mobile_app_header.dart';

class MisTarjetasScreen extends StatefulWidget {
  const MisTarjetasScreen({super.key});

  @override
  State<MisTarjetasScreen> createState() => _MisTarjetasScreenState();
}

class _MisTarjetasScreenState extends State<MisTarjetasScreen> {
  final TarjetaBancariaService _tarjetaService = TarjetaBancariaService();

  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _titularController = TextEditingController();
  final _mesController = TextEditingController();
  final _anioController = TextEditingController();
  final _aliasController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  bool _principal = false;
  String _error = '';
  List<dynamic> _tarjetas = [];

  @override
  void initState() {
    super.initState();
    _cargarTarjetas();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _titularController.dispose();
    _mesController.dispose();
    _anioController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _cargarTarjetas() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
      });

      final data = await _tarjetaService.obtenerTarjetas();

      if (!mounted) return;

      setState(() {
        _tarjetas = data;
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

  void _limpiarFormulario() {
    _numeroController.clear();
    _titularController.clear();
    _mesController.clear();
    _anioController.clear();
    _aliasController.clear();
    _principal = false;
  }

  Future<void> _agregarTarjeta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _guardando = true;
        _error = '';
      });

      await _tarjetaService.agregarTarjeta(
        numeroTarjeta: _numeroController.text.trim(),
        titular: _titularController.text.trim(),
        mesExpiracion: int.parse(_mesController.text.trim()),
        anioExpiracion: int.parse(_anioController.text.trim()),
        alias: _aliasController.text.trim(),
        principal: _principal,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarjeta agregada correctamente.'),
        ),
      );

      _limpiarFormulario();
      await _cargarTarjetas();
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

  Future<void> _eliminarTarjeta(dynamic tarjeta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar tarjeta'),
          content: Text(
            '¿Deseas eliminar la tarjeta ${tarjeta['numero_enmascarado'] ?? ''}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _tarjetaService.eliminarTarjeta(
        int.parse(tarjeta['id'].toString()),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarjeta eliminada correctamente.'),
        ),
      );

      await _cargarTarjetas();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _establecerPrincipal(dynamic tarjeta) async {
    try {
      await _tarjetaService.establecerPrincipal(
        int.parse(tarjeta['id'].toString()),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarjeta establecida como principal.'),
        ),
      );

      await _cargarTarjetas();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _mostrarFormularioTarjeta() {
    _limpiarFormulario();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  top: 8,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Agregar tarjeta bancaria',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Esta tarjeta se usará para recargar tu billetera. No se guarda el CVV ni el número completo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _numeroController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Número de tarjeta',
                          prefixIcon: Icon(Icons.credit_card),
                          hintText: '4111111111111111',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el número de tarjeta';
                          }

                          if (value.trim().length < 13) {
                            return 'Ingrese un número de tarjeta válido';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _titularController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Titular',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'JUAN PEREZ',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 4) {
                            return 'Ingrese el nombre del titular';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mesController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Mes',
                                hintText: '12',
                              ),
                              validator: (value) {
                                final mes = int.tryParse(value ?? '');

                                if (mes == null || mes < 1 || mes > 12) {
                                  return 'Mes inválido';
                                }

                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _anioController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Año',
                                hintText: '2028',
                              ),
                              validator: (value) {
                                final anio = int.tryParse(value ?? '');

                                if (anio == null || anio < DateTime.now().year) {
                                  return 'Año inválido';
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _aliasController,
                        decoration: const InputDecoration(
                          labelText: 'Alias opcional',
                          prefixIcon: Icon(Icons.label_outline),
                          hintText: 'Visa principal',
                        ),
                      ),

                      const SizedBox(height: 12),

                      CheckboxListTile(
                        value: _principal,
                        onChanged: (value) {
                          setModalState(() {
                            _principal = value ?? false;
                          });
                        },
                        title: const Text('Establecer como tarjeta principal'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      FilledButton.icon(
                        onPressed: _guardando ? null : _agregarTarjeta,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar tarjeta',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tarjetaCard(dynamic tarjeta) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final principal = tarjeta['principal'] == true;
    final vencida = tarjeta['vencida'] == true;
    final activa = tarjeta['estado'] == 'activa';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.credit_card,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tarjeta['alias']?.toString().trim().isNotEmpty == true
                        ? tarjeta['alias'].toString()
                        : tarjeta['marca_display']?.toString() ?? 'Tarjeta',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (principal)
                  Chip(
                    label: const Text('Principal'),
                    backgroundColor: colors.secondaryContainer,
                    labelStyle: TextStyle(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              tarjeta['numero_enmascarado']?.toString() ?? '**** **** **** ****',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Titular: ${tarjeta['titular'] ?? 'Sin dato'}',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),

            Text(
              'Vence: ${tarjeta['mes_expiracion']}/${tarjeta['anio_expiracion']}',
              style: textTheme.bodyMedium?.copyWith(
                color: vencida ? colors.error : colors.onSurfaceVariant,
                fontWeight: vencida ? FontWeight.bold : FontWeight.normal,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Chip(
                  label: Text(
                    activa ? 'Activa' : 'Inactiva',
                  ),
                  backgroundColor:
                      activa ? colors.primaryContainer : colors.errorContainer,
                  labelStyle: TextStyle(
                    color: activa
                        ? colors.onPrimaryContainer
                        : colors.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!principal && activa)
                  TextButton(
                    onPressed: () => _establecerPrincipal(tarjeta),
                    child: const Text('Hacer principal'),
                  ),
                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: () => _eliminarTarjeta(tarjeta),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
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

    if (_error.isNotEmpty && _tarjetas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (_tarjetas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 58,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes tarjetas registradas',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agrega una tarjeta para poder recargar tu billetera.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _mostrarFormularioTarjeta,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar tarjeta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarTarjetas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tarjetas.length,
        itemBuilder: (context, index) {
          return _tarjetaCard(_tarjetas[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppHeader(
        title: 'Mis tarjetas',
        subtitle: 'Métodos de recarga',
        icon: Icons.credit_card,
        showBackButton: true,
        showNotifications: true,
        showRefresh: true,
        onRefresh: _cargarTarjetas,
        showLogout: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioTarjeta,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _contenido(),
    );
  }
}