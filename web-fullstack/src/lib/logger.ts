type Level = "INFO" | "WARN" | "ERROR";

export function appLog(level: Level, event: string, payload: Record<string, unknown> = {}) {
  const line = {
    ts: new Date().toISOString(),
    level,
    event,
    ...payload,
  };
  console.log(JSON.stringify(line));
}
