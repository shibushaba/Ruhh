import { assert, assertEquals } from "@std/assert";
import { readOps } from "../ops_read.ts";
import { ALICE, BOB, seed, setup, TOKEN_A, TOKEN_A_RO, TOKEN_B } from "./helpers.ts";

const rid = (n = 1) => `req-test-${n.toString().padStart(4, "0")}`;

Deno.test("auth: missing, malformed, unknown, revoked, expired tokens are rejected with 401", async () => {
  const { db, call } = await setup(readOps);
  const body = { op: "habit.list", request_id: rid() };
  assertEquals((await call(body, "")).status, 401);
  assertEquals((await call(body, "not-a-token")).status, 401);
  assertEquals((await call(body, "ruhh_agent_" + "f".repeat(64))).status, 401);
  db.creds[0]!.revoked_at = "2026-10-01T00:00:00Z";
  assertEquals((await call(body)).status, 401);
  db.creds[0]!.revoked_at = null;
  db.creds[0]!.expires_at = "2026-10-01T00:00:00Z";
  const r = await call(body);
  assertEquals(r.status, 401);
  assertEquals(r.json.error.code, "unauthorized");
});

Deno.test("auth: only POST", async () => {
  const { call } = await setup(readOps);
  const r = await call(undefined, TOKEN_A, { method: "GET", body: undefined });
  assertEquals(r.status, 405);
});

Deno.test("user isolation: every query is scoped to the credential's user", async () => {
  const { db, call } = await setup(readOps);
  seed(db);
  const a = await call({ op: "budget.summary", request_id: rid(), params: { from: "2026-10-01", to: "2026-10-31" } });
  assertEquals(a.json.data.expense_total, 250);
  const b = await call(
    { op: "budget.summary", request_id: rid(2), params: { from: "2026-10-01", to: "2026-10-31" } },
    TOKEN_B,
  );
  assertEquals(b.json.data.expense_total, 999);
  assert(db.selects.every((s) => s.userId === ALICE || s.userId === BOB));
  assert(db.selects.filter((s) => s.userId === BOB).length > 0);
});

Deno.test("user cannot choose the user id via params", async () => {
  const { call } = await setup(readOps);
  const r = await call({ op: "habit.list", request_id: rid(), params: { user_id: BOB } });
  assertEquals(r.status, 400);
  assertEquals(r.json.error.code, "unknown_param");
});

Deno.test("validation: body size, json, request_id, op, extra fields, ranges, enums, limits", async () => {
  const { call } = await setup(readOps);
  assertEquals((await call("x".repeat(5000))).json.error.code, "body_too_large");
  assertEquals((await call("{nope")).json.error.code, "invalid_json");
  assertEquals((await call({ op: "habit.list" })).json.error.code, "invalid_request_id");
  assertEquals((await call({ op: "habit.list", request_id: "short" })).json.error.code, "invalid_request_id");
  assertEquals((await call({ op: "sql.raw", request_id: rid() })).json.error.code, "unknown_op");
  assertEquals((await call({ op: "__proto__", request_id: rid() })).json.error.code, "unknown_op");
  assertEquals((await call({ op: "habit.list", request_id: rid(), extra: 1 })).json.error.code, "unknown_field");
  assertEquals(
    (await call({ op: "budget.summary", request_id: rid(), params: { from: "2025-01-01", to: "2026-10-01" } })).json
      .error.detail,
    "max_366_days",
  );
  assertEquals(
    (await call({ op: "budget.summary", request_id: rid(), params: { from: "2026-10-05", to: "2026-10-01" } })).json
      .error.detail,
    "from_after_to",
  );
  assertEquals(
    (await call({ op: "budget.summary", request_id: rid(), params: { from: "2026-02-30" } })).json.error.code,
    "invalid_param",
  );
  assertEquals(
    (await call({ op: "movie.list", request_id: rid(), params: { status: "deleted" } })).json.error.code,
    "invalid_param",
  );
  assertEquals(
    (await call({ op: "budget.list_transactions", request_id: rid(), params: { limit: 51 } })).json.error.code,
    "invalid_param",
  );
  assertEquals((await call({ op: "habit.list", request_id: rid(), params: [] })).json.error.code, "invalid_params");
});

Deno.test("date ranges are explicit in every ranged response, with utc offset", async () => {
  const { db, call } = await setup(readOps);
  seed(db);
  const r = await call({
    op: "budget.summary",
    request_id: rid(),
    params: { from: "2026-10-01", to: "2026-10-31", utc_offset_minutes: 330 },
  });
  assertEquals(r.json.meta.range, { from: "2026-10-01", to: "2026-10-31", days: 31, utc_offset_minutes: 330 });
  const q = db.selects.at(-1)!.spec;
  assertEquals(q.gte, ["occurred_at", "2026-09-30T18:30:00.000Z"]);
  assertEquals(q.lte, ["occurred_at", "2026-10-31T18:29:59.999Z"]);
  const d = await call({ op: "prayer.summary", request_id: rid(2) });
  assertEquals(d.json.meta.range.to, "2026-10-22");
  assertEquals(d.json.meta.range.from, "2026-09-23");
});

