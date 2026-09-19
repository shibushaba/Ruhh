-- Extended habit + movie columns to match app sync payload (Streak + Movie tracker)

alter table public.habits
  add column if not exists icon text not null default 'target',
  add column if not exists kind text not null default 'positive',
  add column if not exists "interval" text not null default 'daily',
  add column if not exists target_frequency int not null default 1,
  add column if not exists schedule_weekdays jsonb not null default '[]'::jsonb,
  add column if not exists schedule_every int not null default 2,
  add column if not exists schedule_unit text not null default 'days',
  add column if not exists increment_amount double precision not null default 1,
  add column if not exists unit_label text not null default '',
  add column if not exists description text not null default '',
  add column if not exists rest_days jsonb not null default '[]'::jsonb,
  add column if not exists vacations_json text not null default '[]',
  add column if not exists reminders_json text not null default '[]',
  add column if not exists sort_order int not null default 0,
  add column if not exists created_at timestamptz not null default now();

alter table public.movies
  add column if not exists backdrop_path text,
  add column if not exists release_date text,
  add column if not exists vote_average double precision,
  add column if not exists user_rating double precision,
  add column if not exists user_review text not null default '',
  add column if not exists liked boolean not null default false,
  add column if not exists favorite boolean not null default false,
  add column if not exists watched_at timestamptz;

-- ruhh_pull already uses to_jsonb(*) — new columns appear automatically.

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
      id, user_id, name, color_value, icon, kind, "interval", target_frequency,
      schedule_weekdays, schedule_every, schedule_unit, target_per_day,
      increment_amount, unit_label, description, frequency, reminder_minute,
      rest_days, vacations_json, reminders_json, archived, sort_order,
      created_at, updated_at
    ) values (
      (row->>'id')::uuid,
      p_user_id,
      row->>'name',
      coalesce((row->>'color_value')::int, 0),
      coalesce(row->>'icon', 'target'),
      coalesce(row->>'kind', 'positive'),
      coalesce(row->>'interval', coalesce(row->>'frequency', 'daily')),
      coalesce((row->>'target_frequency')::int, 1),
      coalesce(row->'schedule_weekdays', '[]'::jsonb),
      coalesce((row->>'schedule_every')::int, 2),
      coalesce(row->>'schedule_unit', 'days'),
      coalesce((row->>'target_per_day')::int, 1),
      coalesce((row->>'increment_amount')::double precision, 1),
      coalesce(row->>'unit_label', ''),
      coalesce(row->>'description', ''),
      coalesce(row->>'frequency', 'daily'),
      nullif(row->>'reminder_minute', '')::int,
      coalesce(row->'rest_days', '[]'::jsonb),
      coalesce(row->>'vacations_json', '[]'),
      coalesce(row->>'reminders_json', '[]'),
      coalesce((row->>'archived')::boolean, false),
      coalesce((row->>'sort_order')::int, 0),
      coalesce((row->>'created_at')::timestamptz, coalesce((row->>'updated_at')::timestamptz, now())),
      coalesce((row->>'updated_at')::timestamptz, now())
    )
    on conflict (id) do update set
      name = excluded.name,
      color_value = excluded.color_value,
      icon = excluded.icon,
      kind = excluded.kind,
      "interval" = excluded."interval",
      target_frequency = excluded.target_frequency,
      schedule_weekdays = excluded.schedule_weekdays,
      schedule_every = excluded.schedule_every,
      schedule_unit = excluded.schedule_unit,
      target_per_day = excluded.target_per_day,
      increment_amount = excluded.increment_amount,
      unit_label = excluded.unit_label,
      description = excluded.description,
      frequency = excluded.frequency,
      reminder_minute = excluded.reminder_minute,
      rest_days = excluded.rest_days,
      vacations_json = excluded.vacations_json,
      reminders_json = excluded.reminders_json,
      archived = excluded.archived,
      sort_order = excluded.sort_order,
      created_at = excluded.created_at,
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
      id, user_id, tmdb_id, title, poster_path, backdrop_path, media_type,
      watch_status, overview, release_date, vote_average, user_rating,
      user_review, liked, favorite, watched_at, updated_at
    ) values (
      (row->>'id')::uuid,
      p_user_id,
      nullif(row->>'tmdb_id', '')::int,
      row->>'title',
      nullif(row->>'poster_path', ''),
      nullif(row->>'backdrop_path', ''),
      coalesce(row->>'media_type', 'movie'),
      row->>'watch_status',
      nullif(row->>'overview', ''),
      nullif(row->>'release_date', ''),
      nullif(row->>'vote_average', '')::double precision,
      nullif(row->>'user_rating', '')::double precision,
      coalesce(row->>'user_review', ''),
      coalesce((row->>'liked')::boolean, false),
      coalesce((row->>'favorite')::boolean, false),
      nullif(row->>'watched_at', '')::timestamptz,
      coalesce((row->>'updated_at')::timestamptz, now())
    )
    on conflict (id) do update set
      tmdb_id = excluded.tmdb_id,
      title = excluded.title,
      poster_path = excluded.poster_path,
      backdrop_path = excluded.backdrop_path,
      media_type = excluded.media_type,
      watch_status = excluded.watch_status,
      overview = excluded.overview,
      release_date = excluded.release_date,
      vote_average = excluded.vote_average,
      user_rating = excluded.user_rating,
      user_review = excluded.user_review,
      liked = excluded.liked,
      favorite = excluded.favorite,
      watched_at = excluded.watched_at,
      updated_at = excluded.updated_at;
  end loop;
end;
$$;
