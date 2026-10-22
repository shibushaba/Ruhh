import type { AgentDb, AuditRow } from "./db.ts";
import type { OpDef } from "./ops_read.ts";
import { ApiError, REQUEST_ID } from "./validate.ts";

export const MAX_BODY_BYTES = 4096;
export const RATE_LIMIT_PER_MINUTE = 30;
export const OP_TIMEOUT_MS = 8000;

export interface HandlerDeps {
  db: AgentDb;
  ops: Record<string, OpDef>;
  now?: () => Date;
  log?: (entry: Record<string, unknown>) => void;
  defaultUtcOffsetMinutes?: number;
  /** ops whose responses are stored for request_id replay (writes). */
  idempotentOps?: Set<string>;
}

const enc = new TextEncoder();

export async function sha256Hex(s: string): Promise<string> {
  const d = await crypto.subtle.digest("SHA-256", enc.encode(s));
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function timingSafeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

const TOKEN = /^ruhh_agent_[0-9a-f]{64}$/;

/** Canonical JSON (sorted keys) so the same params always hash the same. */
export function canonicalJson(v: unknown): string {
  if (Array.isArray(v)) return `[${v.map(canonicalJson).join(",")}]`;
  if (v && typeof v === "object") {
    const o = v as Record<string, unknown>;
    return `{${Object.keys(o).sort().map((k) => `${JSON.stringify(k)}:${canonicalJson(o[k])}`).join(",")}}`;
  }
  return JSON.stringify(v ?? null);
}

/** Reads at most [max] bytes; a larger (also chunked / no content-length) body is refused early. */
export async function readBodyCapped(req: Request, max: number): Promise<string> {
  if (!req.body) return "";
  const reader = req.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > max) {
        await reader.cancel().catch(() => {});
        throw new ApiError(413, "body_too_large");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const buf = new Uint8Array(total);
  let off = 0;
  for (const c of chunks) {
    buf.set(c, off);
    off += c.byteLength;
  }
  return new TextDecoder("utf-8", { fatal: true }).decode(buf);
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });
}

function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  let t: ReturnType<typeof setTimeout> | undefined;
  return Promise.race([
    p.finally(() => clearTimeout(t)),
    new Promise<T>((_, rej) => {
      t = setTimeout(() => rej(new ApiError(504, "timeout")), ms);
    }),
  ]);
}

export function createHandler(deps: HandlerDeps) {
  const now = deps.now ?? (() => new Date());
  const log = deps.log ?? ((e) => console.log(JSON.stringify(e)));

  return async function handle(req: Request): Promise<Response> {
    const started = Date.now();
    const audit: AuditRow = {
      credential_id: null,
      user_id: null,
      request_id: null,
      op: null,
      outcome: "error",
      error_code: null,
      duration_ms: 0,
    };
    let status = 200;
    let body: unknown;

    try {
      if (req.method !== "POST") throw new ApiError(405, "method_not_allowed");

      // --- authentication (before reading the body) ---
      const auth = req.headers.get("authorization") ?? "";
      const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
      if (!TOKEN.test(token)) throw new ApiError(401, "unauthorized");
      const hash = await sha256Hex(token);
      const cred = await deps.db.credentialByHash(hash);
      if (
        !cred || !timingSafeEqualHex(cred.token_hash, hash) || cred.revoked_at ||
        (cred.expires_at && Date.parse(cred.expires_at) <= now().getTime())
      ) {
        throw new ApiError(401, "unauthorized");
      }
      audit.credential_id = cred.id;
      audit.user_id = cred.user_id;

      // --- rate limit ---
      if (await deps.db.recentRequestCount(cred.id, 60) >= RATE_LIMIT_PER_MINUTE) {
        audit.outcome = "rate_limited";
        throw new ApiError(429, "rate_limited");
      }

      // --- body ---
      const len = Number(req.headers.get("content-length") ?? "0");
      if (len > MAX_BODY_BYTES) throw new ApiError(413, "body_too_large");
      let raw: string;
      try {
        raw = await readBodyCapped(req, MAX_BODY_BYTES);
      } catch (e) {
        if (e instanceof ApiError) throw e;
        throw new ApiError(400, "invalid_body");
      }
      let parsed: unknown;
      try {
        parsed = JSON.parse(raw);
      } catch {
        throw new ApiError(400, "invalid_json");
      }
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new ApiError(400, "invalid_body");
      const { op, params = {}, request_id, ...rest } = parsed as Record<string, unknown>;
      if (Object.keys(rest).length) throw new ApiError(400, "unknown_field");
      if (typeof request_id !== "string" || !REQUEST_ID.test(request_id)) throw new ApiError(400, "invalid_request_id");
      audit.request_id = request_id;
      if (typeof op !== "string" || !Object.hasOwn(deps.ops, op)) throw new ApiError(400, "unknown_op");
      audit.op = op;
      if (!params || typeof params !== "object" || Array.isArray(params)) throw new ApiError(400, "invalid_params");
      const def = deps.ops[op]!;

      // --- authorization (scopes) ---
      if (!cred.scopes.includes(def.scope)) {
        audit.outcome = "denied";
        throw new ApiError(403, "forbidden_scope");
      }

      // --- idempotent replay for writes ---
      const idem = deps.idempotentOps?.has(op) ?? false;
      const paramsHash = idem ? await sha256Hex(`${op}\n${canonicalJson(params)}`) : "";
      if (idem) {
        const prev = await deps.db.getReplay(cred.id, request_id);
        if (prev) {
          // Same request_id must mean the same op + params; anything else is a client bug
          // or an attempt to get a stored response for a different action.
          if (prev.op !== op || prev.params_hash !== paramsHash) {
            throw new ApiError(409, "request_id_reused");
          }
          audit.outcome = "replay";
          body = prev.response;
          return json(200, prev.response);
        }
      }

      const result = await withTimeout(
        def.run({
          db: deps.db,
          userId: cred.user_id,
          credentialId: cred.id,
          requestId: request_id,
          now: now(),
          utcOffsetMinutes: deps.defaultUtcOffsetMinutes ?? 0,
        }, params as Record<string, unknown>),
        OP_TIMEOUT_MS,
      );
      body = { ok: true, request_id, op, data: result.data, meta: result.meta };
      if (idem) await deps.db.saveReplay(cred.id, request_id, op, paramsHash, body);
      audit.outcome = "ok";
      await deps.db.touchCredential(cred.id).catch(() => {});
      return json(200, body);
    } catch (e) {
      const err = e instanceof ApiError ? e : new ApiError(
        500,
        e instanceof Error && /^(inbox_full|proposal_[a-z_]+|target_not_found)$/.test(e.message)
          ? e.message
          : "internal",
      );
      if (err.code === "inbox_full") err.status = 503;
      if (!(e instanceof ApiError) && (err.code.startsWith("proposal_") || err.code === "target_not_found")) {
        err.status = 409;
      }
      status = err.status;
      audit.error_code = err.code;
      if (audit.outcome === "error" && status === 401) audit.outcome = "denied";
      body = {
        ok: false,
        request_id: audit.request_id,
        error: { code: err.code, ...(err.detail ? { detail: err.detail } : {}) },
      };
      return json(status, body);
    } finally {
      audit.duration_ms = Date.now() - started;
      // metadata only — never params, amounts, titles, tokens
      log({
        evt: "ruhh_agent",
        op: audit.op,
        outcome: audit.outcome,
        code: audit.error_code,
        ms: audit.duration_ms,
        cred: audit.credential_id?.slice(0, 8) ?? null,
      });
      if (audit.credential_id) await deps.db.audit(audit).catch(() => {});
    }
  };
}
