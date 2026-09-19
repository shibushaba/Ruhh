-- Ledger fields + full payload reconciliation (deletes sync when rows omitted from push).

alter table public.transactions
  add column if not exists ledger_type text,
  add column if not exists category_remote_id text not null default '',
  add column if not exists is_auto_generated boolean not null default false;

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

  delete from public.budget_objectives o
  where o.user_id = p_user_id
    and not exists (
      select 1 from jsonb_array_elements(coalesce(p_payload->'objectives', '[]'::jsonb)) elem
      where (elem->>'id')::uuid = o.id
    );

  delete from public.category_budget_limits l
  where l.user_id = p_user_id
    and not exists (
      select 1 from jsonb_array_elements(coalesce(p_payload->'category_budget_limits', '[]'::jsonb)) elem
      where (elem->>'id')::uuid = l.id
    );

  delete from public.transactions t
  where t.user_id = p_user_id
    and not exists (
      select 1 from jsonb_array_elements(coalesce(p_payload->'transactions', '[]'::jsonb)) elem
      where (elem->>'id')::uuid = t.id
    );

  delete from public.habit_completions c
  where c.user_id = p_user_id
    and not exists (
      select 1 from jsonb_array_elements(coalesce(p_payload->'habit_completions', '[]'::jsonb)) elem
      where (elem->>'id')::uuid = c.id
    );

  delete from public.habits h
  where h.user_id = p_user_id
    and not exists (
      select 1 from jsonb_array_elements(coalesce(p_payload->'habits', '[]'::jsonb)) elem
      where (elem->>'id')::uuid = h.id
    );

  delete from public.prayer_logs p
  where p.user_id = p_user_id
    and not exists (
      select 1 from jsonb_array_elements(coalesce(p_payload->'prayer_logs', '[]'::jsonb)) elem
      where (elem->>'id')::uuid = p.id
    );

  delete from public.movies m
  where m.user_id = p_user_id
    and not exists (
      select 1 from jsonb_array_elements(coalesce(p_payload->'movies', '[]'::jsonb)) elem
      where (elem->>'id')::uuid = m.id
    );

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
      title, schedule_type, paid, recurrence, period_length, recurrence_end, objective_remote_id,
      ledger_type, category_remote_id, is_auto_generated
    ) values (
      (row->>'id')::uuid,
      p_user_id,
      (row->>'amount')::numeric,
      coalesce((row->>'is_income')::boolean, false),
      coalesce(nullif(row->>'category', ''), nullif(row->>'title', ''), 'Other'),
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
      nullif(row->>'objective_remote_id', ''),
      nullif(row->>'ledger_type', ''),
      coalesce(row->>'category_remote_id', ''),
      coalesce((row->>'is_auto_generated')::boolean, false)
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
      objective_remote_id = excluded.objective_remote_id,
      ledger_type = excluded.ledger_type,
      category_remote_id = excluded.category_remote_id,
      is_auto_generated = excluded.is_auto_generated;
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
      user_review, liked, favorite, watched_at,
      category_remote_id, priority, tracker_note,
      updated_at
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
      coalesce(row->>'category_remote_id', ''),
      coalesce((row->>'priority')::int, 3),
      coalesce(row->>'tracker_note', ''),
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
      category_remote_id = excluded.category_remote_id,
      priority = excluded.priority,
      tracker_note = excluded.tracker_note,
      updated_at = excluded.updated_at;
  end loop;
end;
$$;
