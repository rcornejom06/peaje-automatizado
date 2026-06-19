# Sistema Inteligente de Peaje Automatizado

Sistema web y móvil para la gestión automatizada de peajes, pagos digitales, membresías por pases, detección de placas, alertas de seguridad y monitoreo administrativo.

El proyecto está desarrollado como caso de estudio de Ingeniería de Software y tiene como finalidad simular una solución tecnológica para automatizar el paso por peajes, mejorar el control vehicular y apoyar la generación de alertas ante vehículos con aviso interno de robo.

---

## Descripción del proyecto

El sistema permite registrar usuarios, vehículos, categorías vehiculares por número de ejes, billeteras digitales, membresías, pasos por peaje, alertas de seguridad, ubicaciones de detección y reportes administrativos.

La solución contempla tres tipos principales de usuarios:

* Usuario
* Operador
* Administrador

El usuario puede registrarse desde la aplicación móvil, registrar sus vehículos, recargar saldo, comprar membresías y generar avisos internos de vehículo robado.

El operador puede monitorear pasos por peaje, simular detecciones, revisar alertas y registrar ubicaciones de detección.

El administrador puede gestionar usuarios, operadores, peajes, cámaras, planes de membresía, categorías vehiculares y reportes generales.

---

## Tecnologías utilizadas

### Backend

* Python
* Django
* Django REST Framework
* PostgreSQL
* Simple JWT
* drf-spectacular
* Docker
* Docker Compose

### Frontend web administrativo

* React

### Aplicación móvil

* Flutter

### Otros servicios previstos

* OpenCV para reconocimiento de placas
* Google Maps para visualización de ubicaciones
* Pasarela de pagos digital simulada o integrada
* Cámaras ANPR simuladas

---

## Estructura general del proyecto

```text
peaje-inteligente/
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
│   ├── config/
│   │   ├── settings/
│   │   │   ├── base.py
│   │   │   ├── dev.py
│   │   │   └── prod.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── requirements/
│   │   ├── base.txt
│   │   ├── dev.txt
│   │   └── prod.txt
│   └── manage.py
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── .env.dev
├── .env.prod
└── README.md
```

---

## Requisitos previos

Antes de ejecutar el proyecto se requiere tener instalado:

* Docker Desktop
* Docker Compose
* Git
* Navegador web
* Visual Studio Code u otro editor de código

---

## Instalación del proyecto

Clonar el repositorio:

```bash
git clone URL_DEL_REPOSITORIO
cd peaje-inteligente
```

Levantar los contenedores en ambiente de desarrollo:

```bash
docker compose -f docker-compose.dev.yml up -d
```

Verificar que los contenedores estén activos:

```bash
docker ps
```

---

## Migraciones de base de datos

Crear migraciones:

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py makemigrations
```

Aplicar migraciones:

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py migrate
```

Verificar el estado del proyecto:

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py check
```

---

## Crear superusuario

El primer usuario administrador del sistema se crea desde consola:

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py createsuperuser
```

Este usuario tendrá acceso al panel administrativo de Django.

---

## Accesos principales

### Panel administrativo Django

```text
http://localhost:8000/admin/
```

### Documentación Swagger

```text
http://localhost:8000/api/docs/
```

### Esquema OpenAPI

```text
http://localhost:8000/api/schema/
```

---

## Roles del sistema

### Usuario

Puede realizar las siguientes acciones:

* Registrarse desde la app móvil
* Iniciar sesión
* Consultar y actualizar su perfil
* Registrar vehículos propios
* Consultar categorías vehiculares
* Recargar billetera
* Comprar membresías
* Consultar sus transacciones
* Crear aviso interno de vehículo robado
* Consultar sus notificaciones
* Consultar su historial

### Operador

Puede realizar las siguientes acciones:

* Consultar vehículos registrados
* Consultar pasos por peaje
* Simular detección de paso por peaje
* Generar alertas por placa
* Revisar alertas
* Derivar alertas a autoridad
* Registrar ubicación de detección
* Consultar reportes operativos

### Administrador

Puede realizar las siguientes acciones:

* Gestionar usuarios
* Crear operadores
* Gestionar categorías vehiculares
* Gestionar peajes
* Gestionar cámaras
* Gestionar planes de membresía
* Consultar auditoría
* Consultar reportes generales
* Gestionar datos desde Django Admin

---

## Módulos principales

### Usuarios

Gestiona usuarios, perfiles y roles del sistema.

El registro de usuarios normales se realiza desde la API o desde la app móvil.

Endpoint principal:

```text
POST /api/usuarios/usuarios/registro/
```

Ejemplo:

```json
{
  "username": "usuario1",
  "email": "usuario1@email.com",
  "password": "Usuario12345",
  "first_name": "Usuario",
  "last_name": "Demo",
  "telefono": "0980000000",
  "cedula": "0912345678"
}
```

---

### Vehículos

Permite registrar vehículos asociados al usuario autenticado.

Cada vehículo pertenece a una categoría vehicular según su tipo y número de ejes.

Categorías utilizadas:

