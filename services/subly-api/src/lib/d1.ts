// ─────────────────────────────────────────────────────────────────────────────
// Tiny typed helpers over D1 prepared statements + a couple of util functions.
// ─────────────────────────────────────────────────────────────────────────────

/** Return all rows of a prepared statement, typed as T[]. */
export async function allRows<T = Record<string, unknown>>(
  stmt: D1PreparedStatement,
): Promise<T[]> {
  const { results } = await stmt.all<T>();
  return results ?? [];
}

/** Return the first row of a prepared statement or null. */
export async function firstRow<T = Record<string, unknown>>(
  stmt: D1PreparedStatement,
): Promise<T | null> {
  return (await stmt.first<T>()) ?? null;
}

/** Execute a write statement; returns the D1 result meta. */
export async function run(stmt: D1PreparedStatement): Promise<D1Result> {
  return stmt.run();
}

/** RFC 4122 v4 UUID (available on the Workers runtime). */
export function uuid(): string {
  return crypto.randomUUID();
}

/** Current time as an ISO-8601 string. */
export function nowIso(): string {
  return new Date().toISOString();
}

/** Today as 'YYYY-MM-DD' (UTC). */
export function todayYmd(): string {
  return new Date().toISOString().slice(0, 10);
}
