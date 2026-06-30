# Sistema Inteligente de Peaje Automatizado

Plataforma inteligente para la gestión automatizada de peajes mediante reconocimiento de placas vehiculares, pagos digitales, membresías por pases, billetera virtual, monitoreo de pasos, alertas de seguridad vehicular y administración web.

## Descripción general

El proyecto propone el desarrollo de una plataforma inteligente de peaje automatizado que optimiza el cobro vehicular mediante reconocimiento de placas e integra funcionalidades de pagos digitales, gestión móvil, validación administrativa de vehículos, seguridad vehicular y monitoreo de eventos en tiempo real.

El sistema permite que los usuarios registren sus vehículos, adjunten documentos de respaldo para validación administrativa y gestionen sus pagos mediante una billetera digital integrada. Además, pueden adquirir paquetes de pases, los cuales permanecen activos hasta agotar el número de viajes disponibles.

Cuando una cámara LPR detecta una placa, el backend registra automáticamente el paso vehicular. Si el vehículo se encuentra aprobado, el sistema procesa el cobro mediante membresía o billetera digital. Si el vehículo está en revisión, rechazado o no registrado, el sistema registra el paso sin ejecutar cobro automático.

También incluye un módulo de seguridad vehicular que permite a los usuarios reportar vehículos robados adjuntando documentación de respaldo. Si un vehículo con aviso activo es detectado por un peaje conectado, el sistema genera una alerta automática, registra la ubicación del peaje y facilita la trazabilidad del vehículo para que el operador pueda derivar la información a la autoridad competente.

## Objetivos del sistema

* Automatizar el registro de pasos vehiculares mediante reconocimiento de placas.
* Reducir tiempos de espera en peajes.
* Digitalizar el cobro mediante billetera virtual y paquetes de pases.
* Permitir la validación administrativa de vehículos registrados por usuarios.
* Registrar evidencias documentales para aprobar o rechazar vehículos.
* Generar alertas automáticas ante vehículos reportados como robados.
* Registrar ubicación, historial y trazabilidad de pasos vehiculares.
* Ofrecer una app móvil para usuarios y un panel web administrativo.

## Módulos principales

### 1. Backend Django REST Framework

El backend centraliza la lógica de negocio del sistema.

Incluye los siguientes módulos:

* Usuarios y perfiles.
* Vehículos y categorías.
* Peajes, cámaras y pasos vehiculares.
* Pagos, billetera y transacciones.
* Membresías o paquetes de pases.
* Seguridad vehicular.
* Notificaciones.
* Auditoría.
* Reportes.

Tecnologías principales:

* Python
* Django
* Django REST Framework
* PostgreSQL
* Docker
* JWT Authentication
* drf-spectacular

### 2. Servidor LPR / Cámara USB

Servidor independiente encargado de procesar imágenes de cámara y detectar placas vehiculares.

Tecnologías:

* Flask
* OpenCV
* Tesseract OCR
* Python
* Cámara USB o fuente de video

Funciones:

* Captura de video.
* Detección de placa.
* Limpieza de texto OCR.
* Envío automático de placa detectada al backend.
* Consulta de última detección.
* Historial de detecciones.
* Stream de video para monitoreo.

### 3. Frontend administrativo React

Panel web para administración y monitoreo del sistema.

Funciones principales:

* Gestión de usuarios.
* Gestión de vehículos.
* Revisión de vehículos registrados.
* Aprobación o rechazo de vehículos.
* Visualización de documentos de respaldo.
* Monitoreo de reconocimiento de placas.
* Gestión de alertas de seguridad.
* Reportes.
* Auditoría.

Tecnologías:

* React
* Vite
* Axios
* Tailwind CSS
* JWT

### 4. App móvil Flutter

Aplicación móvil destinada a los usuarios finales.

Funciones principales:

* Registro e inicio de sesión.
* Visualización de perfil.
* Registro de vehículos.
* Carga de documento de respaldo del vehículo.
* Consulta del estado del vehículo: En revisión, Aprobado o Rechazado.
* Consulta de billetera.
* Recarga de saldo.
* Compra de paquetes de pases.
* Consulta de membresía activa.
* Historial de pasos.
* Reporte de vehículo robado.
* Consulta de alertas de seguridad.

