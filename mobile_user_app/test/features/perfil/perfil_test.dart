import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_user_app/features/perfil/data/perfil.dart';

void main() {
  group('Perfil.fromJson', () {
    test('lee datos anidados en "usuario"', () {
      final p = Perfil.fromJson({
        'usuario': {
          'username': 'jdoe',
          'first_name': 'Juan',
          'last_name': 'Perez',
          'email': 'juan@mail.com',
        },
        'cedula': '0102030405',
        'telefono': '0987654321',
      });

      expect(p.username, 'jdoe');
      expect(p.nombre, 'Juan');
      expect(p.apellido, 'Perez');
      expect(p.correo, 'juan@mail.com');
      expect(p.cedula, '0102030405');
      expect(p.telefono, '0987654321');
    });

    test('lee datos anidados en "usuario_detalle"', () {
      final p = Perfil.fromJson({
        'usuario_detalle': {
          'username': 'mlopez',
          'first_name': 'Maria',
          'last_name': 'Lopez',
          'email': 'maria@mail.com',
        },
      });

      expect(p.username, 'mlopez');
      expect(p.nombre, 'Maria');
      expect(p.apellido, 'Lopez');
      expect(p.correo, 'maria@mail.com');
    });

    test('lee claves planas cuando no hay contenedor anidado', () {
      final p = Perfil.fromJson({
        'username': 'flat',
        'first_name': 'Ana',
        'last_name': 'Ruiz',
        'email': 'ana@mail.com',
        'cedula': '123',
        'telefono': '456',
      });

      expect(p.username, 'flat');
      expect(p.nombre, 'Ana');
      expect(p.apellido, 'Ruiz');
      expect(p.correo, 'ana@mail.com');
    });

    test('usa respaldos nombre/apellido/correo en español', () {
      final p = Perfil.fromJson({
        'nombre': 'Pedro',
        'apellido': 'Gomez',
        'correo': 'pedro@mail.com',
      });

      expect(p.nombre, 'Pedro');
      expect(p.apellido, 'Gomez');
      expect(p.correo, 'pedro@mail.com');
    });

    test('campos ausentes quedan como cadena vacía', () {
      final p = Perfil.fromJson({});

      expect(p.username, '');
      expect(p.nombre, '');
      expect(p.apellido, '');
      expect(p.correo, '');
      expect(p.cedula, '');
      expect(p.telefono, '');
    });

    test('prioriza el contenedor "usuario" sobre las claves planas', () {
      final p = Perfil.fromJson({
        'usuario': {'first_name': 'Anidado'},
        'first_name': 'Plano',
      });

      expect(p.nombre, 'Anidado');
    });
  });
}
