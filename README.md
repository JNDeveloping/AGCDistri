# AGC Distribuidora

Base profesional de app móvil (Flutter) + API (Node.js/Express) con PostgreSQL.

## Stack
- Mobile: Flutter + Cubit + GoRouter + Dio + Secure Storage
- Backend: Node.js + Express + JWT + bcryptjs + Zod
- Base de datos: PostgreSQL

---

## Tutorial paso a paso (puesta en marcha)

### 1) Requisitos previos
Instalá en tu máquina:
- Node.js 20+
- npm 10+
- PostgreSQL 14+
- Flutter SDK 3.3+
- Un emulador Android/iOS o dispositivo físico

### 2) Setup backend
```bash
cd backend
cp .env.example .env
npm install
npm run migrate
npm run seed
npm run dev
```

> `migrate` y `seed` son cross-platform (Windows/macOS/Linux).
> La API usa `DATABASE_URL` si existe; si no, usa `DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME`.
> El backup previo a migrar es opcional y se habilita con `BACKUP_BEFORE_MIGRATE=true`.

### 3) Setup mobile
```bash
cd mobile
cp .env.example .env
flutter pub get
flutter run
```

---

## Endpoints principales

### Auth
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`

### Clientes
- `GET /api/v1/clientes`
- `GET /api/v1/clientes/:id`
- `POST /api/v1/clientes`
- `PUT /api/v1/clientes/:id`
- `PATCH /api/v1/clientes/:id/deactivate`

### Productos
- `GET /api/v1/productos`
- `GET /api/v1/productos/:id`
- `POST /api/v1/productos`
- `PUT /api/v1/productos/:id`
- `PATCH /api/v1/productos/:id/deactivate`

---

## Permisos por rol
- `admin`: acceso total (incluye alta/edición/desactivación de productos)
- `vendedor`: lectura de productos y uso comercial en pedidos
- `repartidor`: lectura básica de productos para entregas

## Seeds de prueba
### Usuarios
- `admin@agc.local` / `Admin123!`
- `vendedor@agc.local` / `Admin123!`
- `repartidor@agc.local` / `Admin123!`

### Productos
- `PRD-0001` Aceite de Girasol 900ml
- `PRD-0002` Lavandina Tradicional

---

## Preparado para módulo pedidos
Los productos quedan listos para enlazarse por `product_id` con futuros módulos de:
- pedidos/carrito de venta
- promociones
- listas de precios por cliente/zona
- control de stock y sugerencias de reposición
- compras a proveedores

## Troubleshooting
- Error `No existe la relacion products`:
  1. Verificá `DATABASE_URL` en `backend/.env`.
  2. Ejecutá migraciones: `npm run migrate`.
  3. Si querés datos iniciales: `npm run seed`.

---

## Migraciones seguras (sin pérdida de datos)

### Principios del sistema
- Las migraciones son **incrementales y no destructivas**.
- Se bloquean operaciones peligrosas como `DROP TABLE`, `DROP DATABASE`, `TRUNCATE` y `DELETE FROM`.
- Se registra historial en la tabla `schema_migrations`.
- Cada migración se ejecuta una sola vez por nombre de archivo.
- Si una migración ya ejecutada cambia su contenido, el runner falla y exige crear una migración nueva.

### Comandos disponibles (backend)
```bash
npm run backup     # backup manual de PostgreSQL en backend/backups/
npm run migrate    # migraciones seguras (solo pendientes)
npm run seed       # datos iniciales sin borrar datos existentes
npm run reset:dev  # SOLO desarrollo, requiere confirmación manual
```

### Qué hace cada comando
- `npm run migrate`:
  - aplica `.sql` pendientes en `src/database/migrations`;
  - registra ejecución en `schema_migrations`.
  - podés activar backup previo con `BACKUP_BEFORE_MIGRATE=true`.
  - en Windows, si `pg_dump` no está en `PATH`, podés definir `PG_DUMP_BIN` en `backend/.env` con la ruta completa al ejecutable.
- `npm run seed`:
  - aplica seeds de `src/database/seeds` sin borrar datos existentes;
  - usa `INSERT ... ON CONFLICT DO NOTHING`.
- `npm run reset:dev`:
  - es destructivo y está bloqueado fuera de `development`;
  - exige confirmación explícita: `CONFIRM_RESET_DEV=true`.

### Restaurar un backup
1. Elegí un archivo de `backend/backups/backup_YYYY-MM-DD_HHMMSS.sql`.
2. Restaurá con:
   ```bash
   psql "$DATABASE_URL" -f backend/backups/backup_YYYY-MM-DD_HHMMSS.sql
   ```

### Comandos/procesos a evitar con datos reales
- No usar `DROP TABLE`, `DROP DATABASE`, `TRUNCATE`, ni borrados masivos.
- No usar scripts de reseteo en entornos reales.
- No editar migraciones ya ejecutadas: crear una migración nueva incremental.

### Cómo agregar una migración nueva de forma segura
1. Crear archivo secuencial en `backend/src/database/migrations` (ej. `009_add_x.sql`).
2. Usar operaciones incrementales (`CREATE ... IF NOT EXISTS`, `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`).
3. Evitar operaciones destructivas; si fuese estrictamente necesario, hacerlo sólo para desarrollo y con confirmación manual.

---

## Deploy en Railway (backend)

### 1) Crear servicio
1. Crear proyecto en Railway.
2. Conectar este repositorio GitHub.
3. Seleccionar el directorio `backend` como servicio (o configurar el root del servicio en `backend`).

### 2) Agregar PostgreSQL
1. En Railway, agregar plugin PostgreSQL.
2. Railway inyecta `DATABASE_URL` automáticamente (preferida por la API).

### 3) Variables recomendadas
Configurar al menos:
- `NODE_ENV=production`
- `PORT=4000` (Railway lo sobreescribe dinámicamente cuando corresponde)
- `DATABASE_URL` (provista por Railway)
- `JWT_SECRET`
- `JWT_EXPIRES_IN=7d`
- `CORS_ORIGIN=https://tu-frontend.app` (o lista separada por coma)

Opcionales:
- `DB_SSL=true`
- `DB_SSL_REJECT_UNAUTHORIZED=false`
- `BACKUP_BEFORE_MIGRATE=false`

### 4) Migraciones en Railway
Ejecutar en consola del servicio:
```bash
npm run migrate
```

### 5) Deploy y verificación
Railway usa `railway.json` con:
- build: `NIXPACKS`
- start: `npm start`

Luego verificar:
```bash
curl https://<tu-dominio>.up.railway.app/health
```

Respuesta esperada:
```json
{
  "status": "ok",
  "service": "backend",
  "timestamp": "2026-01-01T00:00:00.000Z",
  "database": "connected"
}
```