Tecnologías:

* Flutter
* Dart
* HTTP
* Shared Preferences
* File Picker

## Flujo principal del sistema

### Registro y validación de vehículos

1. El usuario registra su vehículo desde la app móvil.
2. Adjunta un documento de respaldo, como matrícula, cédula, autorización o documento legal.
3. El vehículo queda con estado `En revisión`.
4. El administrador revisa el documento desde el panel web.
5. El administrador puede aprobar o rechazar el vehículo.
6. Solo los vehículos aprobados pueden usar cobro automático en peajes.

Estados de revisión:

* `en_revision`: Vehículo pendiente de validación.
* `aprobado`: Vehículo validado por administración.
* `rechazado`: Vehículo rechazado por documentación incorrecta o inconsistente.

### Cobro automático de peaje

1. La cámara detecta una placa.
2. El servidor LPR envía la placa al backend.
3. Django busca el vehículo asociado.
4. Si el vehículo existe y está aprobado, se registra el paso y se procesa el cobro.
5. El sistema intenta cobrar primero mediante membresía o paquete de pases.
6. Si no hay pases disponibles, intenta cobrar mediante billetera.
7. Si no hay saldo suficiente, el paso queda pendiente.
8. Si el vehículo no está aprobado, el paso se registra sin cobro automático.

### Membresías / paquetes de pases

El sistema utiliza paquetes de pases sin fecha de caducidad.

Ejemplo:

* Plan de 15 pases.
* Plan de 30 pases.
* Plan de 50 pases.

Reglas:

* El usuario compra un plan usando su billetera.
* Los pases quedan disponibles hasta agotarse.
* No existe fecha de vencimiento.
* Cada paso aprobado consume un pase.
* Cuando los pases llegan a cero, la membresía pasa a estado vencida.

### Seguridad vehicular

1. El usuario reporta un vehículo como robado.
2. Adjunta documentación de respaldo, como denuncia o comprobante.
3. El aviso queda activo en el sistema.
4. Cuando una cámara detecta la placa del vehículo reportado, el backend genera una alerta automática.
5. Se registra el peaje, ubicación, fecha, hora y estado de seguridad.
6. El operador puede revisar la alerta y derivar la información a la autoridad competente.

## Funcionalidades implementadas

### Usuarios

* Registro de usuarios.
* Inicio de sesión con JWT.
* Gestión de perfil.
* Roles: administrador, operador y usuario.
* Creación automática de perfil y billetera.

### Vehículos

* Registro de vehículos por usuario.
* Carga de documento de respaldo.
* Estados de revisión.
* Aprobación y rechazo administrativo.
* Búsqueda por placa para revisión.
* Validación para permitir cobro solo a vehículos aprobados.

### Peajes y cámaras

* Registro de peajes.
* Registro de cámaras.
* Asociación cámara-peaje.
* Detección automática de placas.
* Registro de pasos vehiculares.
* Prevención de duplicados recientes.

### Pagos

* Billetera digital por usuario.
* Recarga de saldo.
* Transacciones.
* Pago automático de peaje con billetera.
* Compra de paquetes de pases.

### Membresías / paquetes de pases

* Planes de pases.
* Compra de membresía desde billetera.
* Membresías sin fecha de caducidad.
* Consumo automático de pases.
* Consulta de membresía activa.

### Seguridad

* Reporte de vehículo robado.
* Carga de denuncia o respaldo.
* Alertas automáticas por detección LPR.
* Registro de ubicación del peaje.
* URL de Google Maps.
* Estados de alerta.
* Historial de seguridad.

### Reportes

* Resumen general.
* Recaudación.
* Pasos por peaje.
* Alertas.
* Vehículos detectados.
* Uso de membresías.

### Auditoría

* Registro de acciones importantes.
* Historial de usuario.
* Resumen de auditoría.
* Registro de eventos LPR y seguridad.

## Tecnologías utilizadas

### Backend

