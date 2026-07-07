import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/billetera_service.dart';

class BilleteraScreen extends StatefulWidget {
  const BilleteraScreen({super.key});

  @override
  State<BilleteraScreen> createState() => _BilleteraScreenState();
}

class _BilleteraScreenState extends State<BilleteraScreen>
    with SingleTickerProviderStateMixin {
  final BilleteraService _billeteraService = BilleteraService();
  final TextEditingController _montoController = TextEditingController();

  late AnimationController _refreshController;

  bool _cargando = true;
  bool _recargando = false;
  String _error = '';
  String _mensaje = '';
  Map<String, dynamic>? _billetera;

  @override
  void initState() {
    super.initState();

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _cargarBilletera();
  }

  Future<void> _cargarBilletera() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
        _mensaje = '';
      });

      _refreshController.forward();

      final data = await _billeteraService.obtenerMiBilletera();

      if (!mounted) return;

      setState(() {
        _billetera = data;
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

        _refreshController.reset();
      }
    }
  }

  Future<void> _recargar() async {
    final montoTexto = _montoController.text.trim().replaceAll(',', '.');
    final monto = double.tryParse(montoTexto);

    if (monto == null || monto <= 0) {
      setState(() {
        _error = 'Ingresa un monto válido y mayor a cero.';
        _mensaje = '';
      });
      return;
    }

    setState(() {
      _recargando = true;
      _error = '';
      _mensaje = '';
    });

    try {
      await _billeteraService.recargar(
        monto: monto,
        metodoPago: 'app_movil',
        referenciaPago: 'RECARGA-MOVIL-${DateTime.now().millisecondsSinceEpoch}',
      );

      _montoController.clear();

      if (!mounted) return;

      setState(() {
        _mensaje = 'Recarga exitosa. Tu saldo ha sido actualizado.';
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      await _cargarBilletera();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _recargando = false;
        });
      }
    }
  }

  String _saldoTexto() {
    final saldo = _billetera?['saldo'];

    if (saldo == null) {
      return '\$0.00';
    }

    final numero = double.tryParse(saldo.toString()) ?? 0;
    return '\$${numero.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _montoController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Widget _mensajeEstado({
    required BuildContext context,
    required String mensaje,
    required bool esError,
  }) {
    if (mensaje.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    final backgroundColor =
        esError ? colors.errorContainer : colors.secondaryContainer;
    final foregroundColor =
        esError ? colors.onErrorContainer : colors.onSecondaryContainer;
    final icon = esError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: foregroundColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saldoCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.onPrimary.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: colors.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Saldo disponible',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _saldoTexto(),
            style: textTheme.displaySmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notaInformativa(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: colors.onPrimaryContainer,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Las recargas se procesarán en tiempo real. Tu saldo se actualizará inmediatamente.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Billetera'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarBilletera,
            icon: RotationTransition(
              turns: _refreshController,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _saldoCard(context),

                        const SizedBox(height: 24),

                        _seccionTitulo('Información'),

                        const SizedBox(height: 12),

                        _InfoCard(
                          icon: Icons.verified_user,
                          title: 'Estado',
                          value: _billetera?['estado'] ?? 'Sin dato',
                          color: colors.secondary,
                        ),

                        const SizedBox(height: 10),

                        _InfoCard(
                          icon: Icons.numbers,
                          title: 'ID de billetera',
                          value: _billetera?['id']?.toString() ?? 'Sin dato',
                          color: colors.primary,
                        ),

                        const SizedBox(height: 24),

                        _seccionTitulo('Recargar saldo'),

                        const SizedBox(height: 12),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _CustomRechargeField(
                                  controller: _montoController,
                                  enabled: !_recargando,
                                ),

                                const SizedBox(height: 16),

                                _mensajeEstado(
                                  context: context,
                                  mensaje: _error,
                                  esError: true,
                                ),

                                _mensajeEstado(
                                  context: context,
                                  mensaje: _mensaje,
                                  esError: false,
                                ),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _recargando ? null : _recargar,
                                    icon: _recargando
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: colors.onPrimary,
                                            ),
                                          )
                                        : const Icon(Icons.add),
                                    label: Text(
                                      _recargando
                                          ? 'Recargando...'
                                          : 'Recargar billetera',
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                _notaInformativa(context),
                              ],
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomRechargeField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;

  const _CustomRechargeField({
    required this.controller,
    required this.enabled,
  });

  @override
  State<_CustomRechargeField> createState() => _CustomRechargeFieldState();
}

class _CustomRechargeFieldState extends State<_CustomRechargeField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: colors.primary.withAlpha(22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: 'Monto a recargar',
          hintText: 'Ej: 25.00',
          prefixIcon: Icon(
            Icons.attach_money,
            color: _isFocused ? colors.primary : colors.onSurfaceVariant,
          ),
          suffixText: 'USD',
          suffixStyle: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}