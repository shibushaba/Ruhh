-- RUHH remote schema, RLS, and SECURITY DEFINER RPCs (username + PIN auth via anon client)

create extension if not exists "pgcrypto";

create table if not exists public.users (
  id uuid primary key,
  username text unique not null,
  pin_hash text not null,
  pin_salt text not null,
  created_at timestamptz not null default now()
);

create index if not exists users_username_lower_idx on public.users (lower(username));

create table if not exists public.transactions (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  amount numeric not null,
  is_income boolean not null default false,
  category text not null,
  account text not null default 'Cash',
  note text not null default '',
  occurred_at timestamptz not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.habits (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  color_value int not null,
  frequency text not null default 'daily',
  target_per_day int not null default 1,
  reminder_minute int,
  archived boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.habit_completions (
  id uuid primary key,
  habit_id uuid not null references public.habits(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  day date not null,
  value double precision not null default 1,
  unique (habit_id, day)
);

create table if not exists public.prayer_logs (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  day date not null,
  prayer text not null,
  status text not null,
  unique (user_id, day, prayer)
);

create table if not exists public.movies (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  tmdb_id int,
  title text not null,
  poster_path text,
  media_type text not null default 'movie',
  watch_status text not null,
  overview text,
  updated_at timestamptz not null default now()
);

alter table public.users enable row level security;
alter table public.transactions enable row level security;
alter table public.habits enable row level security;
alter table public.habit_completions enable row level security;
alter table public.prayer_logs enable row level security;
alter table public.movies enable row level security;

revoke all on public.users from anon, authenticated;
revoke all on public.transactions from anon, authenticated;
revoke all on public.habits from anon, authenticated;
revoke all on public.habit_completions from anon, authenticated;
revoke all on public.prayer_logs from anon, authenticated;
revoke all on public.movies from anon, authenticated;

create or replace function public.ruhh_verify_user(p_user_id uuid, p_pin_hash text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where u.id = p_user_id and u.pin_hash = p_pin_hash
  );
$$;

create or replace function public.ruhh_is_username_available(p_username text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select not exists (
    select 1 from public.users u where lower(u.username) = lower(trim(p_username))
  );
$$;

create or replace function public.ruhh_register_user(
  p_id uuid,
  p_username text,
  p_pin_hash text,
  p_pin_salt text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text := lower(trim(p_username));
begin
  if char_length(v_username) < 3 then
    raise exception 'username_too_short';
  end if;
  if exists (select 1 from public.users u where lower(u.username) = v_username) then
    raise exception 'username_taken';
  end if;
  insert into public.users (id, username, pin_hash, pin_salt)
  values (p_id, v_username, p_pin_hash, p_pin_salt);
  return p_id;
end;
$$;

create or replace function public.ruhh_fetch_auth_profile(p_username text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'id', u.id,
        'username', u.username,
        'pin_hash', u.pin_hash,
        'pin_salt', u.pin_salt
      )
      from public.users u
      where lower(u.username) = lower(trim(p_username))
    ),
    'null'::jsonb
  );
$$;

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

  for row in select * from jsonb_array_elements(coalesce(p_payload->'transactions', '[]'::jsonb))
  loop
    insert into public.transactions (
      id, user_id, amount, is_income, category, account, note, occurred_at, updated_at
    ) values (
      (row->>'id')::uuid,
      p_user_id,
      (row->>'amount')::numeric,
      coalesce((row->>'is_income')::boolean, false),
      row->>'category',
      coalesce(row->>'account', 'Cash'),
      coalesce(row->>'note', ''),
      (row->>'occurred_at')::timestamptz,
      coalesce((row->>'updated_at')::timestamptz, now())
    )
    on conflict (id) do update set
      amount = excluded.amount,
      is_income = excluded.is_income,
      category = excluded.category,
      account = excluded.account,
      note = excluded.note,
      occurred_at = excluded.occurred_at,
      updated_at = excluded.updated_at;
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

grant execute on function public.ruhh_is_username_available(text) to anon, authenticated;
grant execute on function public.ruhh_register_user(uuid, text, text, text) to anon, authenticated;
grant execute on function public.ruhh_fetch_auth_profile(text) to anon, authenticated;
grant execute on function public.ruhh_pull(uuid, text) to anon, authenticated;
grant execute on function public.ruhh_push(uuid, text, jsonb) to anon, authenticated;
