import { AppError } from '../errors/app-error.js';

export const validate = (schema) => {
  return (req, _res, next) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      throw new AppError('Error de validación.', 400, result.error.flatten());
    }

    req.body = result.data;
    return next();
  };
};
