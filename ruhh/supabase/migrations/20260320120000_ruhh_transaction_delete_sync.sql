-- Sync transaction deletes: remote rows not in push payload are removed.

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

  delete from public.transactions t
  where t.user_id = p_user_id
    and not exists (
      select 1
      from jsonb_array_elements(coalesce(p_payload->'transactions', '[]'::jsonb)) elem
      where (elem->>'id')::uuid = t.id
    );

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
