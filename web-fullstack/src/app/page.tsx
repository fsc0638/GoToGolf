"use client";
import { useMemo, useState } from "react";
import { QueryClient, QueryClientProvider, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

type HoleScore = { hole: number; par: number; gross: number };
type Round = {
  id: string;
  title: string;
  courseName: string;
  status: "IN_PROGRESS" | "FINISHED";
  currentHole: number;
  totalGross: number;
  totalPar: number;
  holeScores: HoleScore[];
};

const client = new QueryClient();

function GolfBoard() {
  const qc = useQueryClient();
  const [activeId, setActiveId] = useState<string | null>(null);

  const roundsQuery = useQuery<Round[]>({
    queryKey: ["rounds"],
    queryFn: async () => {
      const res = await fetch("/api/rounds");
      if (!res.ok) throw new Error("load rounds failed");
      return res.json();
    },
  });

  const createMutation = useMutation({
    mutationFn: async () => {
      const res = await fetch("/api/rounds", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: `練習回合 ${new Date().toLocaleTimeString()}`,
          courseName: "淡水高爾夫球場",
          holePars: [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4],
        }),
      });
      if (!res.ok) throw new Error("create round failed");
      return res.json();
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["rounds"] }),
  });

  const scoreMutation = useMutation({
    mutationFn: async ({ roundId, hole, gross }: { roundId: string; hole: number; gross: number }) => {
      const res = await fetch(`/api/rounds/${roundId}/score`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ hole, gross }),
      });
      if (!res.ok) throw new Error("update score failed");
      return res.json();
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["rounds"] }),
  });

  const rounds = roundsQuery.data ?? [];
  const active = useMemo(() => rounds.find((r) => r.id === activeId) ?? rounds[0], [rounds, activeId]);

  return (
    <main className="min-h-screen bg-zinc-950 text-zinc-100 p-6">
      <div className="mx-auto max-w-6xl space-y-6">
        <header className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold">GoToGolf Web 完整測試台</h1>
            <p className="text-zinc-400">Windows 可直接測：記分流程 / 洞位切換 / 統計摘要</p>
          </div>
          <button
            onClick={() => createMutation.mutate()}
            className="rounded bg-emerald-600 px-4 py-2 font-medium hover:bg-emerald-500"
          >
            + 建立18洞測試回合
          </button>
        </header>

        <section className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <div className="md:col-span-1 rounded-xl border border-zinc-800 p-4">
            <h2 className="font-semibold mb-3">歷史回合</h2>
            <div className="space-y-2 max-h-[480px] overflow-auto">
              {rounds.map((r) => (
                <button
                  key={r.id}
                  onClick={() => setActiveId(r.id)}
                  className={`w-full text-left rounded p-3 border ${active?.id === r.id ? "border-emerald-500 bg-emerald-900/20" : "border-zinc-800"}`}
                >
                  <div className="font-medium">{r.title}</div>
                  <div className="text-xs text-zinc-400">{r.courseName} · H{r.currentHole} · {r.status}</div>
                </button>
              ))}
            </div>
          </div>

          <div className="md:col-span-2 rounded-xl border border-zinc-800 p-4">
            {!active ? (
              <p className="text-zinc-400">先建立一個測試回合。</p>
            ) : (
              <>
                <div className="flex gap-6 mb-4">
                  <div><div className="text-xs text-zinc-400">目前洞位</div><div className="text-2xl font-bold">H{active.currentHole}</div></div>
                  <div><div className="text-xs text-zinc-400">總桿</div><div className="text-2xl font-bold">{active.totalGross}</div></div>
                  <div><div className="text-xs text-zinc-400">+/- Par</div><div className="text-2xl font-bold">{active.totalGross - active.totalPar}</div></div>
                </div>

                <div className="grid grid-cols-3 gap-2 md:grid-cols-6">
                  {active.holeScores
                    .slice()
                    .sort((a, b) => a.hole - b.hole)
                    .map((h) => (
                      <div key={h.hole} className="rounded border border-zinc-800 p-2 text-center">
                        <div className="text-xs text-zinc-400">H{h.hole} / Par {h.par}</div>
                        <div className="text-xl font-semibold my-1">{h.gross}</div>
                        <div className="flex justify-center gap-1">
                          <button
                            className="px-2 py-1 rounded bg-zinc-800"
                            onClick={() => scoreMutation.mutate({ roundId: active.id, hole: h.hole, gross: Math.max(0, h.gross - 1) })}
                          >
                            -
                          </button>
                          <button
                            className="px-2 py-1 rounded bg-zinc-800"
                            onClick={() => scoreMutation.mutate({ roundId: active.id, hole: h.hole, gross: h.gross + 1 })}
                          >
                            +
                          </button>
                        </div>
                      </div>
                    ))}
                </div>
              </>
            )}
          </div>
        </section>
      </div>
    </main>
  );
}

export default function Home() {
  return (
    <QueryClientProvider client={client}>
      <GolfBoard />
    </QueryClientProvider>
  );
}
