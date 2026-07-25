# Refactor de arquitectura — mobile_user_app (ViaSmart)

- **Fecha:** 2026-07-22
- **Autor:** Cristhian Pin (con Claude)
- **Estado:** F0 en ejecución · F1/F2 planificadas

---

## 1. Contexto y estado actual

`mobile_user_app` ("Peaje Automatizado" / marca **ViaSmart**) es la app móvil Flutter
de usuario final de un sistema de peaje automatizado (contexto Ecuador). Consume un
backend **propio** Django REST + SimpleJWT (NO el Backoffice de Hey).

Auditoría inicial (2026-07-22) — deuda relevante:

| Área | Hallazgo |
|---|---|
| Control de versiones | No era repo git (sin historial). **Resuelto en F0.** |
| Estado | `provider` declarado pero **0 usos**; todo es `setState` en 21 pantallas. |
| Modelos | **1 solo modelo** (`ComprobantePaso`); el resto viaja como `Map<String,dynamic>`. |
| Pantallas | God-screens: `billetera_screen.dart` 1.248 líneas, y otras 800+. |
| Servicios | Sin DI; 25 sitios instancian `ApiService()`/`StorageService()` a mano. `VehiculoService` duplica el multipart en vez de usar `ApiService.postMultipart`. |
| Config | `baseUrl` hardcodeada a IP de dev; sin flavors/entornos. **Resuelto en F0.** |
| Red (release) | `INTERNET` solo en manifest debug/profile → release sin red. **Resuelto en F0.** |
| Seguridad | JWT (access+refresh) en `SharedPreferences` en claro. |
| Release | Firma con llave **debug**; `applicationId` default `com.example.mobile_user_app`. |
| Tests | Cero (ni carpeta `test/`). |

Lo que **sí** está bien y se conserva: esqueleto `core/features/shared`, `ApiService`
(refresh de token con single-flight, timeouts, manejo de errores), Firebase/FCM bien
cableado (`google-services.json` + plugin), nombres consistentes en español,
validación de cédula EC.

## 2. Objetivos y NO-objetivos

**Objetivos:** dejar la app **óptima, escalable y bien estructurada** pero **pragmática** —
buena arquitectura y funcional, sin sobre-ingeniería. Referencias: `hey-client` /
`hey-support` (Riverpod, feature-first), adaptadas y recortadas.

**NO-objetivos (YAGNI):** no migrar a Dio, no go_router, no Freezed/codegen, no
rediseñar la UI, no quitar features existentes, no multi-flavor complejo.

## 3. Arquitectura objetivo (decisiones)

- **Estado → Riverpod** (`flutter_riverpod`), **sin codegen**. Se elimina el `provider` sin usar.
- **Red → se conserva `http` + `ApiService`**. Todo pasa por `ApiService`; se elimina el
  multipart duplicado de `VehiculoService` (se añade soporte de PATCH multipart si hace falta).
- **Modelos → clases Dart inmutables con `fromJson`/`toJson`** por feature. Adiós a los
  `Map<String,dynamic>` en la UI.
- **Navegación → rutas nombradas centralizadas** (se mantiene el enfoque actual, ordenado).
- **Capas por feature:**
  - `data/` → modelos + `<feature>_repository.dart` (envuelve `ApiService`, devuelve objetos tipados).
  - `application/` → notifiers/providers Riverpod (solo donde hay estado real).
  - `view/` → pantallas + widgets del feature.
  - Compartido en `core/` (config, network, storage, theme, utils) y `shared/widgets/`.
- **Seguridad → `flutter_secure_storage`** para tokens; `SharedPreferences` solo para no-sensible.

## 4. Roadmap por fases

### F0 — Estabilizar (sin tocar arquitectura) — *en ejecución*
1. ✅ `git init` + commit baseline.
2. ✅ `INTERNET` en manifest `main` (red en release).
3. ✅ `baseUrl` por `--dart-define=API_BASE_URL` vía `AppConfig` (default = IP dev actual).
4. Verificar con `fvm flutter analyze` y `fvm flutter run` (en Android Studio).

### F1 — Seguridad y release
1. Migrar JWT a `flutter_secure_storage` (`StorageService` como fachada; API interna intacta).
2. Definir `applicationId` real (p. ej. `ec.viasmart.userapp`) — **requiere confirmación**.
3. Firma de release con keystore propio (lo genera/provee el dueño; se configura Gradle
   con `key.properties` fuera de git). **No** se usa la llave de Hey (proyecto externo).

### F2 — Arquitectura (incremental, **feature por feature**)
Orden sugerido (de menor a mayor riesgo): `perfil` → `vehiculos` → `billetera` →
`membresias` → `pasos` → `seguridad` → `notificaciones`.
Por cada feature: (a) modelos tipados + repository; (b) notifier Riverpod y quitar
lógica del widget; (c) partir la pantalla en widgets; (d) tests de repo/notifier.
Al final: `ProviderScope` en `main`, limpieza de `provider`, y test de `cedula_validator`.

## 5. Verificación

⚠️ En este entorno (sandbox) el toolchain Flutter/Gradle no corre de forma fiable
(`dart analyze` standalone da falsos positivos por SDK/paquete desalineados). La
verificación **en vivo** se hace en Android Studio con **FVM 3.41.9** (Dart 3.11.5):

```bash
fvm use 3.41.9            # pinnear la SDK del proyecto (crea .fvmrc)
fvm flutter pub get
fvm flutter analyze
fvm flutter run --dart-define=API_BASE_URL=http://172.20.10.2:8000/api
```

Cada fase se cierra solo cuando `flutter analyze` queda limpio y la app corre en device/emulador.

## 6. Riesgos / pendientes por confirmar
- `applicationId` definitivo y dominio de producción (`API_BASE_URL` prod).
- Keystore de release (lo aporta el dueño; nunca se commitea).
- iOS: el `.metadata` lo lista pero **no existe carpeta `ios/`**; definir si entra en alcance.
- El proyecto no está pineado a FVM (`.fvmrc` ausente) — se añade en F0/F1.
