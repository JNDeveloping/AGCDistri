export const USER_ROLES = {
  ADMIN: 'admin',
  VENDEDOR: 'vendedor',
  REPARTIDOR: 'repartidor',
};

export const ROLE_PERMISSIONS = {
  [USER_ROLES.ADMIN]: ['*'],
  [USER_ROLES.VENDEDOR]: ['clientes:read', 'productos:read', 'pedidos:read', 'pedidos:create'],
  [USER_ROLES.REPARTIDOR]: ['repartos:read:own', 'rutas:read:own', 'entregas:read:own'],
};
