import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { hasMinRole, type AppRole } from "@/lib/rbac";

export async function requireRoleFromHeader(required: AppRole): Promise<{ ok: true; email: string; role: AppRole } | { ok: false; response: NextResponse }> {
  const email = process.env.DEV_ADMIN_EMAIL || "demo@gotogolf.local";
  const roleHeader = (process.env.DEV_ROLE_OVERRIDE || "ADMIN") as AppRole;

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    return { ok: false, response: NextResponse.json({ error: "Unauthorized user" }, { status: 401 }) };
  }

  const role = roleHeader || (user.role as AppRole);
  if (!hasMinRole(role, required)) {
    return { ok: false, response: NextResponse.json({ error: `Forbidden: requires ${required}` }, { status: 403 }) };
  }

  return { ok: true, email, role };
}
