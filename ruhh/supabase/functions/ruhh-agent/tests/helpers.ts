import { createHandler, sha256Hex } from "../handler.ts";
import type { OpDef } from "../ops_read.ts";
import { MockDb } from "./mock_db.ts";

export const ALICE = "00000000-0000-4000-8000-00000000000a";
export const BOB = "00000000-0000-4000-8000-00000000000b";
export const TOKEN_A = "ruhh_agent_" + "a".repeat(64);
export const TOKEN_A_RO = "ruhh_agent_" + "c".repeat(64);
export const TOKEN_B = "ruhh_agent_" + "b".repeat(64);
export const NOW = new Date("2026-10-22T06:00:00Z");

export async function setup(ops: Record<string, OpDef>, idempotentOps?: Set<string>) {
  const db = new MockDb();
  db.creds.push(
    {
      id: "cred-a",
      user_id: ALICE,
      token_hash: await sha256Hex(TOKEN_A),
      scopes: ["read", "write", "approve"],
      expires_at: null,
      revoked_at: null,
    },
    {
      id: "cred-a-ro",
      user_id: ALICE,
      token_hash: await sha256Hex(TOKEN_A_RO),
      scopes: ["read"],
      expires_at: null,
      revoked_at: null,
    },
    {
      id: "cred-b",
      user_id: BOB,
      token_hash: await sha256Hex(TOKEN_B),
      scopes: ["read"],
      expires_at: null,
      revoked_at: null,
    },
  );
  const logs: Record<string, unknown>[] = [];
  const handle = createHandler({ db, ops, now: () => NOW, log: (e) => logs.push(e), idempotentOps });
  const call = async (body: unknown, token = TOKEN_A, init: RequestInit = {}) => {
    const res = await handle(
      new Request("http://local/ruhh-agent", {
        method: "POST",
        headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
        body: typeof body === "string" ? body : JSON.stringify(body),
        ...init,
      }),
    );
    return { status: res.status, json: await res.json() };
  };
  return { db, call, logs };
}

export function seed(db: MockDb) {
  db.tables.transactions = [
    {
      id: "t1",
      user_id: ALICE,
      amount: 250,
      is_income: false,
      category: "Food",
      account: "Cash",
      title: "Lunch",
      note: "SECRET-NOTE",
      occurred_at: "2026-10-05T07:00:00.000Z",
      schedule_type: "normal",
      paid: true,
    },
    {
      id: "t2",
      user_id: ALICE,
      amount: 50000,
      is_income: true,
      category: "Salary",
      account: "Bank",
      title: "Salary",
      note: "",
      occurred_at: "2026-10-01T04:00:00.000Z",
      schedule_type: "normal",
      paid: true,
    },
    {
      id: "t3",
      user_id: ALICE,
      amount: 1200,
      is_income: false,
      category: "Rent",
      account: "Bank",
      title: "Rent",
      note: "",
      occurred_at: "2026-10-28T04:00:00.000Z",
      schedule_type: "scheduled",
      paid: false,
      recurrence: "monthly",
    },
    {
      id: "t4",
      user_id: BOB,
      amount: 999,
      is_income: false,
      category: "Food",
      account: "Cash",
      title: "Bob",
      note: "",
      occurred_at: "2026-10-05T07:00:00.000Z",
      schedule_type: "normal",
      paid: true,
    },
  ];
  db.tables.habits = [
    {
      id: "11111111-1111-4111-8111-111111111111",
      user_id: ALICE,
      name: "Read",
      kind: "positive",
      interval: "daily",
      target_per_day: 1,
      archived: false,
      sort_order: 0,
    },
  ];
  db.tables.habit_completions = [
    { habit_id: "11111111-1111-4111-8111-111111111111", user_id: ALICE, day: "2026-10-20", value: 1 },
    { habit_id: "11111111-1111-4111-8111-111111111111", user_id: ALICE, day: "2026-10-21", value: 1 },
  ];
  db.tables.prayer_logs = [
    { user_id: ALICE, day: "2026-10-21", prayer: "fajr", status: "withGroup" },
    { user_id: ALICE, day: "2026-10-21", prayer: "isha", status: "missed" },
  ];
  db.tables.movies = [
    {
      id: "m1",
      user_id: ALICE,
      title: "Dune",
      media_type: "movie",
      watch_status: "watched",
      watched_at: "2026-10-10T15:00:00.000Z",
      updated_at: "2026-10-10",
    },
    {
      id: "m2",
      user_id: ALICE,
      title: "Arrival",
      media_type: "movie",
      watch_status: "wantToWatch",
      updated_at: "2026-10-11",
    },
  ];
}
