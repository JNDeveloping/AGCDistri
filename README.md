# AGC Distribuidora

Base profesional de app móvil (Flutter) + API (Node.js/Express) con PostgreSQL.

## Stack
- Mobile: Flutter + BLoC/Cubit + GoRouter + Dio + Secure Storage
- Backend: Node.js + Express + JWT + bcryptjs + Zod
- Base de datos: PostgreSQL

## Estructura
```text
backend/
  src/
    config/
    database/
      migrations/
      seeds/
    errors/
    middlewares/
    modules/
      auth/
      users/
      operations/
      health/
mobile/
  lib/
    core/
    features/
      auth/
      home/
    services/
```

## Backend

### Variables de entorno
Copiar `backend/.env.example` a `.env`.

### Migraciones y seed
```bash
cd backend
npm install
DATABASE_URL=postgresql://... npm run db:migrate
DATABASE_URL=postgresql://... npm run db:seed
```

### Ejecutar API
```bash
npm run dev
```

### Endpoints
#### Auth
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me` (Bearer token)

#### Operaciones protegidas por rol
- `GET /api/v1/operaciones/clientes` → admin, vendedor
- `GET /api/v1/operaciones/productos` → admin, vendedor
- `GET /api/v1/operaciones/pedidos` → admin, vendedor
- `POST /api/v1/operaciones/pedidos` → admin, vendedor
- `GET /api/v1/operaciones/repartos/mis-asignaciones` → admin, repartidor
- `GET /api/v1/operaciones/rutas/mis-rutas` → admin, repartidor
- `GET /api/v1/operaciones/entregas/mis-entregas` → admin, repartidor

### Credenciales de prueba (seed)
Password común: `Admin123!`
- admin@agc.local (admin)
- vendedor@agc.local (vendedor)
- repartidor@agc.local (repartidor)

## Mobile Flutter

### Variables de entorno
Copiar `mobile/.env.example` a `.env`.

### Ejecutar
```bash
cd mobile
flutter pub get
flutter run
```

## Flujo de login
1. App inicia en Splash.
2. Se busca token seguro en dispositivo.
3. Si hay token, se valida con `GET /auth/me`.
4. Si es válido → Home; si no → Login.
5. Login guarda token en secure storage.
6. Logout elimina token y vuelve a Login.
