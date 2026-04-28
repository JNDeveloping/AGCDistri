import dotenv from 'dotenv';

dotenv.config();

const requiredEnvVars = ['JWT_SECRET'];

requiredEnvVars.forEach((key) => {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
});

const hasDatabaseUrl = Boolean(process.env.DATABASE_URL);
const hasDbParts = ['DB_HOST', 'DB_USER', 'DB_NAME'].every((key) => Boolean(process.env[key]));

if (!hasDatabaseUrl && !hasDbParts) {
  throw new Error(
    'Missing database configuration. Define DATABASE_URL or DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME.',
  );
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 4000),
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  corsOrigin: process.env.CORS_ORIGIN ?? '',
};