* Python
* Django
* Django REST Framework
* PostgreSQL
* Docker
* Simple JWT
* drf-spectacular

### Reconocimiento de placas

* Flask
* OpenCV
* Tesseract OCR
* Python

### Frontend web

* React
* Vite
* Axios
* Tailwind CSS

### Aplicación móvil

* Flutter
* Dart
* HTTP
* Shared Preferences
* File Picker

### Base de datos

* PostgreSQL

## Estructura general del proyecto

```text
peaje-automatizado/
├── backend/
│   ├── apps/
│   │   ├── usuarios/
│   │   ├── vehiculos/
│   │   ├── peajes/
│   │   ├── pagos/
│   │   ├── membresias/
│   │   ├── seguridad/
│   │   ├── notificaciones/
│   │   ├── auditoria/
│   │   └── reportes/
│   └── config/
├── frontend-admin/
├── mobile_user_app/
├── camera-usb-server/
├── docker-compose.dev.yml
└── README.md
```

## Instalación y ejecución

### 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd peaje-automatizado
```

### 2. Levantar backend con Docker

```powershell
cd F:\peaje-automatizado
docker compose -f docker-compose.dev.yml up -d
```

Verificar servicios:

```powershell
docker compose -f docker-compose.dev.yml ps
```

Ejecutar migraciones:

```powershell
docker compose -f docker-compose.dev.yml exec backend python manage.py makemigrations
docker compose -f docker-compose.dev.yml exec backend python manage.py migrate
```

Verificar backend:

```powershell
docker compose -f docker-compose.dev.yml exec backend python manage.py check
```

Backend disponible en:

```text
http://localhost:8000
```

### 3. Ejecutar frontend administrativo

```powershell
cd F:\peaje-automatizado\frontend-admin
npm install
npm run dev
```

Frontend disponible en:

```text
http://localhost:5173
```

### 4. Ejecutar app móvil Flutter

```powershell
cd F:\peaje-automatizado\mobile_user_app

flutter run
```

Para emulador Android usar:

```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

Para celular físico usar la IP de la PC:

```dart
static const String baseUrl = 'http://192.168.X.X:8000/api';
```

### 5. Ejecutar servidor LPR

```powershell
cd F:\peaje-automatizado\camera-usb-server
.\venv\Scripts\activate
python app.py
```

Servidor disponible en:

```text
http://localhost:5001
```

Endpoints principales del servidor LPR:

```text
GET /video_feed
GET /last_detection
GET /detections
GET /health
POST /reset_camera
```

## Endpoints principales del backend

### Autenticación

```text
POST /api/auth/token/
POST /api/auth/token/refresh/
```

### Usuarios

```text
POST /api/usuarios/usuarios/registro/
GET /api/usuarios/perfiles/mi-perfil/
PATCH /api/usuarios/perfiles/actualizar-mi-perfil/
```

### Vehículos

```text
GET /api/vehiculos/categorias/
GET /api/vehiculos/vehiculos/
POST /api/vehiculos/vehiculos/registrar-propio/
GET /api/vehiculos/vehiculos/buscar-revision/?placa=AAC0123
PATCH /api/vehiculos/vehiculos/{id}/aprobar/
PATCH /api/vehiculos/vehiculos/{id}/rechazar/
```

### Peajes

```text
GET /api/peajes/peajes/
GET /api/peajes/camaras/
GET /api/peajes/pasos-peaje/
POST /api/peajes/pasos-peaje/detectar-placa/
```

### Pagos

```text
GET /api/pagos/billeteras/mi-billetera/
POST /api/pagos/billeteras/recargar/
```

### Membresías

```text
GET /api/membresias/planes/
GET /api/membresias/membresias/
POST /api/membresias/membresias/comprar/
GET /api/membresias/membresias/mi-membresia-activa/
```

### Seguridad

