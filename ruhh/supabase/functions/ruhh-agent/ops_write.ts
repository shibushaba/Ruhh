import type { OpContext, OpDef, OpResult } from "./ops_read.ts";
import { PRAYER_STATUSES, PRAYERS } from "./ops_read.ts";
import { ApiError, bool, day, num, oneOf, onlyKeys, str, uuid } from "./validate.ts";

// Policy:
//  * AUTO (queued immediately, reversible, low risk): tx.add, habit.mark_done,
//    prayer.set_status, movie.add_watchlist.
//  * PROPOSAL (needs exact single-use approval within 15 min): tx.edit, tx.delete, movie.delete.
//  * NEVER offered: payments/transfers, bulk changes, wallets/categories/todos (local-only),
//    schema/security/deployment actions, raw SQL.
// All writes only enqueue into ruhh_agent_inbox; the app applies them before its next push.

const HEX64 = /^[0-9a-f]{64}$/;

function today(ctx: OpContext): string {
  return new Date(ctx.now.getTime() + ctx.utcOffsetMinutes * 60000).toISOString().slice(0, 10);
}

function notFuture(ctx: OpContext, d: string) {
  if (d > today(ctx)) throw new ApiError(400, "invalid_param", "future_day");
}

async function enqueue(
  ctx: OpContext,
  entity: string,
  op: string,
  payload: Record<string, unknown>,
): Promise<OpResult> {
  const r = await ctx.db.rpc("ruhh_inbox_enqueue", {
    p_user_id: ctx.userId,
    p_entity: entity,
    p_op: op,
    p_payload: payload,
    p_idempotency_key: `${ctx.credentialId}:${ctx.requestId}`,
    p_source: "agent",
  }) as { id: string; status: string; duplicate: boolean };
  return {
    data: {
      inbox_id: r.id,
      status: "queued",
      duplicate: r.duplicate,
      applies: "on the next app sync (app must be opened)",
    },
    meta: {
      range: null,
      modules: [entity === "transaction" ? "budget" : entity.split("_")[0]!],
      coverage: {},
      notes: ["Queued in the RUHH inbox; it becomes visible after the phone syncs."],
    },
  };
}

async function propose(
  ctx: OpContext,
  action: "tx.edit" | "tx.delete" | "movie.delete",
  target: string,
  params: Record<string, unknown>,
  summary: string,
): Promise<OpResult> {
  const r = await ctx.db.rpc("ruhh_agent_proposal_create", {
    p_user_id: ctx.userId,
    p_credential_id: ctx.credentialId,
    p_action: action,
    p_target: target,
    p_params: params,
    p_summary: summary,
  }) as { proposal_id: string; params_hash: string; summary: string; expires_at: string; status: string };
  return {
    data: {
      ...r,
      requires_approval: true,
      approve_with: { op: "proposal.approve", params: { proposal_id: r.proposal_id, params_hash: r.params_hash } },
    },
    meta: {
      range: null,
      modules: [action.startsWith("tx.") ? "budget" : "movie"],
      coverage: {},
      notes: ["Nothing has changed yet. Ask the user to confirm this exact action within 15 minutes."],
    },
  };
}

