import '../../env/env.dart';

/// Entornos soportados por la app.
enum Environment { dev, prod }

/// Configuración de entorno.
///
/// El entrypoint (`lib/main/main_dev.dart` o `lib/main/main_prod.dart`) fija el
/// entorno con [setEnvironment] antes de arrancar la app; el resto del código
/// solo lee [apiBaseUrl]. Los valores viven en `.env` y se inyectan en
/// compilación con envied (ver [Env]); se regeneran con `make build-env`.
class AppConfig {
  const AppConfig._();

  static Environment _environment = Environment.dev;

  /// Fija el entorno activo. Llamar una sola vez, en el entrypoint.
  static void setEnvironment(Environment environment) {
    _environment = environment;
  }

  static Environment get environment => _environment;

  /// URL base del API REST (incluye `/api`), según el entorno activo.
  static String get apiBaseUrl =>
      _environment == Environment.prod ? Env.productionEnv : Env.developEnv;
}
