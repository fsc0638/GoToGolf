import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function upsertUser(email, name, password, role) {
  const passwordHash = await bcrypt.hash(password, 10);
  await prisma.user.upsert({
    where: { email },
    update: { passwordHash, role },
    create: { email, name, passwordHash, role },
  });
}

async function main() {
  const demoEmail = process.env.DEMO_USER_EMAIL || "demo@gotogolf.local";
  const demoPassword = process.env.DEMO_USER_PASSWORD || "12345678";
  const adminEmail = process.env.ADMIN_USER_EMAIL || "admin@gotogolf.local";
  const adminPassword = process.env.ADMIN_USER_PASSWORD || "12345678";

  await upsertUser(demoEmail, "Demo Player", demoPassword, "PLAYER");
  await upsertUser(adminEmail, "Platform Admin", adminPassword, "ADMIN");

  console.log(`Seeded users: ${demoEmail}, ${adminEmail}`);
}

main().finally(async () => prisma.$disconnect());
