import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { authorize } from '../../../middlewares/authorize.js';
import { ok } from '../../../utils/api-response.js';

const operationsRouter = Router();

operationsRouter.use(authenticate);

operationsRouter.get('/clientes', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), (req, res) => {
  return ok(res, { role: req.user.role }, 'Acceso concedido a clientes.');
});

operationsRouter.get('/productos', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), (req, res) => {
  return ok(res, { role: req.user.role }, 'Acceso concedido a productos.');
});

operationsRouter.get('/pedidos', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), (req, res) => {
  return ok(res, { role: req.user.role }, 'Acceso concedido a pedidos.');
});

operationsRouter.post('/pedidos', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), (req, res) => {
  return ok(res, { createdBy: req.user.sub }, 'Pedido creado (placeholder de integración).');
});

operationsRouter.get('/repartos/mis-asignaciones', authorize(USER_ROLES.ADMIN, USER_ROLES.REPARTIDOR), (req, res) => {
  return ok(res, { userId: req.user.sub }, 'Acceso concedido a repartos asignados.');
});

operationsRouter.get('/rutas/mis-rutas', authorize(USER_ROLES.ADMIN, USER_ROLES.REPARTIDOR), (req, res) => {
  return ok(res, { userId: req.user.sub }, 'Acceso concedido a rutas asignadas.');
});

operationsRouter.get('/entregas/mis-entregas', authorize(USER_ROLES.ADMIN, USER_ROLES.REPARTIDOR), (req, res) => {
  return ok(res, { userId: req.user.sub }, 'Acceso concedido a entregas asignadas.');
});

export { operationsRouter };
