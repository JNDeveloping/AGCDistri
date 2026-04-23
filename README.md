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
npm run db:migrate
npm run db:seed
npm run dev
```

> `db:migrate` y `db:seed` son cross-platform (Windows/macOS/Linux) y toman `DATABASE_URL` desde `.env`.

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