```text
POST /api/seguridad/avisos-robo/crear-aviso/
PATCH /api/seguridad/avisos-robo/{id}/cerrar/
PATCH /api/seguridad/avisos-robo/{id}/cancelar/
GET /api/seguridad/alertas/
PATCH /api/seguridad/alertas/{id}/marcar-revisada/
PATCH /api/seguridad/alertas/{id}/derivar-autoridad/
PATCH /api/seguridad/alertas/{id}/cerrar/
PATCH /api/seguridad/alertas/{id}/descartar/
```

### Reportes

```text
GET /api/reportes/resumen/
GET /api/reportes/recaudacion/
GET /api/reportes/pasos-por-peaje/
GET /api/reportes/alertas/
GET /api/reportes/vehiculos-detectados/
GET /api/reportes/uso-membresias/
```

### Auditoría

```text
GET /api/auditoria/historial/
GET /api/auditoria/historial/resumen/
```

## Variables de entorno recomendadas

### Frontend Admin

Archivo:

```text
frontend-admin/.env
```

Ejemplo:

```env
VITE_API_URL=http://localhost:8000/api
VITE_CAMERA_SERVER_URL=http://localhost:5001
```

### Servidor LPR

Archivo:

```text
camera-usb-server/.env
```

Ejemplo:

```env
DJANGO_USERNAME=admin
DJANGO_PASSWORD=CAMBIAR
DJANGO_AUTH_URL=http://localhost:8000/api/auth/token/
DJANGO_API_URL=http://localhost:8000/api/peajes/pasos-peaje/detectar-placa/
DJANGO_CAMARA_ID=1
CAMERA_INDEX=1
```

## Consideraciones de seguridad

* No subir archivos `.env` reales al repositorio.
* No subir carpetas `venv`, `node_modules`, `build` ni archivos temporales.
* Proteger tokens JWT.
* No exponer credenciales en logs.
* Validar documentos de respaldo antes de aprobar vehículos.
* El sistema no reemplaza a las autoridades competentes.
* La retención o recuperación de vehículos debe ser gestionada por organismos autorizados.
* El sistema genera alertas y trazabilidad para apoyar el proceso de seguridad.

## Estado actual del cumplimiento funcional

### Cumplido

* Reconocimiento de placas.
* Registro automático de pasos.
* Cobro por billetera.
* Compra de paquetes de pases.
* Membresías sin fecha de caducidad.
* App móvil para usuarios.
* Panel web administrativo.
* Reporte de robo.
* Alertas automáticas.
* Ubicación del peaje.
* Auditoría.
* Reportes.
* Validación administrativa de vehículos.
* Documento de respaldo para vehículos.

### Parcial

* Pago manual de pasos pendientes.
* Dashboard avanzado de monitoreo en tiempo real.
* Trazabilidad visual completa en mapa.
* Reporte inmediato por zonas de alto riesgo.

### Pendiente

* Captura automática de evidencia fotográfica del vehículo y conductor.
* Notificación directa a autoridades mediante integración oficial.
* Integración oficial con ANT, CTE, ECU 911 u otra entidad competente.
* Protocolo automatizado de retención, el cual debe depender de autoridades autorizadas.

## Comandos útiles

### Backend

```powershell
cd F:\peaje-automatizado
docker compose -f docker-compose.dev.yml up -d
docker compose -f docker-compose.dev.yml ps
docker compose -f docker-compose.dev.yml logs backend --tail=100
docker compose -f docker-compose.dev.yml exec backend python manage.py check
docker compose -f docker-compose.dev.yml exec backend python manage.py makemigrations
docker compose -f docker-compose.dev.yml exec backend python manage.py migrate
docker compose -f docker-compose.dev.yml restart backend
```

### Frontend Admin

```powershell
cd F:\peaje-automatizado\frontend-admin
npm install
npm run dev
```

### Flutter

```powershell
cd F:\peaje-automatizado\mobile_user_app
flutter pub get
flutter analyze
flutter run
```

### Servidor LPR

```powershell
cd F:\peaje-automatizado\camera-usb-server
.\venv\Scripts\activate
python app.py
```

## Autor

Proyecto desarrollado como sistema inteligente de peaje automatizado con integración de pagos digitales, reconocimiento de placas y seguridad vehicular.

Autor: Roger Andres Cornejo Mendez
