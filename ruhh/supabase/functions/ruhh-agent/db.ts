// Data-access contract for ruhh-agent. The real implementation uses the service role
// (server-side only); tests use an in-memory mock with the same semantics.

export interface Credential {
  id: string;
  user_id: string;
  token_hash: string;
  scopes: string[];
  expires_at: string | null;
  revoked_at: string | null;
}

export interface QuerySpec {
  table: string;
  columns: string;
  eq?: Record<string, string | number | boolean>;
  gte?: [string, string];
  lte?: [string, string];
  inList?: [string, string[]];
  order?: [string, boolean]; // [column, ascending]
  limit: number;
}

export interface AuditRow {
  credential_id: string | null;
  user_id: string | null;
  request_id: string | null;
  op: string | null;
  outcome: "ok" | "error" | "denied" | "rate_limited" | "replay";
  error_code: string | null;
  duration_ms: number;
}

export interface AgentDb {
  credentialByHash(hash: string): Promise<Credential | null>;
  touchCredential(id: string): Promise<void>;
  recentRequestCount(credentialId: string, seconds: number): Promise<number>;
  audit(row: AuditRow): Promise<void>;
  /** Always scoped: implementations MUST add user_id = userId. */
  select(userId: string, spec: QuerySpec): Promise<Record<string, unknown>[]>;
  getReplay(credentialId: string, requestId: string): Promise<unknown | null>;
  saveReplay(credentialId: string, requestId: string, op: string, response: unknown): Promise<void>;
  rpc(fn: string, args: Record<string, unknown>): Promise<unknown>;
}

export const ALLOWED_TABLES = new Set([
  "transactions",
  "budget_objectives",
  "category_budget_limits",
  "habits",
  "habit_completions",
  "prayer_logs",
  "movies",
  "ruhh_agent_proposals",
]);

// ruhh_agent_proposal_decide (approve) is deliberately absent: the agent cannot approve.
export const ALLOWED_RPCS = new Set([
  "ruhh_inbox_enqueue",
  "ruhh_agent_proposal_create",
  "ruhh_agent_proposal_reject",
]);
