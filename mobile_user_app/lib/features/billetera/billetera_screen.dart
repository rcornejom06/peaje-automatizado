import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/api_service.dart';
import '../../core/services/billetera_service.dart';
import '../../core/services/tarjeta_bancaria_service.dart';
import '../../shared/widgets/mobile_app_header.dart';

class BilleteraScreen extends StatefulWidget {
  const BilleteraScreen({super.key});

  @override
  State<BilleteraScreen> createState() => _BilleteraScreenState();
}

class _BilleteraScreenState extends State<BilleteraScreen>
    with SingleTickerProviderStateMixin {
  final BilleteraService _billeteraService = BilleteraService();
  final ApiService _apiService = ApiService();
  final TarjetaBancariaService _tarjetaService = TarjetaBancariaService();

  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  late AnimationController _refreshController;

  bool _cargando = true;
  bool _recargando = false;

  String _error = '';
  String _mensaje = '';

  Map<String, dynamic>? _billetera;
  List<dynamic> _movimientos = [];
  List<dynamic> _tarjetas = [];

  int? _tarjetaSeleccionadaId;

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

      _refreshController.forward(from: 0);

      final dataBilletera = await _billeteraService.obtenerMiBilletera();
      final dataMovimientos = await _obtenerMovimientosSeguro();
      final dataTarjetas = await _obtenerTarjetasSeguro();

      if (!mounted) return;

      setState(() {
        _billetera = dataBilletera;
        _movimientos = dataMovimientos;
        _tarjetas = dataTarjetas;
        _tarjetaSeleccionadaId = _obtenerTarjetaInicial(dataTarjetas);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      _refreshController.reset();
    }
  }

  Future<List<dynamic>> _obtenerMovimientosSeguro() async {
    try {
      final data = await _apiService.get('/pagos/transacciones/');

      final movimientos = _extraerListaMovimientos(data)
          .map(_normalizarMovimiento)
          .where(_movimientoTieneDatos)
          .where((movimiento) => !_esUsoDePaseMembresia(movimiento))
          .toList();

      final movimientosConIndice = movimientos
          .asMap()
          .entries
          .toList();

      movimientosConIndice.sort((a, b) {
        final fechaA = _fechaMovimientoParaOrdenar(a.value);
        final fechaB = _fechaMovimientoParaOrdenar(b.value);

        final comparacion = fechaB.compareTo(fechaA);

        if (comparacion != 0) {
          return comparacion;
        }

        return a.key.compareTo(b.key);
      });

      return movimientosConIndice.map((entry) => entry.value).take(5).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> _obtenerTarjetasSeguro() async {
    try {
      final data = await _tarjetaService.obtenerTarjetas();

      return data
          .map(_normalizarTarjeta)
          .where((tarjeta) {
        return tarjeta.isNotEmpty &&
            tarjeta['estado'] == 'activa' &&
            tarjeta['vencida'] != true;
      })
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<dynamic> _extraerListaMovimientos(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    if (data is Map && data['transacciones'] is List) {
      return data['transacciones'];
    }

    if (data is Map && data['movimientos'] is List) {
      return data['movimientos'];
    }

    if (data is Map && data['data'] is List) {
      return data['data'];
    }

    return [];
  }

  Map<String, dynamic> _normalizarMovimiento(dynamic movimiento) {
    if (movimiento is Map<String, dynamic>) {
      return movimiento;
    }

    if (movimiento is Map) {
      return movimiento.map(
            (key, value) => MapEntry(key.toString(), value),
      );
    }

    return {};
  }

  Map<String, dynamic> _normalizarTarjeta(dynamic tarjeta) {
    if (tarjeta is Map<String, dynamic>) {
      return tarjeta;
    }

    if (tarjeta is Map) {
      return tarjeta.map(
            (key, value) => MapEntry(key.toString(), value),
      );
    }

    return {};
  }

  int? _obtenerTarjetaId(dynamic tarjeta) {
    final mapa = _normalizarTarjeta(tarjeta);

    if (mapa['id'] == null) {
      return null;
    }

    return int.tryParse(mapa['id'].toString());
  }

  int? _obtenerTarjetaInicial(List<dynamic> tarjetas) {
    if (tarjetas.isEmpty) {
      return null;
    }

    final principales = tarjetas.where((tarjeta) {
      final mapa = _normalizarTarjeta(tarjeta);
      return mapa['principal'] == true;
    }).toList();

    if (principales.isNotEmpty) {
      return _obtenerTarjetaId(principales.first);
    }

    return _obtenerTarjetaId(tarjetas.first);
  }

  dynamic _valorCampo(Map<String, dynamic> movimiento, List<String> campos) {
    for (final campo in campos) {
      final valor = movimiento[campo];

      if (valor != null && valor
          .toString()
          .trim()
          .isNotEmpty) {
        return valor;
      }
    }

    return null;
  }

  String _textoCampo(Map<String, dynamic> movimiento, List<String> campos) {
    final valor = _valorCampo(movimiento, campos);

    if (valor == null) {
      return '';
    }

    return valor.toString().trim();
  }

  bool _movimientoTieneDatos(Map<String, dynamic> movimiento) {
    final monto = _montoMovimiento(movimiento);
    final fecha = _fechaValorMovimiento(movimiento);

    final descripcion = _textoCampo(movimiento, [
      'descripcion',
      'detalle',
      'concepto',
      'observacion',
      'mensaje',
      'tipo_display',
      'tipo_nombre',
    ]);

    final tipo = _textoCampo(movimiento, [
      'tipo',
      'tipo_transaccion',
      'tipo_movimiento',
      'clase',
    ]);

    if (monto != 0) {
      return true;
    }

    if (descripcion.isNotEmpty &&
        descripcion.toLowerCase() != 'movimiento de billetera') {
      return true;
    }

    if (tipo.isNotEmpty && fecha != null) {
      return true;
    }

    return false;
  }

  dynamic _fechaValorMovimiento(Map<String, dynamic> movimiento) {
    return _valorCampo(movimiento, [
      'fecha_creacion',
      'fecha_hora',
      'fecha',
      'creado_en',
      'created_at',
      'fecha_transaccion',
      'fecha_registro',
    ]);
  }

  DateTime _fechaMovimientoParaOrdenar(Map<String, dynamic> movimiento) {
    final valor = _fechaValorMovimiento(movimiento);

    if (valor == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.tryParse(valor.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _textoTarjeta(dynamic tarjeta) {
    final mapa = _normalizarTarjeta(tarjeta);

    final alias = mapa['alias']?.toString();
    final marca = mapa['marca_display']?.toString() ?? 'Tarjeta';
    final numero = mapa['numero_enmascarado']?.toString() ?? '';

    if (alias != null && alias
        .trim()
        .isNotEmpty) {
      return '$alias · $numero';
    }

    return '$marca · $numero';
  }

  Future<void> _irATarjetas() async {
    await Navigator.pushNamed(context, '/mis-tarjetas');

    if (!mounted) return;

    await _cargarBilletera();
  }

  Future<void> _recargar() async {
    final montoTexto = _montoController.text.trim().replaceAll(',', '.');
    final monto = double.tryParse(montoTexto);

    if (_tarjetas.isEmpty) {
      setState(() {
        _error = 'Primero debes registrar una tarjeta bancaria.';
        _mensaje = '';
      });
      return;
    }

    if (_tarjetaSeleccionadaId == null) {
      setState(() {
        _error = 'Selecciona una tarjeta bancaria.';
        _mensaje = '';
      });
      return;
    }

    if (monto == null || monto <= 0) {
      setState(() {
        _error = 'Ingresa un monto válido y mayor a cero.';
        _mensaje = '';
      });
      return;
    }

    if (_cvvController.text
        .trim()
        .length < 3) {
      setState(() {
        _error = 'Ingresa el CVV de la tarjeta.';
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
      final respuesta = await _tarjetaService.recargarBilletera(
        tarjetaId: _tarjetaSeleccionadaId!,
        monto: montoTexto,
        cvv: _cvvController.text.trim(),
      );

      _montoController.clear();
      _cvvController.clear();

      if (!mounted) return;

      final saldoActual = respuesta is Map ? respuesta['saldo_actual'] : null;

      setState(() {
        _mensaje = saldoActual != null
            ? 'Recarga exitosa. Saldo actual: \$$saldoActual.'
            : 'Recarga exitosa. Tu saldo ha sido actualizado.';
      });

      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      await _cargarBilletera();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _recargando = false;
      });
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

  bool _esUsoDePaseMembresia(Map<String, dynamic> movimiento) {
    final tipo = _textoCampo(movimiento, [
      'tipo_transaccion',
      'tipo',
      'tipo_movimiento',
      'clase',
    ]).toLowerCase();

    final metodoPago = _textoCampo(movimiento, [
      'metodo_pago',
      'metodo',
      'forma_pago',
    ]).toLowerCase();

    final descripcion = _textoCampo(movimiento, [
      'descripcion',
      'detalle',
      'concepto',
      'observacion',
      'mensaje',
      'referencia_pago',
    ]).toLowerCase();

    final textoCompleto = '$tipo $metodoPago $descripcion';
    final monto = _montoMovimiento(movimiento);

    return monto == 0 &&
        (textoCompleto.contains('uso_membresia') ||
            textoCompleto.contains('uso membresia') ||
            textoCompleto.contains('uso membresía') ||
            textoCompleto.contains('membresia') && metodoPago == 'membresia');
  }

  bool _esMovimientoIngreso(Map<String, dynamic> movimiento) {
    final tipo = _textoCampo(movimiento, [
      'tipo_transaccion',
      'tipo',
      'tipo_movimiento',
      'clase',
    ]).toLowerCase();

    final metodoPago = _textoCampo(movimiento, [
      'metodo_pago',
      'metodo',
      'forma_pago',
    ]).toLowerCase();

    final referencia = _textoCampo(movimiento, [
      'referencia_pago',
      'referencia',
      'codigo_referencia',
    ]).toLowerCase();

    final descripcion = _textoCampo(movimiento, [
      'descripcion',
      'detalle',
      'concepto',
      'observacion',
      'mensaje',
    ]).toLowerCase();

    final textoCompleto = '$tipo $metodoPago $referencia $descripcion';

    if (textoCompleto.contains('recarga') ||
        textoCompleto.contains('deposito') ||
        textoCompleto.contains('depósito') ||
        textoCompleto.contains('abono') ||
        textoCompleto.contains('ingreso')) {
      return true;
    }

    return false;
  }

  String _descripcionMovimiento(Map<String, dynamic> movimiento) {
    final descripcion = _textoCampo(movimiento, [
      'descripcion',
      'detalle',
      'concepto',
      'observacion',
      'mensaje',
    ]);

    if (descripcion.isNotEmpty &&
        descripcion.toLowerCase() != 'movimiento de billetera') {
      return descripcion;
    }

    final tipo = _textoCampo(movimiento, [
      'tipo_transaccion',
      'tipo',
      'tipo_movimiento',
      'clase',
    ]).toLowerCase();

    final metodoPago = _textoCampo(movimiento, [
      'metodo_pago',
      'metodo',
      'forma_pago',
    ]).toLowerCase();

    final referencia = _textoCampo(movimiento, [
      'referencia_pago',
      'referencia',
      'codigo_referencia',
    ]).toLowerCase();

    final textoCompleto = '$tipo $metodoPago $referencia';

    if (textoCompleto.contains('recarga')) {
      return 'Recarga de saldo';
    }

    if (textoCompleto.contains('uso_membresia') ||
        textoCompleto.contains('uso membresia') ||
        textoCompleto.contains('uso_membresía')) {
      return 'Uso de membresía';
    }

    if (textoCompleto.contains('compra_membresia') ||
        textoCompleto.contains('compra membresia') ||
        textoCompleto.contains('compra_membresía') ||
        textoCompleto.contains('membresia') ||
        textoCompleto.contains('membresía')) {
      return 'Consumo por compra de membresía';
    }

    if (textoCompleto.contains('pago_peaje') ||
        textoCompleto.contains('pago peaje') ||
        textoCompleto.contains('peaje')) {
      return 'Consumo por paso de peaje';
    }

    if (textoCompleto.contains('billetera')) {
      return 'Pago con billetera';
    }

    if (textoCompleto.contains('pago')) {
      return 'Pago realizado';
    }

    final monto = _montoMovimiento(movimiento);

    if (monto > 0 && _esMovimientoIngreso(movimiento)) {
      return 'Recarga de saldo';
    }

    if (monto > 0 && !_esMovimientoIngreso(movimiento)) {
      return 'Consumo de saldo';
    }

    return 'Movimiento de billetera';
  }

  double _montoMovimiento(Map<String, dynamic> movimiento) {
    final valor = movimiento['monto'] ??
        movimiento['valor'] ??
        movimiento['importe'] ??
        movimiento['amount'] ??
        0;

    return double.tryParse(valor.toString()) ?? 0;
  }

  String _formatearFechaMovimiento(dynamic valor) {
    if (valor == null) {
      return 'Sin fecha';
    }

    try {
      final fecha = DateTime.parse(valor.toString()).toLocal();

      String dosDigitos(int value) {
        return value.toString().padLeft(2, '0');
      }

      return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha
          .year} '
          '${dosDigitos(fecha.hour)}:${dosDigitos(fecha.minute)}';
    } catch (_) {
      return valor.toString();
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _cvvController.dispose();
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
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
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
    final colors = Theme
        .of(context)
        .colorScheme;

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
              'Las recargas se realizan con una tarjeta bancaria registrada. '
                  'No guardamos el CVV y el saldo se actualiza inmediatamente.',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
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
      style: Theme
          .of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _movimientosBilletera(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    final movimientosValidos = _movimientos
        .map(_normalizarMovimiento)
        .where(_movimientoTieneDatos)
        .where((movimiento) => !_esUsoDePaseMembresia(movimiento))
        .take(5)
        .toList();

    if (movimientosValidos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: colors.primary,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                'Sin movimientos',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aún no se han registrado recargas o consumos.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: movimientosValidos
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final movimiento = entry.value;

            final descripcion = _descripcionMovimiento(movimiento);
            final monto = _montoMovimiento(movimiento);
            final esIngreso = _esMovimientoIngreso(movimiento);
            final fecha = _fechaValorMovimiento(movimiento);

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: esIngreso
                          ? colors.secondary.withAlpha(22)
                          : colors.error.withAlpha(22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      esIngreso
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      color: esIngreso ? colors.secondary : colors.error,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    _formatearFechaMovimiento(fecha),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  trailing: Text(
                    '${esIngreso ? '+' : '-'}\$${monto.abs().toStringAsFixed(
                        2)}',
                    style: textTheme.titleSmall?.copyWith(
                      color: esIngreso ? colors.secondary : colors.error,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (index != movimientosValidos.length - 1)
                  Divider(
                    height: 1,
                    indent: 68,
                    endIndent: 14,
                    color: colors.outline.withAlpha(35),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _seccionRecarga(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;

    final Set<int> idsUsados = {};

    final List<DropdownMenuItem<int>> tarjetasItems = [];

    for (final tarjeta in _tarjetas) {
      final id = _obtenerTarjetaId(tarjeta);

      if (id == null) {
        continue;
      }

      if (idsUsados.contains(id)) {
        continue;
      }

      idsUsados.add(id);

      tarjetasItems.add(
        DropdownMenuItem<int>(
          value: id,
          child: Text(
            _textoTarjeta(tarjeta),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    }

    final bool seleccionExiste = tarjetasItems.any(
          (item) => item.value == _tarjetaSeleccionadaId,
    );

    final int? valorSeleccionado = seleccionExiste
        ? _tarjetaSeleccionadaId
        : tarjetasItems.isNotEmpty
        ? tarjetasItems.first.value
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_tarjetas.isEmpty || tarjetasItems.isEmpty) ...[
              Icon(
                Icons.credit_card_off,
                size: 46,
                color: colors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'No tienes tarjetas registradas',
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
                'Agrega una tarjeta bancaria para poder recargar tu billetera.',
                textAlign: TextAlign.center,
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _irATarjetas,
                  icon: const Icon(Icons.add_card),
                  label: const Text('Agregar tarjeta'),
                ),
              ),
            ] else
              ...[
                DropdownButtonFormField<int>(
                  value: valorSeleccionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tarjeta bancaria',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  items: tarjetasItems,
                  onChanged: _recargando
                      ? null
                      : (value) {
                    setState(() {
                      _tarjetaSeleccionadaId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Seleccione una tarjeta.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _CustomRechargeField(
                  controller: _montoController,
                  enabled: !_recargando,
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _cvvController,
                  enabled: !_recargando,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _recargando ? null : _irATarjetas,
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Administrar tarjetas'),
                  ),
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
                    onPressed: _recargando ? null : _recargar,
                    icon: _recargando
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colors.onPrimary,
                      ),
                    )
                        : const Icon(Icons.payment),
                    label: Text(
                      _recargando ? 'Procesando...' : 'Recargar con tarjeta',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _notaInformativa(context),
              ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppHeader(
        title: 'Billetera',
        subtitle: 'Saldo y movimientos',
        icon: Icons.account_balance_wallet,
        showBackButton: true,
        showRefresh: true,
        onRefresh: _cargarBilletera,
        showNotifications: true,
        showLogout: false,
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
                  _seccionTitulo('Movimientos'),
                  const SizedBox(height: 12),
                  _movimientosBilletera(context),
                  const SizedBox(height: 24),
                  _seccionTitulo('Recargar saldo'),
                  const SizedBox(height: 12),
                  _seccionRecarga(context),
                ],
              ),
            ),
          ),
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