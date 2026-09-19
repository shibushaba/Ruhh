-- Sync payload support for objectives and category budget limits (stored in ruhh_push JSON blob)

create table if not exists public.budget_objectives (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  target_amount numeric not null,
  kind text not null default 'savings',
  wallet_name text not null default 'Cash',
  color_value int not null default 0,
  pinned boolean not null default true,
  archived boolean not null default false,
  end_date timestamptz,
  sort_order int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.category_budget_limits (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  budget_remote_id text not null,
  category_name text not null,
  limit_amount numeric not null,
  updated_at timestamptz not null default now()
);

alter table public.transactions
  add column if not exists title text not null default '',
  add column if not exists schedule_type text not null default 'normal',
  add column if not exists paid boolean not null default true,
  add column if not exists recurrence text not null default 'none',
  add column if not exists period_length int not null default 1,
  add column if not exists recurrence_end timestamptz,
  add column if not exists objective_remote_id text;

-- Extend push/pull to persist new payload keys (mirrors 20260319103000 pattern)

create or replace function public.ruhh_pull(p_user_id uuid, p_pin_hash text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.ruhh_verify_user(p_user_id, p_pin_hash) then
    raise exception 'unauthorized';
  end if;

  return jsonb_build_object(
    'preferences', coalesce(
      (select u.preferences from public.users u where u.id = p_user_id),
      '{}'::jsonb
    ),
    'objectives', coalesce((
      select jsonb_agg(to_jsonb(o) - 'user_id')
      from public.budget_objectives o where o.user_id = p_user_id
    ), '[]'::jsonb),
    'category_budget_limits', coalesce((
      select jsonb_agg(to_jsonb(c) - 'user_id')
      from public.category_budget_limits c where c.user_id = p_user_id
    ), '[]'::jsonb),
    'transactions', coalesce((
      select jsonb_agg(to_jsonb(t) - 'user_id')
      from public.transactions t where t.user_id = p_user_id
    ), '[]'::jsonb),
    'habits', coalesce((
      select jsonb_agg(to_jsonb(h) - 'user_id')
      from public.habits h where h.user_id = p_user_id
    ), '[]'::jsonb),
    'habit_completions', coalesce((
      select jsonb_agg(to_jsonb(c) - 'user_id')
      from public.habit_completions c where c.user_id = p_user_id
    ), '[]'::jsonb),
    'prayer_logs', coalesce((
      select jsonb_agg(to_jsonb(p) - 'user_id')
      from public.prayer_logs p where p.user_id = p_user_id
    ), '[]'::jsonb),
    'movies', coalesce((
      select jsonb_agg(to_jsonb(m) - 'user_id')
      from public.movies m where m.user_id = p_user_id
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.ruhh_push(p_user_id uuid, p_pin_hash text, p_payload jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  row jsonb;
begin
  if not public.ruhh_verify_user(p_user_id, p_pin_hash) then
    raise exception 'unauthorized';
  end if;

  if p_payload ? 'preferences' then
    update public.users
    set preferences = coalesce(p_payload->'preferences', '{}'::jsonb)
    where id = p_user_id;
  end if;

  for row in select * from jsonb_array_elements(coalesce(p_payload->'objectives', '[]'::jsonb))
  loop
    insert into public.budget_objectives (
      id, user_id, name, target_amount, kind, wallet_name, color_value,
      pinned, archived, end_date, sort_order, updated_at
    ) values (
      (row->>'id')::uuid,
      p_user_id,
      row->>'name',
      (row->>'target_amount')::numeric,
      coalesce(row->>'kind', 'savings'),
      coalesce(row->>'wallet_name', 'Cash'),
      coalesce((row->>'color_value')::int, 0),
      coalesce((row->>'pinned')::boolean, true),
      coalesce((row->>'archived')::boolean, false),
      nullif(row->>'end_date', '')::timestamptz,
      coalesce((row->>'sort_order')::int, 0),
      coalesce((row->>'updated_at')::timestamptz, now())
    )
    on conflict (id) do update set
      name = excluded.name,
      target_amount = excluded.target_amount,
      kind = excluded.kind,
      wallet_name = excluded.wallet_name,
      color_value = excluded.color_value,
      pinned = excluded.pinned,
      archived = excluded.archived,
      end_date = excluded.end_date,
      sort_order = excluded.sort_order,
      updated_at = excluded.updated_at;
  end loop;

  for row in select * from jsonb_array_elements(coalesce(p_payload->'category_budget_limits', '[]'::jsonb))
  loop
    insert into public.category_budget_limits (
      id, user_id, budget_remote_id, category_name, limit_amount, updated_at
    ) values (
      (row->>'id')::uuid,
      p_user_id,
      row->>'budget_remote_id',
      row->>'category_name',
      (row->>'limit_amount')::numeric,
      coalesce((row->>'updated_at')::timestamptz, now())
    )
    on conflict (id) do update set
      budget_remote_id = excluded.budget_remote_id,
      category_name = excluded.category_name,
      limit_amount = excluded.limit_amount,
      updated_at = excluded.updated_at;
  end loop;

  for row in select * from jsonb_array_elements(coalesce(p_payload->'transactions', '[]'::jsonb))
  loop
    insert into public.transactions (
      id, user_id, amount, is_income, category, account, note, occurred_at, updated_at,
      title, schedule_type, paid, recurrence, period_length, recurrence_end, objective_remote_id
    ) values (
      (row->>'id')::uuid,
      p_user_id,
      (row->>'amount')::numeric,
      coalesce((row->>'is_income')::boolean, false),
      row->>'category',
      coalesce(row->>'account', 'Cash'),
      coalesce(row->>'note', ''),
      (row->>'occurred_at')::timestamptz,
      coalesce((row->>'updated_at')::timestamptz, now()),
      coalesce(row->>'title', ''),
      coalesce(row->>'schedule_type', 'normal'),
      coalesce((row->>'paid')::boolean, true),
      coalesce(row->>'recurrence', 'none'),
      coalesce((row->>'period_length')::int, 1),
      nullif(row->>'recurrence_end', '')::timestamptz,
      nullif(row->>'objective_remote_id', '')
    )
    on conflict (id) do update set
      amount = excluded.amount,
      is_income = excluded.is_income,
      category = excluded.category,
      account = excluded.account,
      note = excluded.note,
      occurred_at = excluded.occurred_at,
      updated_at = excluded.updated_at,
      title = excluded.title,
      schedule_type = excluded.schedule_type,
      paid = excluded.paid,
      recurrence = excluded.recurrence,
      period_length = excluded.period_length,
      recurrence_end = excluded.recurrence_end,
      objective_remote_id = excluded.objective_remote_id;
  end loop;

  for row in select * from jsonb_array_elements(coalesce(p_payload->'habits', '[]'::jsonb))
  loop
    insert into public.habits (
      id, user_id, name, color_value, frequency, target_per_day, reminder_minute, archived, updated_at
    ) values (
      (row->>'id')::uuid,
      p_user_id,
      row->>'name',
      (row->>'color_value')::int,
      coalesce(row->>'frequency', 'daily'),
      coalesce((row->>'target_per_day')::int, 1),
      nullif(row->>'reminder_minute', '')::int,
      coalesce((row->>'archived')::boolean, false),
      coalesce((row->>'updated_at')::timestamptz, now())
    )
    on conflict (id) do update set
      name = excluded.name,
      color_value = excluded.color_value,
      frequency = excluded.frequency,
      target_per_day = excluded.target_per_day,
      reminder_minute = excluded.reminder_minute,
      archived = excluded.archived,
      updated_at = excluded.updated_at;
  end loop;

  for row in select * from jsonb_array_elements(coalesce(p_payload->'habit_completions', '[]'::jsonb))
  loop
    insert into public.habit_completions (id, habit_id, user_id, day, value)
    values (
      (row->>'id')::uuid,
      (row->>'habit_id')::uuid,
      p_user_id,
      (row->>'day')::date,
      coalesce((row->>'value')::double precision, 1)
    )
    on conflict (id) do update set value = excluded.value;
  end loop;

  for row in select * from jsonb_array_elements(coalesce(p_payload->'prayer_logs', '[]'::jsonb))
  loop
    insert into public.prayer_logs (id, user_id, day, prayer, status)
    values (
      (row->>'id')::uuid,
      p_user_id,
      (row->>'day')::date,
      row->>'prayer',
      row->>'status'
    )
    on conflict (id) do update set status = excluded.status;
  end loop;

  for row in select * from jsonb_array_elements(coalesce(p_payload->'movies', '[]'::jsonb))
  loop
    insert into public.movies (
      id, user_id, tmdb_id, title, poster_path, media_type, watch_status, overview, updated_at
    ) values (
      (row->>'id')::uuid,
      p_user_id,
      nullif(row->>'tmdb_id', '')::int,
      row->>'title',
      nullif(row->>'poster_path', ''),
      coalesce(row->>'media_type', 'movie'),
      row->>'watch_status',
      nullif(row->>'overview', ''),
      coalesce((row->>'updated_at')::timestamptz, now())
    )
    on conflict (id) do update set
      tmdb_id = excluded.tmdb_id,
      title = excluded.title,
      poster_path = excluded.poster_path,
      media_type = excluded.media_type,
      watch_status = excluded.watch_status,
      overview = excluded.overview,
      updated_at = excluded.updated_at;
  end loop;
end;
$$;
