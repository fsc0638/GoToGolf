import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { z } from "zod";
import { requireRoleFromHeader } from "@/lib/api-auth";
import { appLog } from "@/lib/logger";

const scoreSchema = z.object({
  hole: z.number().int().min(1).max(18),
  gross: z.number().int().min(0).max(20),
});

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireRoleFromHeader("PLAYER");
  if (!auth.ok) return auth.response;

  const body = scoreSchema.safeParse(await req.json());
  if (!body.success) return NextResponse.json({ error: body.error.flatten() }, { status: 400 });
  const { id } = await params;
  const { hole, gross } = body.data;

  await prisma.holeScore.update({
    where: { roundId_hole: { roundId: id, hole } },
    data: { gross },
  });

  const scores = await prisma.holeScore.findMany({ where: { roundId: id } });
  const totalGross = scores.reduce((sum, item) => sum + item.gross, 0);
  const currentHole = Math.min(18, Math.max(1, scores.findIndex((h) => h.gross === 0) + 1 || 18));

  const round = await prisma.round.update({
    where: { id },
    data: {
      totalGross,
      currentHole,
      status: scores.every((s) => s.gross > 0) ? "FINISHED" : "IN_PROGRESS",
    },
    include: { holeScores: true },
  });

  appLog("INFO", "rounds.score.update", { roundId: id, hole, gross, actor: auth.email, role: auth.role });
  return NextResponse.json(round);
}
