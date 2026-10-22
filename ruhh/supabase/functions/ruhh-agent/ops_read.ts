import type { AgentDb } from "./db.ts";
import { ApiError, bool, day, int, oneOf, onlyKeys, type Params, type Range, range, uuid } from "./validate.ts";

export interface OpContext {
  db: AgentDb;
  userId: string;
  credentialId: string;
  requestId: string;
  now: Date;
  utcOffsetMinutes: number;
}

export interface OpResult {
  data: unknown;
  meta: {
    range?: { from: string; to: string; days: number; utc_offset_minutes: number } | null;
    modules: string[];
    coverage: Record<string, unknown>;
    notes: string[];
  };
}

export interface OpDef {
  scope: "read" | "write";
  run(ctx: OpContext, p: Params): Promise<OpResult>;
}

/** Aggregation reads are capped; coverage.truncated tells the caller. */
export const AGG_ROW_CAP = 5000;

export const PRAYERS = ["fajr", "dhuhr", "asr", "maghrib", "isha"] as const;
export const PRAYER_STATUSES = ["none", "missed", "lateAlone", "withGroup", "onTimeAlone", "qadha"] as const;
export const WATCH_STATUSES = ["wantToWatch", "watching", "watched"] as const;

const LOCAL_ONLY_NOTE =
  "Wallets, categories, budget periods, movie categories, todos and focus sessions are stored only on the phone and are not available here.";

function utcOffset(p: Params, dflt: number): number {
  return int(p, "utc_offset_minutes", -720, 840, dflt);
}

/** Local-day range -> UTC instants for timestamptz columns. */
function instants(r: Range, offsetMin: number): [string, string] {
  const start = Date.parse(r.from + "T00:00:00Z") - offsetMin * 60000;
  const end = Date.parse(r.to + "T00:00:00Z") + 86400000 - 1 - offsetMin * 60000;
  return [new Date(start).toISOString(), new Date(end).toISOString()];
}

function metaRange(r: Range, off: number) {
  return { from: r.from, to: r.to, days: r.days, utc_offset_minutes: off };
}

const round2 = (n: number) => Math.round(n * 100) / 100;

async function txInRange(ctx: OpContext, r: Range, off: number) {
  const [a, b] = instants(r, off);
  const rows = await ctx.db.select(ctx.userId, {
    table: "transactions",
    columns: "id,amount,is_income,category,account,title,occurred_at,schedule_type,paid",
    gte: ["occurred_at", a],
    lte: ["occurred_at", b],
    order: ["occurred_at", false],
    limit: AGG_ROW_CAP + 1,
  });
  const truncated = rows.length > AGG_ROW_CAP;
  return { rows: truncated ? rows.slice(0, AGG_ROW_CAP) : rows, truncated };
}

const booked = (t: Record<string, unknown>) => t.schedule_type === "normal" || t.paid === true;

function summarise(rows: Record<string, unknown>[]) {
  let income = 0, expense = 0, n = 0, pendingScheduled = 0;
  const byCat = new Map<string, number>();
  for (const t of rows) {
    if (!booked(t)) {
      pendingScheduled++;
      continue;
    }
    n++;
    const amt = Number(t.amount) || 0;
    if (t.is_income) income += amt;
    else {
      expense += amt;
      const c = String(t.category ?? "Uncategorised");
      byCat.set(c, (byCat.get(c) ?? 0) + amt);
    }
  }
  const top = [...byCat.entries()].sort((x, y) => y[1] - x[1]).slice(0, 20)
    .map(([category, total]) => ({ category, total: round2(total) }));
  return {
    income_total: round2(income),
    expense_total: round2(expense),
    net: round2(income - expense),
    transaction_count: n,
    unpaid_scheduled_excluded: pendingScheduled,
    expense_by_category: top,
  };
}

