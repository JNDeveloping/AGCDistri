import { AppError } from '../errors/app-error.js';

export const validate = (schema, source = 'body') => {
  return (req, _res, next) => {
    const target = source === 'query' ? req.query : req.body;
    const result = schema.safeParse(target);

    if (!result.success) {
      throw new AppError('Error de validación.', 400, result.error.flatten());
    }

    if (source === 'query') {
      req.query = result.data;
    } else {
      req.body = result.data;
    }

    return next();
  };
};
