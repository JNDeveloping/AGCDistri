# AGC Distribuidora - Base de Plataforma (Mobile + Backend)

Base profesional preparada para escalar una app de distribuidora mayorista con Flutter + Node.js/Express + PostgreSQL.

## Stack
- **Mobile:** Flutter + `flutter_bloc` + `go_router` + `dio`
- **Backend:** Node.js + Express + JWT + Zod
- **Database:** PostgreSQL (`pg`)

---

## Estructura de carpetas

```text
.
├── backend/
│   ├── src/
│   │   ├── config/            # Variables de entorno y logging
│   │   ├── database/          # Pool de PostgreSQL y healthcheck DB
│   │   ├── middlewares/       # Auth JWT, validación, error handling
│   │   ├── modules/
│   │   │   ├── auth/          # Módulo de autenticación (base lista)
│   │   │   └── health/        # Endpoint operativo de salud
│   │   ├── utils/             # Helpers de respuesta HTTP
│   │   ├── app.js             # Composición Express
│   │   └── server.js          # Bootstrap de API
│   ├── .env.example
│   └── package.json
├── mobile/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── config/        # Bootstrap de app e inyección inicial
│   │   │   ├── router/        # Navegación escalable con GoRouter
│   │   │   └── theme/         # Tema visual corporativo
│   │   ├── features/
│   │   │   ├── auth/          # Base de autenticación con Cubit
│   │   │   └── dashboard/     # Pantalla operativa base
│   │   ├── models/            # Modelos de dominio compartidos
│   │   ├── services/          # API client y storage de token
│   │   └── shared/            # Componentes/extensiones reutilizables
│   ├── .env.example
│   └── pubspec.yaml
└── README.md
```

---

## Backend: cómo correr

1. Instalar dependencias:
   ```bash
   cd backend
   npm install
   ```

2. Configurar entorno:
   ```bash
   cp .env.example .env
   ```
   Ajustar `DATABASE_URL`, `JWT_SECRET` y puertos según tu entorno.

3. Levantar API:
   ```bash
   npm run dev
   ```

### Endpoints base disponibles
- `GET /api/v1/health`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me` (requiere Bearer token)

> En esta etapa, `login` emite JWT con una sesión base para validar wiring de arquitectura.

---

## Mobile Flutter: cómo correr

1. Crear proyecto Flutter real (si todavía no está generado):
   ```bash
   cd mobile
   flutter create .
   ```

2. Instalar dependencias:
   ```bash
   flutter pub get
   ```

3. Configurar entorno:
   ```bash
   cp .env.example .env
   ```

4. Ejecutar app:
   ```bash
   flutter run
   ```

> `API_BASE_URL` default está pensado para emulador Android (`10.0.2.2`).

---

## Variables de entorno

### backend/.env.example
- `PORT`
- `DATABASE_URL`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `CORS_ORIGIN`

### mobile/.env.example
- `API_BASE_URL`

---

## Decisiones de arquitectura tomadas

- **Estado global:** `Cubit` (`flutter_bloc`) para mantener consistencia, simplicidad y escalabilidad.
- **Navegación:** `go_router` con guard de autenticación basado en estado.
- **Auth:** base JWT lista en backend + cliente móvil integrado por `ApiClient`.
- **DB:** conexión PostgreSQL centralizada mediante `Pool` con healthcheck al iniciar.
- **Escalabilidad:** módulos de backend por dominio (`modules/*`) y features de Flutter por vertical.

---

## Cómo continuar con módulo Login (siguiente etapa)

1. **Backend auth real**
   - Crear tabla `users` y `roles` en PostgreSQL.
   - Validar credenciales con hash (`bcryptjs`).
   - Reemplazar `pending-db-user-id` por usuario real.

2. **Mobile auth real**
   - Reemplazar `TokenStorage` en memoria por almacenamiento seguro (`flutter_secure_storage`).
   - Agregar refresh token strategy.
   - Manejar expiración y logout automático.

3. **Seguridad/producción**
   - Rotación de secretos JWT.
   - Rate limit y audit logs.
   - CI/CD + tests de integración.