export const readOps: Record<string, OpDef> = {
  "budget.summary": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, ["from", "to", "utc_offset_minutes"]);
      const off = utcOffset(p, ctx.utcOffsetMinutes);
      const r = range(p, ctx.now);
      const { rows, truncated } = await txInRange(ctx, r, off);
      const s = summarise(rows);
      const notes = [LOCAL_ONLY_NOTE, "Wallet balances are not included (wallets are local-only)."];
      if (s.transaction_count === 0) notes.unshift("No booked transactions in this range.");
      return {
        data: { currency: "INR", ...s },
        meta: {
          range: metaRange(r, off),
          modules: ["budget"],
          coverage: { rows_scanned: rows.length, truncated },
          notes,
        },
      };
    },
  },

  "budget.list_transactions": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, ["from", "to", "limit", "type", "category", "utc_offset_minutes"]);
      const off = utcOffset(p, ctx.utcOffsetMinutes);
      const r = range(p, ctx.now);
      const limit = int(p, "limit", 1, 50, 20);
      const type = oneOf(p, "type", ["income", "expense"] as const);
      const category = p.category === undefined ? undefined : String(p.category).slice(0, 64);
      const [a, b] = instants(r, off);
      const eq: Record<string, string | boolean> = {};
      if (type) eq.is_income = type === "income";
      if (category) eq.category = category;
      const rows = await ctx.db.select(ctx.userId, {
        table: "transactions",
        columns: "id,amount,is_income,category,account,title,occurred_at,schedule_type,paid",
        eq,
        gte: ["occurred_at", a],
        lte: ["occurred_at", b],
        order: ["occurred_at", false],
        limit: limit + 1,
      });
      const more = rows.length > limit;
      return {
        data: { transactions: rows.slice(0, limit) },
        meta: {
          range: metaRange(r, off),
          modules: ["budget"],
          coverage: { returned: Math.min(rows.length, limit), more_available: more },
          notes: rows.length === 0 ? ["No transactions match."] : ["Notes are omitted for privacy."],
        },
      };
    },
  },

  "budget.upcoming": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, ["days"]);
      const days = int(p, "days", 1, 90, 30);
      const rows = await ctx.db.select(ctx.userId, {
        table: "transactions",
        columns: "id,amount,is_income,category,title,occurred_at,schedule_type,recurrence,paid",
        eq: { paid: false },
        gte: ["occurred_at", new Date(ctx.now.getTime() - 86400000 * 31).toISOString()],
        lte: ["occurred_at", new Date(ctx.now.getTime() + 86400000 * days).toISOString()],
        order: ["occurred_at", true],
        limit: 51,
      });
      const items = rows.filter((t) => t.schedule_type !== "normal").slice(0, 50);
      const overdue = items.filter((t) => Date.parse(String(t.occurred_at)) < ctx.now.getTime()).length;
      return {
        data: { upcoming: items, overdue_count: overdue },
        meta: {
          range: {
            from: new Date(ctx.now.getTime() - 86400000 * 31).toISOString().slice(0, 10),
            to: new Date(ctx.now.getTime() + 86400000 * days).toISOString().slice(0, 10),
            days: days + 31,
            utc_offset_minutes: 0,
          },
          modules: ["budget"],
          coverage: { returned: items.length },
          notes: items.length === 0
            ? ["No unpaid scheduled payments in this window."]
            : ["Includes up to 31 days overdue."],
        },
      };
    },
  },

  "budget.objectives": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, ["include_archived"]);
      const inc = bool(p, "include_archived", false);
      const rows = await ctx.db.select(ctx.userId, {
        table: "budget_objectives",
        columns: "id,name,target_amount,kind,wallet_name,pinned,archived,end_date",
        eq: inc ? {} : { archived: false },
        order: ["sort_order", true],
        limit: 100,
      });
      return {
        data: { objectives: rows },
        meta: {
          range: null,
          modules: ["budget"],
          coverage: { returned: rows.length },
          notes: rows.length === 0
            ? ["No savings goals synced."]
            : ["Contributed amounts are computed on the phone and are not included."],
        },
      };
    },
  },

  "budget.category_limits": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, []);
      const rows = await ctx.db.select(ctx.userId, {
        table: "category_budget_limits",
        columns: "id,budget_remote_id,category_name,limit_amount",
        order: ["category_name", true],
        limit: 200,
      });
      return {
        data: { category_limits: rows },
        meta: {
          range: null,
          modules: ["budget"],
          coverage: { returned: rows.length },
          notes: rows.length === 0
            ? ["No category limits synced."]
            : ["Budget periods are local-only; limits are keyed by budget_remote_id."],
        },
      };
    },
  },

  "habit.list": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, ["include_archived"]);
      const inc = bool(p, "include_archived", false);
      const rows = await ctx.db.select(ctx.userId, {
        table: "habits",
        columns: "id,name,kind,interval,target_per_day,target_frequency,unit_label,archived",
        eq: inc ? {} : { archived: false },
        order: ["sort_order", true],
        limit: 200,
      });
      return {
        data: { habits: rows },
        meta: {
          range: null,
          modules: ["habit"],
          coverage: { returned: rows.length },
          notes: rows.length === 0 ? ["No habits synced."] : [],
        },
      };
    },
  },

  "habit.completions": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, ["from", "to", "habit_id"]);
      const r = range(p, ctx.now);
      const habitId = uuid(p, "habit_id", false);
      const [habits, comps] = await Promise.all([
        ctx.db.select(ctx.userId, { table: "habits", columns: "id,name,archived", limit: 200 }),
        ctx.db.select(ctx.userId, {
          table: "habit_completions",
          columns: "habit_id,day,value",
          eq: habitId ? { habit_id: habitId } : {},
          gte: ["day", r.from],
          lte: ["day", r.to],
          limit: AGG_ROW_CAP + 1,
        }),
      ]);
      const truncated = comps.length > AGG_ROW_CAP;
      const counts = new Map<string, number>();
      for (const c of comps.slice(0, AGG_ROW_CAP)) {
        counts.set(String(c.habit_id), (counts.get(String(c.habit_id)) ?? 0) + 1);
      }
      const per = habits
        .filter((h) => !habitId || h.id === habitId)
        .map((h) => ({
          habit_id: h.id,
          name: h.name,
          days_completed: counts.get(String(h.id)) ?? 0,
          completion_rate: round2((counts.get(String(h.id)) ?? 0) / r.days),
        }));
      const notes: string[] = [];
      if (comps.length === 0) notes.push("No habit completions in this range.");
      if (habitId && per.length === 0) notes.push("Habit not found.");
      notes.push("Completion rate = days with a completion / days in range (ignores rest days and schedules).");
      return {
        data: { habits: per, total_completions: Math.min(comps.length, AGG_ROW_CAP) },
        meta: { range: metaRange(r, 0), modules: ["habit"], coverage: { truncated }, notes },
      };
    },
  },

  "prayer.summary": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, ["from", "to"]);
      const r = range(p, ctx.now);
      const rows = await ctx.db.select(ctx.userId, {
        table: "prayer_logs",
        columns: "day,prayer,status",
        gte: ["day", r.from],
        lte: ["day", r.to],
        limit: AGG_ROW_CAP + 1,
      });
      const byStatus: Record<string, number> = {};
      const byPrayer: Record<string, Record<string, number>> = {};
      const days = new Set<string>();
      for (const x of rows.slice(0, AGG_ROW_CAP)) {
        const s = String(x.status), pr = String(x.prayer);
        if (s === "none") continue;
        days.add(String(x.day));
        byStatus[s] = (byStatus[s] ?? 0) + 1;
        (byPrayer[pr] ??= {})[s] = (byPrayer[pr]![s] ?? 0) + 1;
      }
      const logged = Object.values(byStatus).reduce((a, b) => a + b, 0);
      const expected = r.days * PRAYERS.length;
      return {
        data: {
          by_status: byStatus,
          by_prayer: byPrayer,
          logged_count: logged,
          expected_count: expected,
          days_with_any_log: days.size,
        },
        meta: {
          range: metaRange(r, 0),
          modules: ["prayer"],
          coverage: { logged_ratio: round2(logged / expected), truncated: rows.length > AGG_ROW_CAP },
          notes: logged === 0
            ? ["No prayer logs in this range."]
            : ["Unlogged prayers are unknown, not assumed missed."],
        },
      };
    },
  },

  "movie.list": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, ["status", "limit"]);
      const status = oneOf(p, "status", WATCH_STATUSES);
      const limit = int(p, "limit", 1, 50, 20);
      const rows = await ctx.db.select(ctx.userId, {
        table: "movies",
        columns: "id,title,media_type,watch_status,user_rating,priority,watched_at,release_date",
        eq: status ? { watch_status: status } : {},
        order: ["updated_at", false],
        limit: limit + 1,
      });
      return {
        data: { movies: rows.slice(0, limit) },
        meta: {
          range: null,
          modules: ["movie"],
          coverage: { returned: Math.min(rows.length, limit), more_available: rows.length > limit },
          notes: rows.length === 0 ? ["No movies match."] : [],
        },
      };
    },
  },

  "cross.monthly_report": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, ["month", "utc_offset_minutes"]);
      const m = typeof p.month === "string" && /^\d{4}-\d{2}$/.test(p.month)
        ? p.month
        : ctx.now.toISOString().slice(0, 7);
      const start = day({ d: m + "-01" }, "d", true)!;
      const next = new Date(Date.parse(start + "T00:00:00Z"));
      next.setUTCMonth(next.getUTCMonth() + 1);
      const end = new Date(next.getTime() - 86400000).toISOString().slice(0, 10);
      const off = utcOffset(p, ctx.utcOffsetMinutes);
      const r = range({ from: start, to: end }, ctx.now);
      const [a, b] = instants(r, off);
      const [tx, comps, habits, prayers, watched] = await Promise.all([
        txInRange(ctx, r, off),
        ctx.db.select(ctx.userId, {
          table: "habit_completions",
          columns: "habit_id,day",
          gte: ["day", r.from],
          lte: ["day", r.to],
          limit: AGG_ROW_CAP,
        }),
        ctx.db.select(ctx.userId, { table: "habits", columns: "id,archived", eq: { archived: false }, limit: 200 }),
        ctx.db.select(ctx.userId, {
          table: "prayer_logs",
          columns: "day,status",
          gte: ["day", r.from],
          lte: ["day", r.to],
          limit: AGG_ROW_CAP,
        }),
        ctx.db.select(ctx.userId, {
          table: "movies",
          columns: "id",
          eq: { watch_status: "watched" },
          gte: ["watched_at", a],
          lte: ["watched_at", b],
          limit: 500,
        }),
      ]);
      const budget = summarise(tx.rows);
      const prayed = prayers.filter((x) => x.status !== "none" && x.status !== "missed").length;
      const missed = prayers.filter((x) => x.status === "missed").length;
      const habitDays = new Set(comps.map((c) => String(c.day))).size;
      const missing: string[] = [];
      if (budget.transaction_count === 0) missing.push("budget: no booked transactions");
      if (habits.length === 0) missing.push("habit: no active habits synced");
      if (prayers.length === 0) missing.push("prayer: no logs");
      if (watched.length === 0) missing.push("movie: nothing marked watched this month");
      // Evidence-based observations only: same-period co-occurrence, never causation.
      const observations: string[] = [];
      if (prayers.length > 0 && habits.length > 0) {
        observations.push(
          `Habit completions on ${habitDays} of ${r.days} days; prayers logged as prayed ${prayed}, missed ${missed}.`,
        );
      }
      if (budget.transaction_count > 0) {
        observations.push(
          `Spent ${budget.expense_total} INR across ${budget.transaction_count} booked transactions; net ${budget.net}.`,
        );
      }
      return {
        data: {
          month: m,
          budget,
          habit: { active_habits: habits.length, completions: comps.length, days_with_completion: habitDays },
          prayer: { logged: prayers.filter((x) => x.status !== "none").length, prayed, missed, expected: r.days * 5 },
          movie: { watched_count: watched.length },
          observations,
        },
        meta: {
          range: metaRange(r, off),
          modules: ["budget", "habit", "prayer", "movie"],
          coverage: { budget_truncated: tx.truncated },
          notes: [...missing.map((x) => "Missing data — " + x), "Correlations are descriptive only.", LOCAL_ONLY_NOTE],
        },
      };
    },
  },
};

export function assertNever(): never {
  throw new ApiError(500, "internal");
}
