/// Perfil del usuario autenticado.
///
/// El backend puede devolver los datos del usuario anidados en `usuario` o en
/// `usuario_detalle`, o bien en claves planas. Toda esa resolución vive aquí
/// (antes estaba repetida y "adivinada" dentro de las pantallas).
class Perfil {
  const Perfil({
    required this.username,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.cedula,
    required this.telefono,
  });

  final String username;
  final String nombre; // first_name
  final String apellido; // last_name
  final String correo; // email
  final String cedula;
  final String telefono;

  factory Perfil.fromJson(Map<String, dynamic> json) {
    // Combina los posibles contenedores del usuario (usuario / usuario_detalle),
    // dando prioridad al primero que traiga cada campo.
    final usuario = <String, dynamic>{};
    for (final clave in const ['usuario', 'usuario_detalle']) {
      final valor = json[clave];
      if (valor is Map) {
        valor.forEach((k, v) {
          usuario.putIfAbsent(k.toString(), () => v);
        });
      }
    }

    return Perfil(
      username: _primerNoVacio([
        usuario['username'],
        json['usuario_username'],
        json['username'],
      ]),
      nombre: _primerNoVacio([
        usuario['first_name'],
        json['first_name'],
        json['nombre'],
      ]),
      apellido: _primerNoVacio([
        usuario['last_name'],
        json['last_name'],
        json['apellido'],
      ]),
      correo: _primerNoVacio([
        usuario['email'],
        json['email'],
        json['correo'],
      ]),
      cedula: _primerNoVacio([json['cedula'], usuario['cedula']]),
      telefono: _primerNoVacio([json['telefono'], usuario['telefono']]),
    );
  }

  /// Devuelve el primer valor no nulo/no vacío como texto, o `''` si no hay.
  static String _primerNoVacio(List<Object?> candidatos) {
    for (final candidato in candidatos) {
      if (candidato != null && candidato.toString().trim().isNotEmpty) {
        return candidato.toString();
      }
    }
    return '';
  }
}
