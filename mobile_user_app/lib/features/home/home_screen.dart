import 'package:flutter/material.dart';

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
          'Mi Peaje',
          style: TextStyle(
            color: darkGray,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarResumen,
            icon: const Icon(Icons.refresh, color: primaryBlue),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmarCerrarSesion(context),
            icon: const Icon(Icons.logout, color: primaryBlue),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarResumen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryBlue,
                            primaryBlue.withAlpha(220),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cargando ? 'Cargando...' : _saldo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _irRuta('/billetera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryBlue,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Recargar billetera',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _InformationCard(
                            icon: Icons.directions_car,
                            label: 'Vehículos',
                            value: _cargando
                                ? '...'
                                : _totalVehiculos.toString(),
                            iconColor: const Color(0xFF16A34A),
                            onTap: () => _irRuta('/vehiculos'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InformationCard(
                            icon: Icons.warning_rounded,
                            label: 'Alertas',
                            value:
                                _cargando ? '...' : _totalAlertas.toString(),
                            iconColor: const Color(0xFFDC2626),
                            onTap: () => _irRuta('/seguridad'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                color: lightGray,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Servicios',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: darkGray,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

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
                          backgroundColor: const Color(0xFF1D4ED8),
                          onTap: () => _irRuta('/perfil'),
                        ),
                        _ServiceCard(
                          icon: Icons.directions_car,
                          title: 'Vehículos',
                          backgroundColor: const Color(0xFF16A34A),
                          onTap: () => _irRuta('/vehiculos'),
                        ),
                        _ServiceCard(
                          icon: Icons.card_membership,
                          title: 'Membresías',
                          backgroundColor: const Color(0xFF7C3AED),
                          onTap: () => _irRuta('/membresias'),
                        ),
                        _ServiceCard(
                          icon: Icons.receipt_long,
                          title: 'Historial',
                          backgroundColor: const Color(0xFF0891B2),
                          onTap: () => _irRuta('/pasos'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _ExpandedServiceCard(
                      icon: Icons.account_balance_wallet,
                      title: 'Billetera',
                      subtitle: 'Consulta tu saldo y realiza recargas',
                      backgroundColor: const Color(0xFFF59E0B),
                      onTap: () => _irRuta('/billetera'),
                    ),

                    const SizedBox(height: 12),

                    _ExpandedServiceCard(
                      icon: Icons.security,
                      title: 'Centro de seguridad',
                      subtitle: 'Alertas de robo y monitoreo',
                      backgroundColor: const Color(0xFFDC2626),
                      onTap: () => _irRuta('/seguridad'),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderGray,
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: primaryBlue,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Desliza hacia abajo para actualizar tu saldo y resumen.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
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
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: backgroundColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: backgroundColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
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
  final VoidCallback onTap;

  const _ExpandedServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: backgroundColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: backgroundColor,
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
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFCBD5E1),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}