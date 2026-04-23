import { ok } from '../../../utils/api-response.js';

export const healthController = (req, res) => {
  return ok(res, { uptime: process.uptime() }, 'API healthy');
};
