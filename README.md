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

Verificá instalación:
```bash
node -v
npm -v
psql --version
flutter --version
```

### 2) Clonar y entrar al proyecto
```bash
git clone <URL_DEL_REPO>
cd AGCDistri
```

### 3) Levantar PostgreSQL y crear base de datos
Ejemplo local:
```bash
createdb agc_distribuidora
```

Si no tenés `createdb`, podés hacerlo desde `psql`:
```sql
CREATE DATABASE agc_distribuidora;
```

### 4) Configurar entorno del backend
```bash
cd backend
cp .env.example .env
```

Editá `.env` con tus valores reales, por ejemplo:
```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/agc_distribuidora
JWT_SECRET=tu_secreto_super_seguro
JWT_EXPIRES_IN=12h
CORS_ORIGIN=*
```

### 5) Instalar dependencias backend
```bash
npm install
```

### 6) Ejecutar migraciones y seeds
```bash
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/agc_distribuidora npm run db:migrate
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/agc_distribuidora npm run db:seed
```

### 7) Levantar API
```bash
npm run dev
```

API disponible en:
- `http://localhost:3000/api/v1`

Chequeo rápido:
```bash
curl http://localhost:3000/api/v1/health
```

### 8) Probar login rápido desde terminal
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@agc.local","password":"Admin123!"}'
```

Usuarios seed:
- `admin@agc.local` / `Admin123!`
- `vendedor@agc.local` / `Admin123!`
- `repartidor@agc.local` / `Admin123!`

### 9) Configurar entorno del mobile
En otra terminal:
```bash
cd mobile
cp .env.example .env
```

Configurar `API_BASE_URL` según tu entorno:
- Android Emulator: `http://10.0.2.2:3000/api/v1`
- iOS Simulator: `http://localhost:3000/api/v1`
- Dispositivo físico: `http://<IP_DE_TU_PC>:3000/api/v1`

### 10) Instalar dependencias y correr app Flutter
```bash
flutter pub get
flutter run
```

### 11) Flujo esperado en la app
1. Abre Splash.
2. Si no hay token válido → Login.
3. Logueás con usuario seed.
4. Entra a Home.
5. Desde Home, abrís módulo Clientes (listar, buscar, alta, edición, desactivación).

---

## Endpoints principales

### Auth
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`

### Clientes
- `GET /api/v1/clientes` (listar + búsqueda/filtros)
- `GET /api/v1/clientes/:id`
- `POST /api/v1/clientes`
- `PUT /api/v1/clientes/:id`
- `PATCH /api/v1/clientes/:id/deactivate`

### Permisos por rol
- `admin`: acceso total
- `vendedor`: ver/crear/editar/desactivar clientes
- `repartidor`: solo lectura (vista básica)

---

## Clientes: preparado para módulos futuros
El modelo de clientes queda listo para enlazar con:
- pedidos (FK `client_id`)
- cuentas corrientes (saldo/límite ya incluidos)
- mapas y rutas (lat/lng + routeZone)
- cobranzas e historial de compras (cliente persistente con desactivación lógica)
