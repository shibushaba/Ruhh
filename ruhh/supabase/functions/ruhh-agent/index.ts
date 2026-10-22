// Supabase Edge Function: ruhh-agent.
// Auth: "Authorization: Bearer ruhh_agent_<64 hex>" — a dedicated, revocable agent
// credential (ruhh_agent_credentials, scopes read/write/approve). verify_jwt is disabled in
// config.toml because this function performs its own authentication; the service role
// key is read from the function environment and never leaves it.
// Writes never touch synced tables: they enqueue into ruhh_agent_inbox (see ops_write.ts).
import { createHandler } from "./handler.ts";
import { readOps } from "./ops_read.ts";
import { IDEMPOTENT_OPS, writeOps } from "./ops_write.ts";
import { createSupabaseDb } from "./supabase_db.ts";

const offset = Number(Deno.env.get("RUHH_AGENT_DEFAULT_UTC_OFFSET_MIN") ?? "0");
// Kill switch: set RUHH_AGENT_WRITES=off to serve read-only operations only.
const writesEnabled = (Deno.env.get("RUHH_AGENT_WRITES") ?? "off") === "on";

const handler = createHandler({
  db: createSupabaseDb(),
  ops: writesEnabled ? { ...readOps, ...writeOps } : { ...readOps },
  idempotentOps: IDEMPOTENT_OPS,
  defaultUtcOffsetMinutes: Number.isInteger(offset) && offset >= -720 && offset <= 840 ? offset : 0,
});

Deno.serve(handler);
