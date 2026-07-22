import 'package:flutter/material.dart';
import '../../shared/widgets/mobile_app_header.dart';
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

      if (!mounted) return;

      setState(() {
        _planes = resultados[0] as List<dynamic>;
        _membresiaActiva = resultados[1] as Map<String, dynamic>?;
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

  Future<void> _comprarPlan(dynamic plan) async {
    final nombrePlan = plan['nombre'] ?? 'Plan';
    final precio = plan['precio'] ?? '0';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme
            .of(context)
            .colorScheme;
        final textTheme = Theme
            .of(context)
            .textTheme;

        return AlertDialog(
          title: const Text('Confirmar compra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombrePlan.toString(),
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$$precio USD',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Deseas continuar con esta compra?',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Comprar'),
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

      if (!mounted) return;

      setState(() {
        _mensaje = 'Membresía comprada exitosamente.';
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;

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
        .trim()
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

  Widget _mensajeEstado({
    required BuildContext context,
    required String mensaje,
    required bool esError,
  }) {
    if (mensaje.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme
        .of(context)
        .colorScheme;

    final backgroundColor =
    esError ? colors.errorContainer : colors.secondaryContainer;
    final foregroundColor =
    esError ? colors.onErrorContainer : colors.onSecondaryContainer;
    final icon = esError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
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
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSeccion(String titulo) {
    return Text(
      titulo,
      style: Theme
          .of(context)
          .textTheme
          .titleLarge
          ?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _emptyPlanes(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 36,
              color: colors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay planes disponibles',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Intenta más tarde',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    final tieneMembresia = _membresiaActiva != null &&
        (_membresiaActiva?.isNotEmpty ?? false);

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tieneMembresia)
                    _MembresiaActivaCard(
                      membresia: _membresiaActiva!,
                      texto: _texto,
                    )
                  else
                    const _MembresiaInactiveCard(),

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

                  const SizedBox(height: 12),

                  _tituloSeccion('Planes disponibles'),

                  const SizedBox(height: 16),

                  if (_planes.isEmpty)
                    _emptyPlanes(context)
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppHeader(
        title: 'Membresías',
        subtitle: 'Planes y pases disponibles',
        icon: Icons.card_membership,
        showBackButton: true,
        showRefresh: true,
        showLogout: false,
        onRefresh: _cargarDatos,
      ),
      body: _cargando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _contenido(context),
    );
  }
}

class _MembresiaInactiveCard extends StatelessWidget {
  const _MembresiaInactiveCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_membership_outlined,
                size: 42,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin membresía activa',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Compra un plan para disfrutar de beneficios exclusivos',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    final nombrePlan = _obtenerNombrePlan();
    final pasesRestantes = texto(membresia['pases_restantes']);
    final fechaInicio = texto(membresia['fecha_inicio']);
    final estado = texto(membresia['estado']).toUpperCase();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.onPrimary.withAlpha(28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.card_membership,
              color: colors.onPrimary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nombrePlan,
            style: textTheme.headlineSmall?.copyWith(
              color: colors.onPrimary,
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
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colors.onPrimary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onPrimary.withAlpha(220),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimary,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    final nombre = texto(plan['nombre']);
    final descripcion = texto(plan['descripcion']);
    final precio = dinero(plan['precio']);
    final pases = texto(plan['pases_incluidos']);
    final descuento = texto(plan['descuento_porcentaje']);

    return Card(
      child: Padding(
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
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$descuento% OFF',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                const _PlanFeature(
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
              height: 52,
              child: ElevatedButton.icon(
                onPressed: comprando ? null : onComprar,
                icon: comprando
                    ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary,
                  ),
                )
                    : const Icon(Icons.shopping_cart_outlined),
                label: Text(
                  comprando ? 'Comprando...' : 'Comprar plan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: colors.onPrimaryContainer,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer.withAlpha(210),
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}