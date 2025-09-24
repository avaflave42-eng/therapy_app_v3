-- bring remote schema in line with v3
alter table if exists practitioners
  add column if not exists specialties text[] default '{}'::text[],
  add column if not exists languages  text[] default '{}'::text[],
  add column if not exists in_network boolean default true,
  add column if not exists telehealth boolean default true;

-- guard index creation on column presence
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='practitioners' and column_name='specialties'
  ) then
    create index if not exists idx_practitioners_specialties on practitioners using gin (specialties);
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='practitioners' and column_name='languages'
  ) then
    create index if not exists idx_practitioners_languages on practitioners using gin (languages);
  end if;
end$$;

-- ensure enum exists (idempotent)
do $$
begin
  if not exists (select 1 from pg_type where typname = 'booking_state') then
    create type booking_state as enum ('requested','pending_payment','confirmed','cancelled');
  end if;
end$$;

-- ensure bookings table has expected columns (safe-up)
alter table if exists bookings
  add column if not exists stripe_pi_id text,
  add column if not exists state booking_state default 'requested';

-- ensure bookings has FK columns we expect (no FKs yet to avoid data failures)
alter table if exists bookings
  add column if not exists patient_id uuid,
  add column if not exists practitioner_id uuid;

