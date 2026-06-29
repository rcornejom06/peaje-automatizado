import 'package:flutter/material.dart';

import '../../core/services/membresia_service.dart';

class MembresiasScreen extends StatefulWidget {
  const MembresiasScreen({super.key});

  @override
  State<MembresiasScreen> createState() => _MembresiasScreenState();
}

class _MembresiasScreenState extends State<MembresiasScreen>
    with SingleTickerProviderStateMixin {
  final MembresiaService _membresiaService = MembresiaService();

  late AnimationController _refreshController;

  bool _cargando = true;
  bool _comprando = false;
  String _error = '';
  String _mensaje = '';

  List<dynamic> _planes = [];
  Map<String, dynamic>? _membresiaActiva;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
        _mensaje = '';
      });

      _refreshController.forward();

      final resultados = await Future.wait([
        _membresiaService.obtenerPlanes(),
        _membresiaService.obtenerMembresiaActiva(),
      ]);

      setState(() {
        _planes = resultados[0] as List<dynamic>;
        _membresiaActiva = resultados[1] as Map<String, dynamic>?;
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

  Future<void> _comprarPlan(dynamic plan) async {
    final nombrePlan = plan['nombre'] ?? 'Plan';
    final precio = plan['precio'] ?? '0';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        const Color primaryBlue = Color(0xFF1D4ED8);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirmar compra',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombrePlan,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$$precio USD',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Deseas continuar con esta compra?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF0F172A).withAlpha(200),
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Comprar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      setState(() {
        _comprando = true;
        _error = '';
        _mensaje = '';
      });

      await _membresiaService.comprarMembresia(
        planId: int.parse(plan['id'].toString()),
      );

      setState(() {
        _mensaje = 'Membresía comprada exitosamente.';
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      await _cargarDatos();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _comprando = false;
        });
      }
    }
  }

  String _texto(dynamic valor) {
    if (valor == null || valor
        .toString()
        .isEmpty) {
      return 'Sin dato';
    }
    return valor.toString();
  }

  String _dinero(dynamic valor) {
    final numero = double.tryParse(valor?.toString() ?? '0') ?? 0;
    return '\$${numero.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
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
          'Membresías',
          style: TextStyle(
            color: darkGray,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarDatos,
            icon: RotationTransition(
              turns: _refreshController,
              child: const Icon(Icons.refresh, color: primaryBlue),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Membresía activa
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: _membresiaActiva == null ||
                    (_membresiaActiva?.isEmpty ?? true)
                    ? _MembresiaInactiveCard()
                    : _MembresiaActivaCard(
                  membresia: _membresiaActiva!,
                  texto: _texto,
                ),
              ),

              // Mensajes de estado
              if (_error.isNotEmpty || _mensaje.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(top: 16),
                  child: Column(
                    children: [
                      if (_error.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
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
                    ],
                  ),
                ),

              // Planes disponibles
              Container(
                color: lightGray,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Planes disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: darkGray,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_planes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 32,
                              color: primaryBlue.withAlpha(150),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay planes disponibles',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Intenta más tarde',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: darkGray.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _planes.map((plan) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PlanCard(
                              plan: plan,
                              onComprar: () => _comprarPlan(plan),
                              comprando: _comprando,
                              dinero: _dinero,
                              texto: _texto,
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget: Membresía Inactiva
class _MembresiaInactiveCard extends StatelessWidget {
  const _MembresiaInactiveCard();

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);

    return Container(
      decoration: BoxDecoration(
        color: primaryBlue.withAlpha(10),
        border: Border.all(
          color: primaryBlue.withAlpha(50),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 48,
            color: primaryBlue.withAlpha(200),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin membresía activa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compra un plan para disfrutar de beneficios exclusivos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF0F172A).withAlpha(180),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget: Membresía Activa
class _MembresiaActivaCard extends StatelessWidget {
  final Map<String, dynamic> membresia;
  final String Function(dynamic) texto;

  const _MembresiaActivaCard({
    required this.membresia,
    required this.texto,
  });

  String _obtenerNombrePlan() {
    final plan = membresia['plan'];
    final planDetalle = membresia['plan_detalle'];
    final planInfo = membresia['plan_info'];

    if (planDetalle is Map && planDetalle['nombre'] != null) {
      return planDetalle['nombre'].toString();
    }

    if (planInfo is Map && planInfo['nombre'] != null) {
      return planInfo['nombre'].toString();
    }

    if (plan is Map && plan['nombre'] != null) {
      return plan['nombre'].toString();
    }

    if (membresia['plan_nombre'] != null) {
      return membresia['plan_nombre'].toString();
    }

    if (membresia['nombre_plan'] != null) {
      return membresia['nombre_plan'].toString();
    }

    if (membresia['nombre'] != null) {
      return membresia['nombre'].toString();
    }

    if (membresia['plan'] != null) {
      return 'Plan ${membresia['plan']}';
    }

    return 'Membresía activa';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);

    final nombrePlan = _obtenerNombrePlan();
    final pasesRestantes = texto(membresia['pases_restantes']);
    final fechaInicio = texto(membresia['fecha_inicio']);
    final estado = texto(membresia['estado']).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, Color(0xFF2563EB)],
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.card_membership,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nombrePlan,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          _MembresiaInfoItem(
            icon: Icons.confirmation_number,
            label: 'Pases restantes',
            value: pasesRestantes,
          ),
          const SizedBox(height: 12),
          _MembresiaInfoItem(
            icon: Icons.event_available,
            label: 'Fecha de compra',
            value: fechaInicio,
          ),
          const SizedBox(height: 12),
          const _MembresiaInfoItem(
            icon: Icons.all_inclusive,
            label: 'Caducidad',
            value: 'Sin fecha de vencimiento',
          ),
          const SizedBox(height: 12),
          _MembresiaInfoItem(
            icon: Icons.check_circle,
            label: 'Estado',
            value: estado,
          ),
        ],
      ),
    );
  }
}
// Widget: Item de información de membresía
class _MembresiaInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MembresiaInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,

                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),)
        ,
      ]
      ,
    );
  }
}

// Widget: Tarjeta de plan
class _PlanCard extends StatelessWidget {
  final dynamic plan;
  final VoidCallback onComprar;
  final bool comprando;
  final String Function(dynamic) dinero;
  final String Function(dynamic) texto;

  const _PlanCard({
    required this.plan,
    required this.onComprar,
    required this.comprando,
    required this.dinero,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color borderGray = Color(0xFFE2E8F0);

    final nombre = texto(plan['nombre']);
    final descripcion = texto(plan['descripcion']);
    final precio = dinero(plan['precio']);
    final pases = texto(plan['pases_incluidos']);
    final descuento = texto(plan['descuento_porcentaje']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryBlue.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$descuento% OFF',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grid de características
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _PlanFeature(
                icon: Icons.attach_money,
                label: 'Precio',
                value: precio,
              ),
              _PlanFeature(
                icon: Icons.confirmation_number_outlined,
                label: 'Pases',
                value: pases,
              ),
              _PlanFeature(
                icon: Icons.all_inclusive,
                label: 'Validez',
                value: 'Hasta agotar pases',
              ),
              _PlanFeature(
                icon: Icons.trending_up,
                label: 'Descuento',
                value: '$descuento%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: comprando ? null : onComprar,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: primaryBlue.withAlpha(150),
              ),
              child: comprando
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Text(
                'Comprar plan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget: Feature de plan
class _PlanFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PlanFeature({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D4ED8);

    return Container(
      decoration: BoxDecoration(
        color: primaryBlue.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: primaryBlue,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}