import 'package:flutter/material.dart';

import 'package:mobile_user_app/core/services/api_service.dart';
import 'package:mobile_user_app/core/models/comprobante_paso.dart';

class ComprobantePasoScreen extends StatefulWidget {
  final int pasoId;

  const ComprobantePasoScreen({
    super.key,
    required this.pasoId,
  });

  @override
  State<ComprobantePasoScreen> createState() => _ComprobantePasoScreenState();
}

class _ComprobantePasoScreenState extends State<ComprobantePasoScreen> {
  final ApiService _apiService = ApiService();

  bool _cargando = true;
  String? _error;
  ComprobantePaso? _comprobante;

  @override
  void initState() {
    super.initState();
    _cargarComprobante();
  }

  Future<void> _cargarComprobante() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final comprobante =
          await _apiService.obtenerComprobantePaso(widget.pasoId);

      if (!mounted) return;

      setState(() {
        _comprobante = comprobante;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });
    }
  }

  String _formatearFecha(String fecha) {
    if (fecha.isEmpty) return 'Sin fecha';

    try {
      final date = DateTime.parse(fecha).toLocal();

      String dosDigitos(int value) => value.toString().padLeft(2, '0');

      return '${dosDigitos(date.day)}/${dosDigitos(date.month)}/${date.year} '
          '${dosDigitos(date.hour)}:${dosDigitos(date.minute)}';
    } catch (_) {
      return fecha;
    }
  }

  String _formatearValor(String valor) {
    final numero = double.tryParse(valor) ?? 0;
    return '\$${numero.toStringAsFixed(2)}';
  }

  String _textoEstadoPago(String estado) {
    switch (estado) {
      case 'pagado':
        return 'Pagado';
      case 'membresia':
        return 'Pagado con membresía';
        case 'exonerado':
        return 'Exonerado';
      case 'pendiente':
        return 'Pendiente';
      case 'fallido':
        return 'Fallido';
      default:
        return estado;
    }
  }

  Color _colorEstadoPago(BuildContext context, String estado) {
    final colors = Theme.of(context).colorScheme;

    switch (estado) {
      case 'pagado':
      case 'membresia':
      case 'exonerado':
        return colors.secondary;
      case 'fallido':
        return colors.error;
      case 'pendiente':
        return Colors.orange;
      default:
        return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprobante'),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _error != null
                ? _bloqueError(context)
                : _comprobante == null
                    ? const Center(
                        child: Text('No se encontró el comprobante.'),
                      )
                    : _contenidoComprobante(context, _comprobante!),
      ),
      backgroundColor: colors.surface,
    );
  }

  Widget _bloqueError(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: colors.onErrorContainer,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                'No se pudo cargar el comprobante.',
                style: TextStyle(
                  color: colors.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                style: TextStyle(
                  color: colors.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _cargarComprobante,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenidoComprobante(
    BuildContext context,
    ComprobantePaso comprobante,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 26,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.outline.withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _encabezado(context, comprobante),
                _separador(context),
                _linea('Ticket:', comprobante.ticket),
                _linea('Placa:', comprobante.placa),
                _linea('Peaje:', comprobante.peaje),
                _linea('Carril:', comprobante.carril),
                _linea('Categoría:', comprobante.categoria),
                _linea('Cliente:', comprobante.tipoCliente),
                _linea('Pago:', comprobante.metodoPago),
                _linea('Vehículo:', comprobante.vehiculo),
                _linea('Usuario:', comprobante.usuario),
                _linea('Fecha:', _formatearFecha(comprobante.fechaHora)),
                _lineaEstadoPago(context, comprobante.estadoPago),
                _linea('Seguridad:', comprobante.estadoSeguridad),
                _total(context, comprobante.valor),
                _observacion(context, comprobante.observacion),
                _separador(context),
                const SizedBox(height: 12),
                Icon(
                  Icons.confirmation_number_outlined,
                  color: colors.primary,
                  size: 42,
                ),
                const SizedBox(height: 8),
                Text(
                  'Comprobante generado electrónicamente',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Gracias por utilizar el sistema de peaje automatizado.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezado(
    BuildContext context,
    ComprobantePaso comprobante,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Text(
          comprobante.peaje.toUpperCase(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          comprobante.empresa,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          comprobante.documento,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _separador(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.outline.withOpacity(0.55),
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }

  Widget _linea(String label, String value) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value.isEmpty ? '--' : value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _lineaEstadoPago(BuildContext context, String estado) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              'Estado:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _textoEstadoPago(estado),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _colorEstadoPago(context, estado),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _total(BuildContext context, String valor) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.outline.withOpacity(0.6),
          ),
          bottom: BorderSide(
            color: colors.outline.withOpacity(0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Valor:',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            _formatearValor(valor),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _observacion(BuildContext context, String observacion) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outline.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observación',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            observacion,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}