import '../core/config/app_config.dart';
import '../main.dart';

/// Entrypoint de DESARROLLO. Compilar con:
///   make build-apk flavor=dev
Future<void> main() => bootstrap(Environment.dev);