```text
Liviano 2 ejes - $1.00
Pesado 2 ejes - $2.00
Pesado 3 ejes - $3.00
Pesado 4 ejes - $4.00
Extrapesado 5 ejes - $5.00
Extrapesado 6 ejes - $6.00
```

Endpoint para registrar vehículo propio:

```text
POST /api/vehiculos/vehiculos/registrar-propio/
```

Ejemplo:

```json
{
  "placa": "ABC1234",
  "marca": "Toyota",
  "modelo": "Corolla",
  "color": "Blanco",
  "anio": 2020,
  "categoria": 1
}
```

---

### Pagos

Gestiona billeteras virtuales y transacciones.

El usuario puede recargar saldo en su billetera.

Endpoint:

```text
POST /api/pagos/billeteras/recargar/
```

Ejemplo:

```json
{
  "monto": "20.00",
  "metodo_pago": "PayPhone simulado",
  "referencia_pago": "REC-001"
}
```

---

### Membresías

Gestiona planes y membresías activas.

Las membresías funcionan mediante pases disponibles.

Ejemplo:

```text
Membresía mensual: $25.00
Pases incluidos: 30
Duración: 30 días
```

Cuando el usuario pasa por un peaje y tiene membresía activa, se descuenta un pase. Si no tiene membresía o ya no tiene pases disponibles, se cobra desde la billetera.

Endpoint para comprar membresía:

```text
POST /api/membresias/membresias/comprar/
```

Ejemplo:

```json
{
  "plan": 1
}
```

---

### Peajes

Gestiona peajes, cámaras y pasos por peaje.

El sistema permite simular el paso de un vehículo por un peaje mediante lectura de placa.

Endpoint:

```text
POST /api/peajes/pasos-peaje/simular/
```

Ejemplo:

```json
{
  "placa_detectada": "ABC1234",
  "peaje": 1,
  "camara": 1
}
```

Reglas de cobro:

```text
1. Si el vehículo tiene membresía activa y pases disponibles:
   - Se descuenta 1 pase.
   - No se descuenta saldo de billetera.

2. Si no tiene membresía activa:
   - Se cobra según la categoría del vehículo.
   - Se descuenta el valor desde la billetera.

3. Si no tiene saldo suficiente:
   - El pago queda como fallido.
```

---

### Seguridad

Gestiona avisos internos de vehículos robados, alertas y ubicaciones de detección.

El usuario puede registrar un aviso interno indicando que su vehículo fue reportado como robado ante la autoridad competente.

Importante:

```text
El sistema no reemplaza la denuncia formal.
El sistema no detiene vehículos.
El sistema solo registra avisos internos, detecta placas y genera alertas de apoyo.
La autoridad competente es quien actúa legalmente.
```

Endpoint para crear aviso interno:

```text
POST /api/seguridad/avisos-robo/crear-aviso/
```

Ejemplo:

```json
{
  "placa": "ABC1234",
  "numero_denuncia": "DEN-2026-001",
  "entidad_denuncia": "Fiscalía",
  "fecha_denuncia": "2026-06-18",
  "lugar_robo": "Milagro",
  "descripcion": "Vehículo reportado como robado por el propietario.",
  "latitud_robo": "-2.1345000",
  "longitud_robo": "-79.5948000"
}
```

Endpoint para generar alerta por placa:

```text
POST /api/seguridad/alertas/generar-por-placa/
```

Ejemplo:

```json
{
  "placa": "ABC1234",
  "peaje": 1
}
```

Endpoints de gestión de estados:

```text
PATCH /api/seguridad/avisos-robo/{id}/cerrar/
PATCH /api/seguridad/avisos-robo/{id}/cancelar/

PATCH /api/seguridad/alertas/{id}/marcar-revisada/
PATCH /api/seguridad/alertas/{id}/derivar-autoridad/
PATCH /api/seguridad/alertas/{id}/cerrar/
PATCH /api/seguridad/alertas/{id}/descartar/
```

---

### Notificaciones

Gestiona las notificaciones del usuario.

Endpoints principales:

```text
GET /api/notificaciones/notificaciones/mis-notificaciones/
GET /api/notificaciones/notificaciones/no-leidas/
PATCH /api/notificaciones/notificaciones/{id}/marcar-leida/
PATCH /api/notificaciones/notificaciones/marcar-todas-leidas/
```

---

### Auditoría

Registra acciones importantes del sistema.

Ejemplos de acciones auditadas:

```text
Registro de vehículo
Recarga de billetera
Compra de membresía
Pago de peaje
Uso de membresía
Pago fallido
Creación de aviso interno
Generación de alerta
Cierre de alerta
Cancelación de aviso
```

Endpoints:

```text
GET /api/auditoria/historial/mi-historial/
GET /api/auditoria/historial/por-modulo/?modulo=Seguridad
GET /api/auditoria/historial/por-usuario/?usuario=1
```

---

### Reportes

El sistema incluye endpoints de reportes para operadores y administradores.

Endpoints disponibles:

```text
GET /api/reportes/resumen/
GET /api/reportes/recaudacion/
GET /api/reportes/pasos-por-peaje/
GET /api/reportes/alertas/
GET /api/reportes/vehiculos-detectados/
GET /api/reportes/uso-membresias/
```

