class ComprobantePaso {
  final int idPaso;
  final String ticket;
  final String empresa;
  final String documento;
  final String placa;
  final String vehiculo;
  final String usuario;
  final String peaje;
  final String ciudad;
  final String ubicacion;
  final String camara;
  final String carril;
  final String categoria;
  final String tipoCliente;
  final String metodoPago;
  final String estadoPago;
  final String estadoSeguridad;
  final String valor;
  final String fechaHora;
  final String observacion;
  final String codigoQr;

  ComprobantePaso({
    required this.idPaso,
    required this.ticket,
    required this.empresa,
    required this.documento,
    required this.placa,
    required this.vehiculo,
    required this.usuario,
    required this.peaje,
    required this.ciudad,
    required this.ubicacion,
    required this.camara,
    required this.carril,
    required this.categoria,
    required this.tipoCliente,
    required this.metodoPago,
    required this.estadoPago,
    required this.estadoSeguridad,
    required this.valor,
    required this.fechaHora,
    required this.observacion,
    required this.codigoQr,
  });

  factory ComprobantePaso.fromJson(Map<String, dynamic> json) {
    return ComprobantePaso(
      idPaso: json['id_paso'] ?? 0,
      ticket: json['ticket']?.toString() ?? '',
      empresa: json['empresa']?.toString() ?? 'Sistema de Peaje Automatizado',
      documento: json['documento']?.toString() ?? 'Comprobante electrónico de peaje',
      placa: json['placa']?.toString() ?? 'Sin placa',
      vehiculo: json['vehiculo']?.toString() ?? 'No registrado',
      usuario: json['usuario']?.toString() ?? 'No registrado',
      peaje: json['peaje']?.toString() ?? 'Sin peaje',
      ciudad: json['ciudad']?.toString() ?? '',
      ubicacion: json['ubicacion']?.toString() ?? '',
      camara: json['camara']?.toString() ?? 'Sin cámara',
      carril: json['carril']?.toString() ?? 'Sin carril',
      categoria: json['categoria']?.toString() ?? 'Sin categoría',
      tipoCliente: json['tipo_cliente']?.toString() ?? 'Particular',
      metodoPago: json['metodo_pago']?.toString() ?? 'Sin método',
      estadoPago: json['estado_pago']?.toString() ?? 'pendiente',
      estadoSeguridad: json['estado_seguridad']?.toString() ?? 'normal',
      valor: json['valor']?.toString() ?? '0.00',
      fechaHora: json['fecha_hora']?.toString() ??
          json['fecha_generacion']?.toString() ??
          '',
      observacion: json['observacion']?.toString() ?? 'Sin observaciones.',
      codigoQr: json['codigo_qr']?.toString() ?? '',
    );
  }
}