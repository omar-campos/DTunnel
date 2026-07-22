import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const args = process.argv.slice(2);
  const username = args[0];
  const password = args[1];

  if (!username || !password) {
    console.error('Uso: npx ts-node src/createAdmin.ts <usuario> <contraseña>');
    process.exit(1);
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  // Reemplaza 'user' y los nombres de campos según tu esquema de Prisma (schema.prisma)
  const admin = await prisma.user.upsert({
    where: { username },
    update: {
      password: hashedPassword,
      role: 'ADMIN', // Ajusta según el campo de roles de tu modelo
    },
    create: {
      username,
      password: hashedPassword,
      role: 'ADMIN',
    },
  });

  console.log(`Usuario administrador '${admin.username}' creado/actualizado correctamente.`);
}

main()
  .catch((e) => {
    console.error('Error al crear el administrador:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });