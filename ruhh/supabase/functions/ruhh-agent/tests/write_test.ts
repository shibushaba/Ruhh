import { assert, assertEquals, assertRejects } from "@std/assert";
import { ALLOWED_RPCS } from "../db.ts";
import { readOps } from "../ops_read.ts";
import { IDEMPOTENT_OPS, writeOps } from "../ops_write.ts";
import { ALICE, seed, setup, TOKEN_A, TOKEN_A_RO } from "./helpers.ts";

const ops = { ...readOps, ...writeOps };
const HABIT = "11111111-1111-4111-8111-111111111111";
const TX = "30000000-0000-4000-8000-000000000001";

function inboxRpc(db: { rpcImpl: (fn: string, a: Record<string, unknown>) => unknown }) {
  const keys = new Map<string, string>();
  const proposals = new Map<
    string,
    { hash: string; status: string; user: string; target: string; expired?: boolean }
  >();
  let n = 0;
  db.rpcImpl = (fn, a) => {
    if (fn === "ruhh_inbox_enqueue") {
      const k = `${a.p_user_id}:${a.p_idempotency_key}`;
      const dup = keys.has(k);
      if (!dup) keys.set(k, `inbox-${++n}`);
      return { id: keys.get(k), status: "pending", duplicate: dup };
    }
    if (fn === "ruhh_agent_proposal_create") {
      if (a.p_target !== TX) throw new Error("target_not_found");
      const id = `00000000-0000-4000-8000-${String(++n).padStart(12, "0")}`;
      proposals.set(id, {
        hash: "f".repeat(64),
        status: "pending",
        user: String(a.p_user_id),
        target: String(a.p_target),
      });
      return {
        proposal_id: id,
        params_hash: "f".repeat(64),
        summary: a.p_summary,
        expires_at: "2026-10-22T06:15:00Z",
        status: "pending",
      };
    }
    if (fn === "ruhh_agent_proposal_reject") {
      const p = proposals.get(String(a.p_proposal_id));
      if (!p || p.user !== a.p_user_id) throw new Error("proposal_not_found");
      if (p.status !== "pending") throw new Error("proposal_already_decided");
      p.status = "rejected";
      return { proposal_id: a.p_proposal_id, status: p.status };
    }
    throw new Error("unexpected");
  };
  return proposals;
}

Deno.test("read-only credential cannot write (403)", async () => {
  const { db, call } = await setup(ops, IDEMPOTENT_OPS);
  inboxRpc(db);
  const r = await call(
    { op: "tx.add", request_id: "req-w-0001", params: { amount: 10, category: "Food" } },
    TOKEN_A_RO,
  );
  assertEquals(r.status, 403);
  assertEquals(r.json.error.code, "forbidden_scope");
  assertEquals(db.rpcCalls.length, 0);
  assertEquals(db.audits.at(-1)!.outcome, "denied");
});

Deno.test("auto writes only enqueue into the inbox, scoped to the credential user", async () => {
  const { db, call } = await setup(ops, IDEMPOTENT_OPS);
  seed(db);
  inboxRpc(db);
  const a = await call({ op: "tx.add", request_id: "req-w-0001", params: { amount: 99.999, category: "Food" } });
  assertEquals(a.json.data.status, "queued");
  const b = await call({
    op: "habit.mark_done",
    request_id: "req-w-0002",
    params: { habit_id: HABIT, day: "2026-10-22" },
  });
  assertEquals(b.status, 200);
  const c = await call({
    op: "prayer.set_status",
    request_id: "req-w-0003",
    params: { prayer: "asr", status: "onTimeAlone", day: "2026-10-21" },
  });
  assertEquals(c.status, 200);
  const d = await call({ op: "movie.add_watchlist", request_id: "req-w-0004", params: { title: "  Interstellar " } });
  assertEquals(d.status, 200);
  assertEquals(db.rpcCalls.map((x) => x.fn), Array(4).fill("ruhh_inbox_enqueue"));
  assert(db.rpcCalls.every((x) => x.args.p_user_id === ALICE));
  assertEquals(db.rpcCalls[0]!.args.p_payload, {
    amount: 100,
    is_income: false,
    category: "Food",
    account: "Cash",
    title: "",
    occurred_at: "2026-10-22T06:00:00.000Z",
  });
  assertEquals((db.rpcCalls[3]!.args.p_payload as { title: string }).title, "Interstellar");
});

Deno.test("request_id idempotency: replay returns the stored response and enqueues once", async () => {
  const { db, call } = await setup(ops, IDEMPOTENT_OPS);
  inboxRpc(db);
  const body = { op: "tx.add", request_id: "req-w-0009", params: { amount: 5, category: "Tea" } };
  const a = await call(body);
  const b = await call(body);
  assertEquals(a.json, b.json);
  assertEquals(db.rpcCalls.length, 1);
  assertEquals(db.audits.at(-1)!.outcome, "replay");
});

Deno.test("write validation: amounts, dates, enums, unknown params, future days", async () => {
  const { db, call } = await setup(ops, IDEMPOTENT_OPS);
  seed(db);
  inboxRpc(db);
  const bad = [
    { op: "tx.add", params: { amount: -1, category: "x" } },
    { op: "tx.add", params: { amount: 1e9, category: "x" } },
    { op: "tx.add", params: { amount: 1 } },
    { op: "tx.add", params: { amount: 1, category: "x", occurred_at: "2030-01-01T00:00:00Z" } },
    { op: "tx.add", params: { amount: 1, category: "x", wallet: "Bank" } },
    { op: "prayer.set_status", params: { prayer: "tahajjud", status: "missed" } },
    { op: "prayer.set_status", params: { prayer: "asr", status: "none" } },
    { op: "habit.mark_done", params: { habit_id: HABIT, day: "2026-10-23" } },
    { op: "movie.add_watchlist", params: { title: "   " } },
  ];
  for (const [i, b] of bad.entries()) {
    const r = await call({ ...b, request_id: `req-bad-${String(i).padStart(4, "0")}` });
    assertEquals(r.status, 400, JSON.stringify(b));
  }
  assertEquals(db.rpcCalls.length, 0);
});

