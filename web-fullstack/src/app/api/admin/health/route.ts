import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireRoleFromHeader } from "@/lib/api-auth";

export async function GET() {
  const auth = await requireRoleFromHeader("ADMIN");
  if (!auth.ok) return auth.response;

  const roundCount = await prisma.round.count();
  const userCount = await prisma.user.count();

  return NextResponse.json({
    status: "ok",
    service: "gotogolf-web-fullstack",
    counts: { users: userCount, rounds: roundCount },
    actor: { email: auth.email, role: auth.role },
    ts: new Date().toISOString(),
  });
}
