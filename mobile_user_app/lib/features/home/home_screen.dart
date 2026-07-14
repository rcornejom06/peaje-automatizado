import 'package:flutter/material.dart';
import '../../shared/widgets/mobile_app_header.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/billetera_service.dart';
import '../../core/services/vehiculo_service.dart';
import '../../core/services/seguridad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BilleteraService _billeteraService = BilleteraService();
  final VehiculoService _vehiculoService = VehiculoService();
  final SeguridadService _seguridadService = SeguridadService();

  bool _cargando = true;
  String _saldo = '\$0.00';
  int _totalVehiculos = 0;
  int _totalAlertas = 0;

  Future<void> _cargarResumen() async {
    try {
      setState(() {
        _cargando = true;
      });

      final resultados = await Future.wait([
        _billeteraService.obtenerMiBilletera(),
        _vehiculoService.obtenerVehiculos(),
        _seguridadService.obtenerAlertas(),
      ]);

      final billetera = resultados[0] as Map<String, dynamic>;
      final vehiculos = resultados[1] as List<dynamic>;
      final alertas = resultados[2] as List<dynamic>;

      final saldoNumero =
          double.tryParse(billetera['saldo']?.toString() ?? '0') ?? 0;

      if (!mounted) return;

      setState(() {
        _saldo = '\$${saldoNumero.toStringAsFixed(2)}';
        _totalVehiculos = vehiculos.length;
        _totalAlertas = alertas.length;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saldo = '\$0.00';
        _totalVehiculos = 0;
        _totalAlertas = 0;
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await AuthService().cerrarSesion();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _cerrarSesion(context);
    }
  }

  Future<void> _irRuta(String ruta) async {
    await Navigator.pushNamed(context, ruta);
    await _cargarResumen();
  }

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Widget _saldoPrincipal(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo disponible',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _cargando ? 'Cargando...' : _saldo,
            style: textTheme.displaySmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _irRuta('/billetera'),
              icon: const Icon(Icons.add),
              label: const Text('Recargar billetera'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.onPrimary,
                foregroundColor: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notaActualizar(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: colors.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Desliza hacia abajo para actualizar tu saldo y resumen.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        titulo,
        style: Theme
            .of(context)
            .textTheme
            .titleLarge
            ?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;

    return Scaffold(
      appBar: MobileAppHeader(
        title: 'VíaSmart',
        subtitle: 'Panel principal',
        icon: Icons.home_rounded,
        showBackButton: false,
        showNotifications: true,
        showLogout: true,
      ),

      body: RefreshIndicator(
        onRefresh: _cargarResumen,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _saldoPrincipal(context),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _InformationCard(
                            icon: Icons.directions_car,
                            label: 'Vehículos',
                            value: _cargando ? '...' : _totalVehiculos
                                .toString(),
                            iconColor: colors.secondary,
                            onTap: () => _irRuta('/vehiculos'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InformationCard(
                            icon: Icons.warning_rounded,
                            label: 'Alertas',
                            value: _cargando ? '...' : _totalAlertas.toString(),
                            iconColor: colors.error,
                            onTap: () => _irRuta('/seguridad'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _tituloSeccion('Servicios'),

                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ServiceCard(
                          icon: Icons.person,
                          title: 'Perfil',
                          backgroundColor: colors.primary,
                          onTap: () => _irRuta('/perfil'),
                        ),
                        _ServiceCard(
                          icon: Icons.directions_car,
                          title: 'Vehículos',
                          backgroundColor: colors.secondary,
                          onTap: () => _irRuta('/vehiculos'),
                        ),
                        _ServiceCard(
                          icon: Icons.card_membership,
                          title: 'Membresías',
                          backgroundColor: colors.tertiary,
                          onTap: () => _irRuta('/membresias'),
                        ),
                        _ServiceCard(
                          icon: Icons.receipt_long,
                          title: 'Historial',
                          backgroundColor: colors.primaryContainer,
                          iconForegroundColor: colors.onPrimaryContainer,
                          onTap: () => _irRuta('/pasos'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _ExpandedServiceCard(
                      icon: Icons.account_balance_wallet,
                      title: 'Billetera',
                      subtitle: 'Consulta tu saldo y realiza recargas',
                      backgroundColor: colors.secondaryContainer,
                      iconForegroundColor: colors.onSecondaryContainer,
                      onTap: () => _irRuta('/billetera'),
                    ),

                    const SizedBox(height: 12),

                    _ExpandedServiceCard(
                      icon: Icons.security,
                      title: 'Centro de seguridad',
                      subtitle: 'Alertas de robo y monitoreo',
                      backgroundColor: colors.errorContainer,
                      iconForegroundColor: colors.onErrorContainer,
                      onTap: () => _irRuta('/seguridad'),
                    ),

                    const SizedBox(height: 20),

                    _notaActualizar(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Color? iconForegroundColor;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    this.iconForegroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    final foregroundColor = iconForegroundColor ?? backgroundColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: backgroundColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: foregroundColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback onTap;

  const _InformationCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconForegroundColor;
  final VoidCallback onTap;

  const _ExpandedServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.iconForegroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconForegroundColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colors.outline,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}