Deno.test("habit.mark_done on unknown habit -> 404, nothing queued", async () => {
  const { db, call } = await setup(ops, IDEMPOTENT_OPS);
  seed(db);
  inboxRpc(db);
  const r = await call({
    op: "habit.mark_done",
    request_id: "req-w-0101",
    params: { habit_id: "22222222-2222-4222-8222-222222222222" },
  });
  assertEquals(r.status, 404);
  assertEquals(db.rpcCalls.length, 0);
});

Deno.test("edits/deletes create proposals, never direct changes", async () => {
  const { db, call } = await setup(ops, IDEMPOTENT_OPS);
  inboxRpc(db);
  const r = await call({ op: "tx.delete", request_id: "req-p-0001", params: { id: TX } });
  assertEquals(r.json.data.requires_approval, true);
  assertEquals(db.rpcCalls.map((x) => x.fn), ["ruhh_agent_proposal_create"]);
  const e = await call({ op: "tx.edit", request_id: "req-p-0002", params: { id: TX } });
  assertEquals(e.json.error.code, "missing_param");
});

Deno.test("agent can never approve: no op, no hash, no approve RPC, no approve scope", async () => {
  const { db, call } = await setup(ops, IDEMPOTENT_OPS);
  const props = inboxRpc(db);
  const r = await call({ op: "tx.edit", request_id: "req-p-0011", params: { id: TX, amount: 12 } });
  assertEquals(r.status, 200);
  const dump = JSON.stringify(r.json);
  assert(!dump.includes("params_hash") && !dump.includes("f".repeat(64)), "hash never returned to the agent");
  assert(!dump.includes("approve_with"));
  assertEquals(r.json.data.requires_approval, true);
  // every approve-like op name is unknown
  for (const op of ["proposal.approve", "proposal.decide", "proposal.execute", "approve"]) {
    const x = await call({
      op,
      request_id: `req-x-${op.length.toString().padStart(4, "0")}`,
      params: { proposal_id: r.json.data.proposal_id, params_hash: "f".repeat(64) },
    });
    assertEquals(x.status, 400, op);
    assertEquals(x.json.error.code, "unknown_op");
  }
  assert(!Object.keys(ops).some((k) => /approve|decide|execute/.test(k)));
  assert(!ALLOWED_RPCS.has("ruhh_agent_proposal_decide"));
  assert(Object.values(ops).every((d) => d.scope === "read" || d.scope === "write"));
  // the DB layer refuses the approve RPC even if called directly
  await assertRejects(() => db.rpc("ruhh_agent_proposal_decide", {}), Error, "rpc_not_allowed");
  // proposal.list never exposes params or hashes
  db.tables.ruhh_agent_proposals = [{
    id: r.json.data.proposal_id,
    user_id: ALICE,
    action: "tx.edit",
    summary: "s",
    status: "pending",
    params_hash: "f".repeat(64),
    params: { amount: 12 },
    expires_at: "2099-01-01T00:00:00Z",
    created_at: "2026-10-22T06:00:00Z",
  }];
  const l = await call({ op: "proposal.list", request_id: "req-p-0019", params: {} });
  assert(!JSON.stringify(l.json).includes("f".repeat(64)));
  assertEquals(props.get(r.json.data.proposal_id)!.status, "pending", "still pending: only the app can approve");
});

Deno.test("agent reject uses the reject-only RPC and is single use", async () => {
  const { db, call } = await setup(ops, IDEMPOTENT_OPS);
  inboxRpc(db);
  const r = await call({ op: "tx.delete", request_id: "req-p-0031", params: { id: TX } });
  const a = await call({
    op: "proposal.reject",
    request_id: "req-p-0032",
    params: { proposal_id: r.json.data.proposal_id },
  });
  assertEquals(a.json.data.status, "rejected");
  const b = await call({
    op: "proposal.reject",
    request_id: "req-p-0033",
    params: { proposal_id: r.json.data.proposal_id },
  });
  assertEquals(b.json.error.code, "proposal_already_decided");
  assert(db.rpcCalls.every((c) => c.fn !== "ruhh_agent_proposal_decide"));
});

Deno.test("proposal on another user's / missing target -> 409 target_not_found", async () => {
  const { db, call } = await setup(ops, IDEMPOTENT_OPS);
  inboxRpc(db);
  const r = await call({
    op: "tx.delete",
    request_id: "req-p-0021",
    params: { id: "30000000-0000-4000-8000-000000000999" },
  });
  assertEquals(r.status, 409);
  assertEquals(r.json.error.code, "target_not_found");
});

Deno.test("no payment, transfer, bulk, local-only or SQL operations exist", () => {
  const names = Object.keys(ops).join(" ");
  for (const banned of ["pay", "transfer", "bulk", "wallet", "todo", "focus", "sql", "category.", "deploy"]) {
    assert(!names.includes(banned), banned);
  }
});

Deno.test("write audit/logs contain no amounts or titles", async () => {
  const { db, call, logs } = await setup(ops, IDEMPOTENT_OPS);
  inboxRpc(db);
  await call({
    op: "tx.add",
    request_id: "req-w-0201",
    params: { amount: 777, category: "Food", title: "Birthday gift" },
  }, TOKEN_A);
  const dump = JSON.stringify(logs) + JSON.stringify(db.audits);
  assert(!dump.includes("777") && !dump.includes("Birthday"));
});
