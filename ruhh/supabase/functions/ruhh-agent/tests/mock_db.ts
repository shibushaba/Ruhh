import { type AgentDb, ALLOWED_RPCS, ALLOWED_TABLES, type AuditRow, type Credential, type QuerySpec } from "../db.ts";

export class MockDb implements AgentDb {
  creds: Credential[] = [];
  tables: Record<string, Record<string, unknown>[]> = {};
  audits: AuditRow[] = [];
  replays = new Map<string, unknown>();
  rpcCalls: { fn: string; args: Record<string, unknown> }[] = [];
  rpcImpl: (fn: string, args: Record<string, unknown>) => unknown = () => null;
  selects: { userId: string; spec: QuerySpec }[] = [];
  recentOverride: number | null = null;
  failSelect = false;
  slowMs = 0;

  credentialByHash(hash: string) {
    return Promise.resolve(this.creds.find((c) => c.token_hash === hash) ?? null);
  }
  touchCredential() {
    return Promise.resolve();
  }
  recentRequestCount(id: string) {
    return Promise.resolve(this.recentOverride ?? this.audits.filter((a) => a.credential_id === id).length);
  }
  audit(row: AuditRow) {
    this.audits.push({ ...row });
    return Promise.resolve();
  }
  async select(userId: string, spec: QuerySpec) {
    if (this.slowMs) await new Promise((r) => setTimeout(r, this.slowMs));
    if (this.failSelect) throw new Error("db_error");
    if (!ALLOWED_TABLES.has(spec.table)) throw new Error("table_not_allowed");
    this.selects.push({ userId, spec });
    let rows = (this.tables[spec.table] ?? []).filter((r) => r.user_id === userId);
    for (const [k, v] of Object.entries(spec.eq ?? {})) rows = rows.filter((r) => r[k] === v);
    if (spec.gte) rows = rows.filter((r) => r[spec.gte![0]] != null && String(r[spec.gte![0]]) >= spec.gte![1]);
    if (spec.lte) rows = rows.filter((r) => r[spec.lte![0]] != null && String(r[spec.lte![0]]) <= spec.lte![1]);
    if (spec.inList) rows = rows.filter((r) => spec.inList![1].includes(String(r[spec.inList![0]])));
    if (spec.order) {
      const [c, asc] = spec.order;
      rows = [...rows].sort((a, b) =>
        (String(a[c]) < String(b[c]) ? -1 : String(a[c]) > String(b[c]) ? 1 : 0) * (asc ? 1 : -1)
      );
    }
    const cols = spec.columns.split(",");
    return rows.slice(0, spec.limit).map((r) => Object.fromEntries(cols.map((c) => [c, r[c]])));
  }
  getReplay(c: string, r: string) {
    return Promise.resolve(this.replays.get(`${c}:${r}`) ?? null);
  }
  saveReplay(c: string, r: string, _op: string, resp: unknown) {
    if (!this.replays.has(`${c}:${r}`)) this.replays.set(`${c}:${r}`, resp);
    return Promise.resolve();
  }
  rpc(fn: string, args: Record<string, unknown>) {
    if (!ALLOWED_RPCS.has(fn)) return Promise.reject(new Error("rpc_not_allowed"));
    this.rpcCalls.push({ fn, args });
    try {
      return Promise.resolve(this.rpcImpl(fn, args));
    } catch (e) {
      return Promise.reject(e);
    }
  }
}
