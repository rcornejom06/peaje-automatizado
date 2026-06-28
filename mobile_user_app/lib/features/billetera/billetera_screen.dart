import 'package:flutter/material.dart';

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

      setState(() {
        _billetera = data;
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
        _refreshController.reset();
      }
    }
  }

  Future<void> _recargar() async {
    final montoTexto = _montoController.text.trim();
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

      setState(() {
        _mensaje = 'Recarga exitosa. Tu saldo ha sido actualizado.';
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      await _cargarBilletera();
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color darkGray = Color(0xFF0F172A);
    const Color lightGray = Color(0xFFF8FAFC);
    const Color borderGray = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mi Billetera',
          style: TextStyle(
            color: darkGray,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarBilletera,
            icon: RotationTransition(
              turns: _refreshController,
              child: const Icon(Icons.refresh, color: primaryBlue),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Hero Section: Saldo Principal
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryBlue,
                            Color(0xFF2563EB),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withAlpha(30),
                            blurRadius: 16,
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
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Saldo disponible',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _saldoTexto(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sección: Información
                  Container(
                    color: lightGray,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkGray,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.verified_user,
                          title: 'Estado',
                          value: _billetera?['estado'] ?? 'Sin dato',
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _InfoCard(
                          icon: Icons.numbers,
                          title: 'ID de billetera',
                          value: _billetera?['id']?.toString() ?? 'Sin dato',
                          color: primaryBlue,
                        ),
                      ],
                    ),
                  ),

                  // Sección: Recargar
                  Container(
                    color: lightGray,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recargar saldo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkGray,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderGray,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Campo monto
                              _CustomRechargeField(
                                controller: _montoController,
                                enabled: !_recargando,
                              ),
                              const SizedBox(height: 16),

                              // Mensajes de estado
                              if (_error.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _error,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (_mensaje.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _mensaje,
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Botón recargar
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      _recargando ? null : _recargar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBackgroundColor:
                                        primaryBlue.withAlpha(150),
                                  ),
                                  child: _recargando
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Recargar billetera',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Nota informativa
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue.shade700,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Las recargas se procesarán en tiempo real. Tu saldo se actualizará inmediatamente.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.blue.shade700,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

// Widget: Tarjeta de información
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget: Campo de recarga personalizado
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
    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color borderGray = Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: primaryBlue.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Monto a recargar',
          hintText: 'Ej: 25.00',
          prefixIcon: Icon(
            Icons.attach_money,
            color: _isFocused ? primaryBlue : const Color(0xFF94A3B8),
            size: 20,
          ),
          suffixText: 'USD',
          suffixStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderGray, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderGray, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: borderGray.withAlpha(100),
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            letterSpacing: 0.1,
          ),
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF94A3B8).withAlpha(150),
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}