# Local-only smoke test against the disposable `supabase start` stack. Synthetic data.
$ErrorActionPreference = 'Stop'
function Sql($q) { (docker exec supabase_db_ruhh psql -U postgres -d postgres -tAc $q).Trim() }
$api = 'http://127.0.0.1:54321'
$ErrorActionPreference = 'Continue'
$st = supabase status -o env 2>$null
$ErrorActionPreference = 'Stop'
$anon = ($st | Select-String '^ANON_KEY=').ToString().Split('=',2)[1].Trim('"')
$h = @{ apikey = $anon; Authorization = "Bearer $anon"; 'Content-Type' = 'application/json' }
function Rpc($fn, $body) { Invoke-RestMethod -Method Post -Uri "$api/rest/v1/rpc/$fn" -Headers $h -Body ($body | ConvertTo-Json -Depth 8 -Compress) }
$uid = [guid]::NewGuid().ToString()
$name = 'smoke_' + (Get-Random -Maximum 999999)
$reg = Rpc 'ruhh_register_user_v2' @{ p_id = $uid; p_username = $name; p_pin = '246810'; p_client_version = '1.0.31' }
"register_v2 ok=$($reg.ok) has_pin_hash=$([bool]$reg.pin_hash)"
$tok = $reg.token
# anon direct table access must fail
try { Invoke-RestMethod -Uri "$api/rest/v1/budget_objectives?select=*" -Headers $h | Out-Null; 'anon budget_objectives: ALLOWED (BAD)' } catch { "anon budget_objectives: denied ($($_.Exception.Response.StatusCode.value__))" }
try { Rpc 'ruhh_verify_user' @{ p_user_id = $uid; p_pin_hash = 'x' } | Out-Null; 'anon ruhh_verify_user: ALLOWED (BAD)' } catch { "anon ruhh_verify_user: denied ($($_.Exception.Response.StatusCode.value__))" }
$payload = @{ transactions = @(@{ id = [guid]::NewGuid().ToString(); amount = 420; category = 'Food'; occurred_at = '2026-10-20T08:00:00Z' }); habits = @(@{ id = '11111111-1111-4111-8111-111111111111'; name = 'Read'; color_value = 4294198070 }); prayer_logs = @(@{ id = [guid]::NewGuid().ToString(); day = '2026-10-21'; prayer = 'fajr'; status = 'withGroup' }) }
Rpc 'ruhh_push_v2' @{ p_token = $tok; p_payload = $payload } | Out-Null
$pull = Rpc 'ruhh_pull_v2' @{ p_token = $tok }
"pull_v2 transactions=$($pull.transactions.Count) habits=$($pull.habits.Count) prayers=$($pull.prayer_logs.Count)"
$cred = Sql "select ruhh_agent_credential_create('$uid','smoke',array['read','write'],1)::text" | ConvertFrom-Json
$ah = @{ Authorization = "Bearer $($cred.token)"; 'Content-Type' = 'application/json' }
function Agent($op, $params, $rid) { try { Invoke-RestMethod -Method Post -Uri "$api/functions/v1/ruhh-agent" -Headers $ah -Body (@{ op = $op; params = $params; request_id = $rid } | ConvertTo-Json -Depth 6 -Compress) } catch { $r = $_.ErrorDetails.Message; if ($r) { $r | ConvertFrom-Json } else { throw } } }
$s = Agent 'budget.summary' @{ from = '2026-10-01'; to = '2026-10-31'; utc_offset_minutes = 330 } 'smoke-0001'
"agent budget.summary ok=$($s.ok) expense_total=$($s.data.expense_total) range=$($s.meta.range.from)..$($s.meta.range.to)"
$m = Agent 'cross.monthly_report' @{ month = '2026-10' } 'smoke-0002'
"agent cross.monthly_report ok=$($m.ok) modules=$($m.meta.modules -join ',') prayer_logged=$($m.data.prayer.logged)"
$bad = try { Invoke-RestMethod -Method Post -Uri "$api/functions/v1/ruhh-agent" -Headers @{ Authorization = 'Bearer ruhh_agent_' + ('0' * 64) } -Body '{"op":"habit.list","request_id":"smoke-0003"}' } catch { $_.Exception.Response.StatusCode.value__ }
"agent bad token -> $bad"
if ($env:RUHH_SMOKE_WRITES -eq '1') {
  $w = Agent 'tx.add' @{ amount = 99; category = 'Food'; occurred_at = '2026-10-22T05:00:00Z' } 'smoke-w-0001'
  $w2 = Agent 'tx.add' @{ amount = 99; category = 'Food'; occurred_at = '2026-10-22T05:00:00Z' } 'smoke-w-0001'
  "agent tx.add ok=$($w.ok) inbox_id_same_on_replay=$($w.data.inbox_id -eq $w2.data.inbox_id)"
  $fetch = Rpc 'ruhh_inbox_fetch_v2' @{ p_token = $tok }
  "app inbox_fetch pending=$(@($fetch).Count)"
  $ack = Rpc 'ruhh_inbox_ack_v2' @{ p_token = $tok; p_results = @(@{ id = $fetch[0].id; status = 'applied' }) }
  "app inbox_ack updated=$ack"
  $txid = $pull.transactions[0].id
  $p = Agent 'tx.delete' @{ id = $txid } 'smoke-w-0002'
  "agent tx.delete -> proposal status=$($p.data.status) needs_approval=$($p.data.requires_approval)"
  "agent response contains params_hash: $([bool]($p | ConvertTo-Json -Depth 6 | Select-String 'params_hash'))"
  $agentApprove = Agent 'proposal.approve' @{ proposal_id = $p.data.proposal_id; params_hash = ('f' * 64) } 'smoke-w-0003'
  "agent proposal.approve -> $($agentApprove.error.code) (must be unknown_op)"
  $list = Rpc 'ruhh_proposals_list_v2' @{ p_token = $tok }
  $mine = @($list) | Where-Object { $_.id -eq $p.data.proposal_id }
  "app proposals_list_v2 sees proposal=$([bool]$mine) target_kind=$($mine.target.kind)"
  try { Rpc 'ruhh_proposal_decide_v2' @{ p_token = $tok; p_proposal_id = $mine.id; p_params_hash = ('0' * 64); p_decision = 'approve' } | Out-Null; 'app approve altered hash: ACCEPTED (BAD)' } catch { "app approve altered hash -> $(($_.ErrorDetails.Message | ConvertFrom-Json).message)" }
  $ok = Rpc 'ruhh_proposal_decide_v2' @{ p_token = $tok; p_proposal_id = $mine.id; p_params_hash = $mine.params_hash; p_decision = 'approve' }
  "app approve exact (user session) -> status=$($ok.status)"
  try { Rpc 'ruhh_proposal_decide_v2' @{ p_token = $tok; p_proposal_id = $mine.id; p_params_hash = $mine.params_hash; p_decision = 'approve' } | Out-Null; 'app approve replay: ACCEPTED (BAD)' } catch { "app approve replay -> $(($_.ErrorDetails.Message | ConvertFrom-Json).message)" }
}
Sql "update ruhh_agent_credentials set revoked_at = now() where id = '$($cred.credential_id)'" | Out-Null
$rv = Agent 'habit.list' @{} 'smoke-0004'
"agent after revoke -> $($rv.error.code)"
$audit = Sql "select count(*) from ruhh_agent_audit where credential_id = '$($cred.credential_id)'"
$leak = Sql "select count(*) from ruhh_agent_audit a where a::text ilike '%420%' or a::text ilike '%Food%'"
"audit rows=$audit rows_with_amount_or_category=$leak"
