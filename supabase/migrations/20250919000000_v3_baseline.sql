create extension if not exists "pgcrypto" with schema extensions;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_state') THEN
    CREATE TYPE booking_state AS ENUM ( 'requested','pending_payment','confirmed','cancelled' );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_state') THEN
    CREATE TYPE booking_state AS ENUM ( 'requested','pending_payment','confirmed','cancelled' );
  END IF;
END $$;
-- core

create table if not exists patients (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid unique,
  created_at timestamptz default now()
);

create table if not exists practitioners (
  id uuid primary key default extensions.gen_random_uuid(),
  first_name text not null,
  last_name  text not null,
  npi text,
  in_network boolean default true,
  telehealth boolean default true,
  specialties text[] default '{}',
  languages  text[] default '{}',
  created_at timestamptz default now()
);


create table if not exists bookings (
  id uuid primary key default extensions.gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  practitioner_id uuid not null references practitioners(id) on delete cascade,
  slot timestamptz not null,
  state booking_state not null default 'requested',
  stripe_pi_id text,
  created_at timestamptz default now()
);

create table if not exists eligibility_snapshots (
  id uuid primary key default extensions.gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  payer_id text,
  active boolean,
  coinsurance numeric,
  deductible_remaining numeric,
  created_at timestamptz default now()
);

-- indexes
create index if not exists idx_bookings_pract   on bookings(practitioner_id);

-- RLS
alter table patients enable row level security;
alter table practitioners enable row level security;
alter table bookings enable row level security;
alter table eligibility_snapshots enable row level security;

-- simple policies for scaffolding (tighten later)
create policy "read_practitioners_public"
  on practitioners for select
  to anon, authenticated
  using (true);

create policy "patient_reads_own"
  on patients for select
  to authenticated
  using (auth.uid() = user_id);

create policy "patient_reads_own_elig"
  on eligibility_snapshots for select
  to authenticated
  using (exists (select 1 from patients p where p.id = eligibility_snapshots.patient_id and p.user_id = auth.uid()));

-- write policies will be added later via RPC

-- guard index creation to avoid failures when table pre-exists
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

-- guarded bookings indexes
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='bookings' and column_name='patient_id'
  ) then
    create index if not exists idx_bookings_patient on bookings(patient_id);
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='bookings' and column_name='practitioner_id'
  ) then
    create index if not exists idx_bookings_practitioner on bookings(practitioner_id);
  end if;
end$$;

-- guarded bookings indexes
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='bookings' and column_name='patient_id'
  ) then
    create index if not exists idx_bookings_patient on bookings(patient_id);
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='bookings' and column_name='practitioner_id'
  ) then
    create index if not exists idx_bookings_practitioner on bookings(practitioner_id);
  end if;
end$$;
