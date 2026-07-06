def validar_cedula_ecuatoriana(cedula):
    if not cedula:
        return False

    cedula = str(cedula).strip()

    if len(cedula) != 10:
        return False

    if not cedula.isdigit():
        return False

    # Evita cédulas repetidas tipo 0000000000, 1111111111, etc.
    if len(set(cedula)) == 1:
        return False

    provincia = int(cedula[:2])
    tercer_digito = int(cedula[2])

    if provincia < 1 or provincia > 24:
        return False

    if tercer_digito >= 6:
        return False

    coeficientes = [2, 1, 2, 1, 2, 1, 2, 1, 2]
    suma = 0

    for i in range(9):
        valor = int(cedula[i]) * coeficientes[i]

        if valor >= 10:
            valor -= 9

        suma += valor

    digito_verificador = int(cedula[9])
    resultado = 10 - (suma % 10)

    if resultado == 10:
        resultado = 0

    return resultado == digito_verificador