Deno.test("budget.summary excludes unpaid scheduled items and reports them", async () => {
  const { db, call } = await setup(readOps);
  seed(db);
  const r = await call({ op: "budget.summary", request_id: rid(), params: { from: "2026-10-01", to: "2026-10-31" } });
  assertEquals(r.json.data.income_total, 50000);
  assertEquals(r.json.data.unpaid_scheduled_excluded, 1);
  assertEquals(r.json.data.expense_by_category, [{ category: "Food", total: 250 }]);
  assertEquals(r.json.meta.modules, ["budget"]);
});

Deno.test("list_transactions never returns notes", async () => {
  const { db, call } = await setup(readOps);
  seed(db);
  const r = await call({
    op: "budget.list_transactions",
    request_id: rid(),
    params: { from: "2026-10-01", to: "2026-10-31" },
  });
  assertEquals(r.json.data.transactions.length, 3);
  assert(!JSON.stringify(r.json).includes("SECRET-NOTE"));
});

Deno.test("empty data returns ok with explanatory notes", async () => {
  const { call } = await setup(readOps);
  for (
    const op of [
      "budget.summary",
      "habit.list",
      "habit.completions",
      "prayer.summary",
      "movie.list",
      "budget.objectives",
      "budget.category_limits",
      "budget.upcoming",
    ]
  ) {
    const r = await call({ op, request_id: rid() });
    assertEquals(r.status, 200, op);
    assert(r.json.meta.notes.length > 0, op);
  }
  const m = await call({ op: "cross.monthly_report", request_id: rid(), params: { month: "2026-10" } });
  assert(m.json.meta.notes.some((n: string) => n.startsWith("Missing data")));
});

Deno.test("cross.monthly_report covers all modules with the month range", async () => {
  const { db, call } = await setup(readOps);
  seed(db);
  const r = await call({ op: "cross.monthly_report", request_id: rid(), params: { month: "2026-10" } });
  assertEquals(r.json.meta.range.from, "2026-10-01");
  assertEquals(r.json.meta.range.to, "2026-10-31");
  assertEquals(r.json.meta.modules, ["budget", "habit", "prayer", "movie"]);
  assertEquals(r.json.data.movie.watched_count, 1);
  assertEquals(r.json.data.prayer.missed, 1);
  assertEquals(r.json.data.habit.completions, 2);
});

Deno.test("habit.completions computes per-habit counts", async () => {
  const { db, call } = await setup(readOps);
  seed(db);
  const r = await call({
    op: "habit.completions",
    request_id: rid(),
    params: { from: "2026-10-16", to: "2026-10-22" },
  });
  assertEquals(r.json.data.habits[0].days_completed, 2);
  assertEquals(r.json.meta.range.days, 7);
});

Deno.test("read-only: read ops never call RPCs or touch write tables", async () => {
  const { db, call } = await setup(readOps);
  seed(db);
  for (const op of Object.keys(readOps)) await call({ op, request_id: rid() });
  assertEquals(db.rpcCalls.length, 0);
  assert(db.selects.every((s) => s.spec.table !== "ruhh_agent_proposals"));
});

Deno.test("rate limit returns 429 and is audited", async () => {
  const { db, call } = await setup(readOps);
  db.recentOverride = 30;
  const r = await call({ op: "habit.list", request_id: rid() });
  assertEquals(r.status, 429);
  assertEquals(db.audits.at(-1)!.outcome, "rate_limited");
});

Deno.test("db errors return a generic 500 without internals", async () => {
  const { db, call } = await setup(readOps);
  db.failSelect = true;
  const r = await call({ op: "habit.list", request_id: rid() });
  assertEquals(r.status, 500);
  assertEquals(r.json.error, { code: "internal" });
});

Deno.test("logs and audit are metadata-only (no amounts, titles, tokens)", async () => {
  const { db, call, logs } = await setup(readOps);
  seed(db);
  await call({ op: "budget.list_transactions", request_id: rid(), params: { from: "2026-10-01", to: "2026-10-31" } });
  await call({ op: "habit.list", request_id: rid(2) }, TOKEN_A_RO);
  const dump = JSON.stringify(logs) + JSON.stringify(db.audits);
  for (const bad of ["Lunch", "250", "50000", "SECRET", "aaaaaaaa", TOKEN_A]) assert(!dump.includes(bad), bad);
  assertEquals(db.audits.length, 2);
  assertEquals(db.audits[0]!.outcome, "ok");
});
