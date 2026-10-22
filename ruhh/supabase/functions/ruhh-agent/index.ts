// Supabase Edge Function: ruhh-agent (read-only in this commit).
// Auth: "Authorization: Bearer ruhh_agent_<64 hex>" — a dedicated, revocable agent
// credential (ruhh_agent_credentials). verify_jwt is disabled in config.toml because
// this function performs its own authentication; the service role key never leaves it.
import { createHandler } from "./handler.ts";
import { readOps } from "./ops_read.ts";
import { createSupabaseDb } from "./supabase_db.ts";

const offset = Number(Deno.env.get("RUHH_AGENT_DEFAULT_UTC_OFFSET_MIN") ?? "0");

const handler = createHandler({
  db: createSupabaseDb(),
  ops: { ...readOps },
  defaultUtcOffsetMinutes: Number.isInteger(offset) && offset >= -720 && offset <= 840 ? offset : 0,
});

Deno.serve(handler);
