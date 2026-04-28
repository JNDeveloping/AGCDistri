const parseBoolean = (value, fallback = false) => {
  if (value == null) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(String(value).toLowerCase());
};

const hasDatabaseUrl = Boolean(process.env.DATABASE_URL);
const nodeEnv = process.env.NODE_ENV ?? 'development';
const isProduction = nodeEnv === 'production';

export const getDatabaseConnectionConfig = () => {
  const sslEnabled = parseBoolean(process.env.DB_SSL, hasDatabaseUrl && isProduction);
  const rejectUnauthorized = parseBoolean(process.env.DB_SSL_REJECT_UNAUTHORIZED, false);

  if (hasDatabaseUrl) {
    return {
      connectionString: process.env.DATABASE_URL,
      ssl: sslEnabled ? { rejectUnauthorized } : undefined,
    };
  }

  return {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? 5432),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: sslEnabled ? { rejectUnauthorized } : undefined,
  };
};

export const getDatabaseTargetForLogs = () => {
  if (hasDatabaseUrl) {
    try {
      const url = new URL(process.env.DATABASE_URL);
      const db = url.pathname?.replace(/^\//, '') || 'postgres';
      return `${url.hostname}:${url.port || 5432}/${db}`;
    } catch {
      return 'database-url';
    }
  }

  return `${process.env.DB_HOST ?? 'db-host'}:${process.env.DB_PORT ?? 5432}/${process.env.DB_NAME ?? 'db-name'}`;
};

