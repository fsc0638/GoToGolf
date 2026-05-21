export type AppRole = "ADMIN" | "COACH" | "PLAYER";

const roleRank: Record<AppRole, number> = {
  PLAYER: 1,
  COACH: 2,
  ADMIN: 3,
};

export function hasMinRole(current: AppRole, required: AppRole): boolean {
  return roleRank[current] >= roleRank[required];
}
