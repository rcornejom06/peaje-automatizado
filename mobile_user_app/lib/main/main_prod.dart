import '../core/config/app_config.dart';
import '../main.dart';

/// Entrypoint de PRODUCCIÓN. Compilar con:
///   make build-apk flavor=prod
Future<void> main() => bootstrap(Environment.prod);