export const writeOps: Record<string, OpDef> = {
  "tx.add": {
    scope: "write",
    run(ctx, p) {
      onlyKeys(p, ["amount", "is_income", "category", "account", "title", "occurred_at"]);
      const amount = num(p, "amount", 0.01, 10_000_000, true)!;
      const occurred = str(p, "occurred_at", 30) ?? ctx.now.toISOString();
      const t = Date.parse(occurred);
      if (Number.isNaN(t) || t > ctx.now.getTime() + 86400000 || t < ctx.now.getTime() - 366 * 86400000) {
        throw new ApiError(400, "invalid_param", "occurred_at");
      }
      return enqueue(ctx, "transaction", "create", {
        amount,
        is_income: bool(p, "is_income", false),
        category: str(p, "category", 64, true),
        account: str(p, "account", 64) ?? "Cash",
        title: str(p, "title", 120) ?? "",
        occurred_at: new Date(t).toISOString(),
      });
    },
  },

  "habit.mark_done": {
    scope: "write",
    async run(ctx, p) {
      onlyKeys(p, ["habit_id", "day"]);
      const habitId = uuid(p, "habit_id")!;
      const d = day(p, "day") ?? today(ctx);
      notFuture(ctx, d);
      const h = await ctx.db.select(ctx.userId, {
        table: "habits",
        columns: "id",
        eq: { id: habitId, archived: false },
        limit: 1,
      });
      if (h.length === 0) throw new ApiError(404, "target_not_found");
      return enqueue(ctx, "habit_completion", "create", { habit_id: habitId, day: d });
    },
  },

  "prayer.set_status": {
    scope: "write",
    run(ctx, p) {
      onlyKeys(p, ["day", "prayer", "status"]);
      const d = day(p, "day") ?? today(ctx);
      notFuture(ctx, d);
      const prayer = oneOf(p, "prayer", PRAYERS)!;
      const status = oneOf(p, "status", PRAYER_STATUSES.filter((s) => s !== "none"))!;
      if (!prayer || !status) throw new ApiError(400, "missing_param", !prayer ? "prayer" : "status");
      return enqueue(ctx, "prayer_log", "upsert", { day: d, prayer, status });
    },
  },

  "movie.add_watchlist": {
    scope: "write",
    run(ctx, p) {
      onlyKeys(p, ["title", "media_type"]);
      const title = str(p, "title", 200, true)!.trim();
      if (!title) throw new ApiError(400, "invalid_param", "title");
      return enqueue(ctx, "movie", "create", {
        title,
        media_type: oneOf(p, "media_type", ["movie", "tv"] as const, "movie"),
      });
    },
  },

  "tx.edit": {
    scope: "write",
    run(ctx, p) {
      onlyKeys(p, ["id", "amount", "category", "title", "note"]);
      const id = uuid(p, "id")!;
      const changes: Record<string, unknown> = {};
      const amount = num(p, "amount", 0.01, 10_000_000);
      if (amount !== undefined) changes.amount = amount;
      for (const [k, max] of [["category", 64], ["title", 120], ["note", 500]] as const) {
        const v = str(p, k, max);
        if (v !== undefined) changes[k] = v;
      }
      if (Object.keys(changes).length === 0) throw new ApiError(400, "missing_param", "changes");
      const summary = "Edit transaction: " +
        Object.entries(changes).map(([k, v]) => `${k} → ${String(v).slice(0, 40)}`).join(", ");
      return propose(ctx, "tx.edit", id, changes, summary);
    },
  },

  "tx.delete": {
    scope: "write",
    run(ctx, p) {
      onlyKeys(p, ["id"]);
      return propose(ctx, "tx.delete", uuid(p, "id")!, {}, "Delete one transaction");
    },
  },

  "movie.delete": {
    scope: "write",
    run(ctx, p) {
      onlyKeys(p, ["id"]);
      return propose(ctx, "movie.delete", uuid(p, "id")!, {}, "Remove one movie from the library");
    },
  },

  "proposal.list": {
    scope: "read",
    async run(ctx, p) {
      onlyKeys(p, []);
      const rows = await ctx.db.select(ctx.userId, {
        table: "ruhh_agent_proposals",
        columns: "id,action,summary,status,expires_at,created_at",
        eq: { status: "pending" },
        gte: ["expires_at", ctx.now.toISOString()],
        order: ["created_at", false],
        limit: 20,
      });
      return {
        data: { proposals: rows },
        meta: {
          range: null,
          modules: [],
          coverage: { returned: rows.length },
          notes: rows.length ? [] : ["No pending proposals."],
        },
      };
    },
  },

  "proposal.approve": {
    scope: "approve",
    async run(ctx, p) {
      onlyKeys(p, ["proposal_id", "params_hash"]);
      const id = uuid(p, "proposal_id")!;
      const hash = str(p, "params_hash", 64, true)!;
      if (!HEX64.test(hash)) throw new ApiError(400, "invalid_param", "params_hash");
      const r = await ctx.db.rpc("ruhh_agent_proposal_decide", {
        p_user_id: ctx.userId,
        p_proposal_id: id,
        p_decision: "approve",
        p_params_hash: hash,
      });
      return {
        data: r,
        meta: {
          range: null,
          modules: [],
          coverage: {},
          notes: ["Approved action queued; applies on the next app sync."],
        },
      };
    },
  },

  "proposal.reject": {
    scope: "write",
    async run(ctx, p) {
      onlyKeys(p, ["proposal_id"]);
      const r = await ctx.db.rpc("ruhh_agent_proposal_decide", {
        p_user_id: ctx.userId,
        p_proposal_id: uuid(p, "proposal_id")!,
        p_decision: "reject",
        p_params_hash: null,
      });
      return { data: r, meta: { range: null, modules: [], coverage: {}, notes: [] } };
    },
  },
};

export const IDEMPOTENT_OPS = new Set([
  "tx.add",
  "habit.mark_done",
  "prayer.set_status",
  "movie.add_watchlist",
  "tx.edit",
  "tx.delete",
  "movie.delete",
  "proposal.approve",
  "proposal.reject",
]);
