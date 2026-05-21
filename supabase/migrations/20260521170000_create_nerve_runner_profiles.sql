create table if not exists public.nerve_runner_profiles (
  player_id uuid primary key references auth.users(id) on delete cascade,
  save_data jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.nerve_runner_profiles enable row level security;

drop policy if exists "Players can read their own Nerve Runner save"
  on public.nerve_runner_profiles;
drop policy if exists "Players can insert their own Nerve Runner save"
  on public.nerve_runner_profiles;
drop policy if exists "Players can update their own Nerve Runner save"
  on public.nerve_runner_profiles;

create policy "Players can read their own Nerve Runner save"
  on public.nerve_runner_profiles
  for select
  to authenticated
  using (auth.uid() = player_id);

create policy "Players can insert their own Nerve Runner save"
  on public.nerve_runner_profiles
  for insert
  to authenticated
  with check (auth.uid() = player_id);

create policy "Players can update their own Nerve Runner save"
  on public.nerve_runner_profiles
  for update
  to authenticated
  using (auth.uid() = player_id)
  with check (auth.uid() = player_id);
