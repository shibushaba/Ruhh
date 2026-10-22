// Small, strict validators. Every op declares exactly which params it accepts.

export class ApiError extends Error {
  constructor(public status: number, public code: string, public detail?: string) {
    super(code);
  }
}

const DATE = /^\d{4}-\d{2}-\d{2}$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export const REQUEST_ID = /^[A-Za-z0-9_-]{8,64}$/;

export type Params = Record<string, unknown>;

export function onlyKeys(p: Params, allowed: string[]) {
  for (const k of Object.keys(p)) {
    if (!allowed.includes(k)) throw new ApiError(400, "unknown_param", k);
  }
}

export function str(p: Params, k: string, max: number, required = false): string | undefined {
  const v = p[k];
  if (v === undefined || v === null) {
    if (required) throw new ApiError(400, "missing_param", k);
    return undefined;
  }
  if (typeof v !== "string" || v.length === 0 || v.length > max) throw new ApiError(400, "invalid_param", k);
  return v;
}

export function uuid(p: Params, k: string, required = true): string | undefined {
  const v = str(p, k, 36, required);
  if (v !== undefined && !UUID.test(v)) throw new ApiError(400, "invalid_param", k);
  return v?.toLowerCase();
}

export function int(p: Params, k: string, min: number, max: number, dflt: number): number {
  const v = p[k];
  if (v === undefined) return dflt;
  if (typeof v !== "number" || !Number.isInteger(v) || v < min || v > max) throw new ApiError(400, "invalid_param", k);
  return v;
}

export function num(p: Params, k: string, min: number, max: number, required = false): number | undefined {
  const v = p[k];
  if (v === undefined) {
    if (required) throw new ApiError(400, "missing_param", k);
    return undefined;
  }
  if (typeof v !== "number" || !Number.isFinite(v) || v < min || v > max) throw new ApiError(400, "invalid_param", k);
  return Math.round(v * 100) / 100;
}

export function bool(p: Params, k: string, dflt: boolean): boolean {
  const v = p[k];
  if (v === undefined) return dflt;
  if (typeof v !== "boolean") throw new ApiError(400, "invalid_param", k);
  return v;
}

export function oneOf<T extends string>(p: Params, k: string, values: readonly T[], dflt?: T): T | undefined {
  const v = p[k];
  if (v === undefined) return dflt;
  if (typeof v !== "string" || !(values as readonly string[]).includes(v)) throw new ApiError(400, "invalid_param", k);
  return v as T;
}

export function day(p: Params, k: string, required = false): string | undefined {
  const v = str(p, k, 10, required);
  if (v === undefined) return undefined;
  const d = new Date(v + "T00:00:00Z");
  if (!DATE.test(v) || Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== v) {
    throw new ApiError(400, "invalid_param", k);
  }
  return v;
}

export interface Range {
  from: string;
  to: string;
  days: number;
}

export const MAX_RANGE_DAYS = 366;

/** Inclusive [from, to] UTC day range; default = last 30 days ending today. */
export function range(p: Params, now: Date, defaultDays = 30): Range {
  const today = now.toISOString().slice(0, 10);
  const to = day(p, "to") ?? today;
  const from = day(p, "from") ?? new Date(Date.parse(to + "T00:00:00Z") - (defaultDays - 1) * 86400000)
    .toISOString().slice(0, 10);
  const days = Math.round((Date.parse(to) - Date.parse(from)) / 86400000) + 1;
  if (days < 1) throw new ApiError(400, "invalid_range", "from_after_to");
  if (days > MAX_RANGE_DAYS) throw new ApiError(400, "invalid_range", "max_366_days");
  return { from, to, days };
}
