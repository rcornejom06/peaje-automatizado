import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/widgets/notificacion_bell.dart';
import '../../core/services/seguridad_service.dart';
import '../../shared/widgets/mobile_app_header.dart';


class SeguridadScreen extends StatefulWidget {
  const SeguridadScreen({super.key});

  @override
  State<SeguridadScreen> createState() => _SeguridadScreenState();
}

class _SeguridadScreenState extends State<SeguridadScreen> {
  final SeguridadService _seguridadService = SeguridadService();

  bool _cargando = true;
  String _error = '';

  List<dynamic> _avisos = [];
  List<dynamic> _alertas = [];

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _cargando = true;
        _error = '';
      });

      final resultados = await Future.wait([
        _seguridadService.obtenerAvisosRobo(),
        _seguridadService.obtenerAlertas(),
      ]);

      if (!mounted) return;

      setState(() {
        _avisos = resultados[0];
        _alertas = resultados[1];
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

  Future<void> _irSolicitarReactivacion() async {
    final resultado = await Navigator.pushNamed(
      context,
      '/solicitar-reactivacion',
    );

    if (resultado == true) {
      await _cargarDatos();
    } else {
      await _cargarDatos();
    }
  }

  Future<void> _irCrearAviso() async {
    final resultado = await Navigator.pushNamed(context, '/crear-aviso-robo');

    if (resultado == true) {
      await _cargarDatos();
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
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

  String _fecha(dynamic valor) {
    if (valor == null) {
      return 'Sin fecha';
    }

    try {
      final fecha = DateTime.parse(valor.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (_) {
      return valor.toString();
    }
  }

  String _obtenerPlaca(dynamic item) {
    if (item['vehiculo_placa'] != null) {
      return item['vehiculo_placa'].toString();
    }

    if (item['placa'] != null) {
      return item['placa'].toString();
    }

    if (item['vehiculo_detalle'] is Map) {
      return item['vehiculo_detalle']['placa']?.toString() ?? 'Sin placa';
    }

    if (item['vehiculo'] is Map) {
      return item['vehiculo']['placa']?.toString() ?? 'Sin placa';
    }

    return _texto(item['vehiculo']);
  }

  Color _colorEstado(String estado, ColorScheme colors) {
    switch (estado.toLowerCase().trim()) {
      case 'activo':
      case 'pendiente':
        return colors.tertiary;
      case 'detectado':
      case 'derivada':
        return colors.error;
      case 'cerrado':
      case 'cerrada':
        return colors.secondary;
      case 'cancelado':
      case 'descartada':
        return colors.outline;
      default:
        return colors.primary;
    }
  }

  Widget _resumen(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            colors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _resumenItem(
            context: context,
            titulo: 'Avisos',
            valor: _avisos.length.toString(),
          ),
          _resumenItem(
            context: context,
            titulo: 'Alertas',
            valor: _alertas.length.toString(),
          ),
          _resumenItem(
            context: context,
            titulo: 'Activos',
            valor: _avisos
                .where((a) => a['estado']?.toString().toLowerCase() == 'activo')
                .length
                .toString(),
          ),
        ],
      ),
    );
  }

  Widget _resumenItem({
    required BuildContext context,
    required String titulo,
    required String valor,
  }) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Column(
      children: [
        Text(
          valor,
          style: textTheme.headlineSmall?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onPrimary.withAlpha(220),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _avisoCard(dynamic aviso) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    final estado = _texto(aviso['estado']);
    final estadoColor = _colorEstado(estado, colors);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: estadoColor.withAlpha(24),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.directions_car,
            color: estadoColor,
          ),
        ),
        title: Text(
          _obtenerPlaca(aviso),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Denuncia: ${_texto(aviso['numero_denuncia'])}\n'
                'Entidad: ${_texto(aviso['entidad_denuncia'])}\n'
                'Lugar: ${_texto(aviso['lugar_robo'])}\n'
                'Estado: $estado',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  String? _extraerUrlMapsDesdeTexto(String texto) {
    final regex = RegExp(
      r'https:\/\/www\.google\.com\/maps\?q=[^\s]+',
      caseSensitive: false,
    );

    final match = regex.firstMatch(texto);

    if (match == null) {
      return null;
    }

    return match.group(0);
  }

  String? _obtenerUrlMaps(dynamic alerta) {
    final urlDirecta = alerta['url_maps'];

    if (urlDirecta != null && urlDirecta
        .toString()
        .trim()
        .isNotEmpty) {
      return urlDirecta.toString();
    }

    final ubicacionDetalle = alerta['ubicacion_detalle'];

    if (ubicacionDetalle is Map &&
        ubicacionDetalle['url_maps'] != null &&
        ubicacionDetalle['url_maps']
            .toString()
            .trim()
            .isNotEmpty) {
      return ubicacionDetalle['url_maps'].toString();
    }

    final ubicacion = alerta['ubicacion'];

    if (ubicacion is Map &&
        ubicacion['url_maps'] != null &&
        ubicacion['url_maps']
            .toString()
            .trim()
            .isNotEmpty) {
      return ubicacion['url_maps'].toString();
    }

    final ubicacionDeteccion = alerta['ubicacion_deteccion'];

    if (ubicacionDeteccion is Map &&
        ubicacionDeteccion['url_maps'] != null &&
        ubicacionDeteccion['url_maps']
            .toString()
            .trim()
            .isNotEmpty) {
      return ubicacionDeteccion['url_maps'].toString();
    }

    final latitud = alerta['latitud_deteccion'];
    final longitud = alerta['longitud_deteccion'];

    if (latitud != null &&
        longitud != null &&
        latitud
            .toString()
            .trim()
            .isNotEmpty &&
        longitud
            .toString()
            .trim()
            .isNotEmpty) {
      return 'https://www.google.com/maps?q=$latitud,$longitud';
    }

    final descripcion = alerta['descripcion']?.toString() ?? '';
    final mensaje = alerta['mensaje']?.toString() ?? '';

    return _extraerUrlMapsDesdeTexto('$descripcion $mensaje');
  }

  Future<void> _abrirUbicacion(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La URL de ubicación no es válida.'),
        ),
      );
      return;
    }

    final abierto = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abierto) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la ubicación.'),
        ),
      );
    }
  }

  Widget _alertaCard(dynamic alerta) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    final estado = _texto(alerta['estado']);
    final estadoColor = _colorEstado(estado, colors);
    final urlMaps = _obtenerUrlMaps(alerta);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: estadoColor.withAlpha(24),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: estadoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _obtenerPlaca(alerta),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _estadoChip(
                  context: context,
                  estado: estado,
                  color: estadoColor,
                ),
              ],
            ),

            const SizedBox(height: 12),

            _infoLinea(
              context: context,
              label: 'Tipo',
              value: _texto(alerta['tipo_alerta']),
            ),

            _infoLinea(
              context: context,
              label: 'Peaje',
              value: _texto(alerta['peaje_nombre'] ?? alerta['peaje']),
            ),

            _infoLinea(
              context: context,
              label: 'Fecha',
              value: _fecha(alerta['fecha_hora']),
            ),

            const SizedBox(height: 10),

            Text(
              _texto(alerta['descripcion']),
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),

            if (urlMaps != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _abrirUbicacion(urlMaps),
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Ver ubicación'),
                ),
              ),
            ] else
              ...[
                const SizedBox(height: 10),
                Text(
                  'Ubicación no disponible',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _estadoChip({
    required BuildContext context,
    required String estado,
    required Color color,
  }) {
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withAlpha(55),
        ),
      ),
      child: Text(
        estado,
        style: textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoLinea({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(
              text: value,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionAvisos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tituloSeccion('Mis avisos de robo'),
        const SizedBox(height: 10),
        if (_avisos.isEmpty)
          _emptyCard(
            icon: Icons.info_outline,
            text: 'No tienes avisos de robo registrados.',
          )
        else
          ..._avisos.map(_avisoCard),
      ],
    );
  }

  Widget _seccionAlertas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tituloSeccion('Alertas relacionadas'),
        const SizedBox(height: 10),
        if (_alertas.isEmpty)
          _emptyCard(
            icon: Icons.info_outline,
            text: 'No tienes alertas registradas.',
          )
        else
          ..._alertas.map(_alertaCard),
      ],
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
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String text,
  }) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: colors.primary,
        ),
        title: Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 52,
                  color: colors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudo cargar la información',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _cargarDatos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Intentar nuevamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accionesSeguridad() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _irCrearAviso,
            icon: const Icon(Icons.report_gmailerrorred_outlined),
            label: const Text('Reportar vehículo robado'),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _irSolicitarReactivacion,
            icon: const Icon(Icons.restore),
            label: const Text('Solicitar reactivación de vehículo'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _cargando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error.isNotEmpty
          ? _errorView(context)
          : RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MobileAppHeader(
                        title: 'Seguridad',
                        subtitle: 'Avisos de robo y alertas',
                        icon: Icons.security,
                        showBackButton: true,
                        showRefresh: true,
                        showLogout: false,
                        onRefresh: _cargarDatos,
                      ),

                      const SizedBox(height: 18),

                      _accionesSeguridad(),

                      const SizedBox(height: 22),

                      _resumen(context),

                      const SizedBox(height: 22),

                      _seccionAvisos(),

                      const SizedBox(height: 22),

                      _seccionAlertas(),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}