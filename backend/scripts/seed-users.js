import path from 'node:path';
import { fileURLToPath } from 'node:url';

import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import pg from 'pg';

import { getDatabaseConnectionConfig } from '../src/config/database.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendRoot = path.resolve(__dirname, '..');

dotenv.config({ path: path.join(backendRoot, '.env') });

const { Client } = pg;

const baseUsers = [
  {
    fullName: 'Admin',
    username: 'admin',
    email: 'admin@admin.com',
    password: 'admin123',
    role: 'admin',
    isActive: true,
  },
  {
    fullName: 'Vendedor',
    username: 'vendedor',
    email: 'vendedor@demo.com',
    password: 'vendedor123',
    role: 'vendedor',
    isActive: true,
  },
];

const seedUsers = async () => {
  const client = new Client(getDatabaseConnectionConfig());
  await client.connect();

  try {
    for (const user of baseUsers) {
      const existing = await client.query(
        'SELECT id FROM users WHERE email = $1 OR username = $2 LIMIT 1',
        [user.email, user.username],
      );

      if (existing.rowCount > 0) {
        process.stdout.write(`Usuario ${user.username} ya existe\n`);
        continue;
      }

      const passwordHash = await bcrypt.hash(user.password, 12);
      await client.query(
        `
          INSERT INTO users (full_name, username, email, password_hash, role, is_active)
          VALUES ($1, $2, $3, $4, $5, $6)
        `,
        [user.fullName, user.username, user.email, passwordHash, user.role, user.isActive],
      );
      process.stdout.write(`Usuario ${user.username} creado\n`);
    }

    process.stdout.write('Seed de usuarios completado\n');
  } finally {
    await client.end();
  }
};

seedUsers().catch((error) => {
  console.error(error?.stack ?? error?.message ?? String(error));
  process.exit(1);
});
