bool validarCedulaEcuatoriana(String cedula) {
  cedula = cedula.trim();

  if (cedula.length != 10) return false;

  if (!RegExp(r'^\d{10}$').hasMatch(cedula)) return false;

  // Evita cédulas repetidas tipo 0000000000
  if (RegExp(r'^(\d)\1{9}$').hasMatch(cedula)) return false;

  final provincia = int.tryParse(cedula.substring(0, 2));
  final tercerDigito = int.tryParse(cedula.substring(2, 3));

  if (provincia == null || provincia < 1 || provincia > 24) {
    return false;
  }

  if (tercerDigito == null || tercerDigito >= 6) {
    return false;
  }

  final coeficientes = [2, 1, 2, 1, 2, 1, 2, 1, 2];
  int suma = 0;

  for (int i = 0; i < 9; i++) {
    int valor = int.parse(cedula[i]) * coeficientes[i];

    if (valor >= 10) {
      valor -= 9;
    }

    suma += valor;
  }

  int digitoVerificador = int.parse(cedula[9]);
  int resultado = 10 - (suma % 10);

  if (resultado == 10) {
    resultado = 0;
  }

  return resultado == digitoVerificador;
}