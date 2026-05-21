import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireRoleFromHeader } from "@/lib/api-auth";
import { appLog } from "@/lib/logger";

const createRoundSchema = z.object({
  title: z.string().min(1),
  courseName: z.string().min(1),
  holePars: z.array(z.number().int().min(3).max(6)).min(9).max(18),
});

export async function GET() {
  const auth = await requireRoleFromHeader("PLAYER");
  if (!auth.ok) return auth.response;

  const rounds = await prisma.round.findMany({
    include: { holeScores: true },
    orderBy: { updatedAt: "desc" },
  });

  appLog("INFO", "rounds.list", { count: rounds.length, actor: auth.email, role: auth.role });
  return NextResponse.json(rounds);
}

export async function POST(req: NextRequest) {
  const auth = await requireRoleFromHeader("COACH");
  if (!auth.ok) return auth.response;

  const parsed = createRoundSchema.safeParse(await req.json());
  if (!parsed.success) {
    appLog("WARN", "rounds.create.invalid_payload", { actor: auth.email });
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
  }

  const { title, courseName, holePars } = parsed.data;
  const totalPar = holePars.reduce((s, n) => s + n, 0);
  const round = await prisma.round.create({
    data: {
      title,
      courseName,
      holeCount: holePars.length,
      totalPar,
      holeScores: {
        create: holePars.map((par, idx) => ({ hole: idx + 1, par, gross: 0 })),
      },
    },
    include: { holeScores: true },
  });

  appLog("INFO", "rounds.create", { roundId: round.id, actor: auth.email, role: auth.role });
  return NextResponse.json(round, { status: 201 });
}
