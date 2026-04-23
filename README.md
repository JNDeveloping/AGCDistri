# AGC Distribuidora

Base profesional de app móvil (Flutter) + API (Node.js/Express) con PostgreSQL.

## Stack
- Mobile: Flutter + Cubit + GoRouter + Dio + Secure Storage
- Backend: Node.js + Express + JWT + bcryptjs + Zod
- Base de datos: PostgreSQL

## Backend

### Migraciones y seed
```bash
cd backend
npm install
DATABASE_URL=postgresql://... npm run db:migrate
DATABASE_URL=postgresql://... npm run db:seed
npm run dev
```

### Endpoints principales
#### Auth
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`

#### Clientes
- `GET /api/v1/clientes` (listar + búsqueda/filtros)
- `GET /api/v1/clientes/:id`
- `POST /api/v1/clientes`
- `PUT /api/v1/clientes/:id`
- `PATCH /api/v1/clientes/:id/deactivate`

### Permisos por rol
- `admin`: acceso total
- `vendedor`: ver/crear/editar/desactivar clientes
- `repartidor`: solo lectura (vista básica)

### Seed de usuarios
Password común: `Admin123!`
- admin@agc.local
- vendedor@agc.local
- repartidor@agc.local

### Seed de clientes
- CLI-0001 / Almacén Centro SRL
- CLI-0002 / Kiosco San Juan

## Mobile

```bash
cd mobile
flutter pub get
flutter run
```

## Flujo de sesión
1. Splash revisa token seguro.
2. Si hay token, valida con `/auth/me`.
3. Si token válido: Home.
4. Si token inválido/no existe: Login.
5. Desde Home se entra al módulo Clientes.

## Clientes: preparado para módulos futuros
El modelo de clientes queda listo para enlazar con:
- pedidos (FK `client_id`)
- cuentas corrientes (saldo/límite ya incluidos)
- mapas y rutas (lat/lng + routeZone)
- cobranzas e historial de compras (cliente persistente con desactivación lógica)
