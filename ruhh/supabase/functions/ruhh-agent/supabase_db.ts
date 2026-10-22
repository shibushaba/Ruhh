import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import {
  type AgentDb,
  ALLOWED_RPCS,
  ALLOWED_TABLES,
  type AuditRow,
  type Credential,
  type QuerySpec,
  type Replay,
} from "./db.ts";

/** Service-role adapter. The key is read from the function environment only. */
export function createSupabaseDb(): AgentDb {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) throw new Error("server_misconfigured");
  const sb: SupabaseClient = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const fail = (e: unknown): never => {
    // never forward DB error text (may contain data) to callers or logs
    void e;
    throw new Error("db_error");
  };

  return {
    async credentialByHash(hash) {
      const { data, error } = await sb.from("ruhh_agent_credentials")
        .select("id,user_id,token_hash,scopes,expires_at,revoked_at")
        .eq("token_hash", hash).maybeSingle();
      if (error) fail(error);
      return (data as Credential | null) ?? null;
    },
    async touchCredential(id) {
      await sb.from("ruhh_agent_credentials").update({ last_used_at: new Date().toISOString() }).eq("id", id);
    },
    async recentRequestCount(credentialId, seconds) {
      const since = new Date(Date.now() - seconds * 1000).toISOString();
      const { count, error } = await sb.from("ruhh_agent_audit")
        .select("id", { count: "exact", head: true })
        .eq("credential_id", credentialId).gte("created_at", since);
      if (error) fail(error);
      return count ?? 0;
    },
    async audit(row: AuditRow) {
      await sb.from("ruhh_agent_audit").insert(row);
    },
    async select(userId: string, spec: QuerySpec) {
      if (!ALLOWED_TABLES.has(spec.table)) throw new Error("table_not_allowed");
      let q = sb.from(spec.table).select(spec.columns).eq("user_id", userId);
      for (const [k, v] of Object.entries(spec.eq ?? {})) q = q.eq(k, v);
      if (spec.gte) q = q.gte(spec.gte[0], spec.gte[1]);
      if (spec.lte) q = q.lte(spec.lte[0], spec.lte[1]);
      if (spec.inList) q = q.in(spec.inList[0], spec.inList[1]);
      if (spec.order) q = q.order(spec.order[0], { ascending: spec.order[1] });
      const { data, error } = await q.limit(spec.limit);
      if (error) fail(error);
      return (data ?? []) as unknown as Record<string, unknown>[];
    },
    async getReplay(credentialId, requestId) {
      const { data, error } = await sb.from("ruhh_agent_requests").select("op,params_hash,response")
        .eq("credential_id", credentialId).eq("request_id", requestId).maybeSingle();
      if (error) fail(error);
      return data ? (data as unknown as Replay) : null;
    },
    async saveReplay(credentialId, requestId, op, paramsHash, response) {
      await sb.from("ruhh_agent_requests").upsert(
        { credential_id: credentialId, request_id: requestId, op, params_hash: paramsHash, response },
        { onConflict: "credential_id,request_id", ignoreDuplicates: true },
      );
    },
    async rpc(fn, args) {
      if (!ALLOWED_RPCS.has(fn)) throw new Error("rpc_not_allowed");
      const { data, error } = await sb.rpc(fn, args);
      if (error) {
        const m = String(error.message ?? "");
        // pass through known short codes raised by our SQL functions only
        const known = m.match(/^(inbox_full|proposal_[a-z_]+|target_not_found)$/);
        throw new Error(known ? known[1] : "db_error");
      }
      return data;
    },
  };
}