Filtros disponibles:

```text
?fecha_inicio=2026-06-01&fecha_fin=2026-06-30
?peaje=1
```

Ejemplo:

```text
GET /api/reportes/resumen/?fecha_inicio=2026-06-01&fecha_fin=2026-06-30
```

---

## Autenticación

El sistema utiliza JWT.

Obtener token:

```text
POST /api/auth/token/
```

Ejemplo:

```json
{
  "username": "usuario1",
  "password": "Usuario12345"
}
```

Respuesta esperada:

```json
{
  "refresh": "TOKEN_REFRESH",
  "access": "TOKEN_ACCESS"
}
```

Para consumir endpoints protegidos se debe enviar el token en el encabezado:

```text
Authorization: Bearer TOKEN_ACCESS
```

Refrescar token:

```text
POST /api/auth/token/refresh/
```

---

## Flujo de prueba recomendado

### 1. Crear superusuario

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py createsuperuser
```

### 2. Entrar al admin

```text
http://localhost:8000/admin/
```

### 3. Crear datos base desde Django Admin

Crear:

```text
Categorías vehiculares
Peajes
Cámaras
Planes de membresía
Operador
```

### 4. Registrar usuario normal desde API

```text
POST /api/usuarios/usuarios/registro/
```

### 5. Iniciar sesión con JWT

```text
POST /api/auth/token/
```

### 6. Registrar vehículo

```text
POST /api/vehiculos/vehiculos/registrar-propio/
```

### 7. Recargar billetera

```text
POST /api/pagos/billeteras/recargar/
```

### 8. Comprar membresía

```text
POST /api/membresias/membresias/comprar/
```

### 9. Simular paso por peaje

```text
POST /api/peajes/pasos-peaje/simular/
```

### 10. Crear aviso interno de vehículo robado

```text
POST /api/seguridad/avisos-robo/crear-aviso/
```

### 11. Simular detección de vehículo con aviso activo

```text
POST /api/peajes/pasos-peaje/simular/
```

### 12. Revisar alerta

```text
PATCH /api/seguridad/alertas/{id}/marcar-revisada/
```

### 13. Derivar alerta

```text
PATCH /api/seguridad/alertas/{id}/derivar-autoridad/
```

### 14. Cerrar alerta

```text
PATCH /api/seguridad/alertas/{id}/cerrar/
```

### 15. Consultar reportes

```text
GET /api/reportes/resumen/
```

---

## Comandos útiles

Levantar proyecto:

```bash
docker compose -f docker-compose.dev.yml up -d
```

Detener proyecto:

```bash
docker compose -f docker-compose.dev.yml down
```

Ver logs del backend:

```bash
docker compose -f docker-compose.dev.yml logs -f backend
```

Ejecutar migraciones:

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py migrate
```

Crear migraciones:

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py makemigrations
```

Entrar al shell de Django:

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py shell
```

Crear superusuario:

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py createsuperuser
```

Reiniciar backend:

```bash
docker compose -f docker-compose.dev.yml restart backend
```

Verificar errores:

```bash
docker compose -f docker-compose.dev.yml exec backend python manage.py check
```

---

## Flujo de seguridad del sistema

El flujo de seguridad está diseñado como apoyo al monitoreo, no como sustituto de procesos legales.

```text
1. El usuario realiza una denuncia formal ante la autoridad competente.
2. El usuario registra un aviso interno en la aplicación.
3. El sistema almacena el aviso asociado al vehículo.
4. Cuando el vehículo pasa por un peaje, el sistema detecta la placa.
5. Si la placa tiene aviso activo, se genera una alerta.
6. El sistema registra la ubicación del peaje.
7. El operador revisa la alerta.
8. El operador puede derivar la alerta a la autoridad competente.
9. El administrador u operador puede cerrar la alerta.
```

---

## Consideraciones legales

El sistema no debe ser interpretado como una herramienta oficial de recuperación vehicular.

El sistema:

```text
Registra avisos internos
Detecta placas
Genera alertas
Registra ubicaciones
Apoya el monitoreo operativo
```

El sistema no:

```text
Sustituye denuncias formales
Ordena detenciones
Recupera vehículos
Reemplaza a la autoridad competente
```

---

## Estado actual del proyecto

El backend incluye:

```text
Autenticación JWT
Gestión de usuarios
Gestión de perfiles
Roles
Vehículos
Categorías por ejes
Billetera virtual
Transacciones
Membresías por pases
Peajes
Cámaras
Pasos por peaje
Avisos internos de robo
Alertas de seguridad
Ubicaciones con Google Maps
Notificaciones
Auditoría
Reportes
Permisos por roles
Swagger
Docker
PostgreSQL
```

---

## Próximas mejoras

```text
Frontend web administrativo en React
Aplicación móvil en Flutter
Integración real con pasarela de pagos
Integración real con reconocimiento de placas ANPR
Dashboard gráfico
Exportación de reportes
Pruebas automatizadas
Despliegue en producción
```

---

## Autor

Proyecto académico desarrollado como caso de estudio para un sistema inteligente de peaje automatizado con pagos digitales, membresías y monitoreo de seguridad.
