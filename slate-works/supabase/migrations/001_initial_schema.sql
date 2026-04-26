-- Enable UUID extension
create extension if not exists "pgcrypto";

-- ============================================================
-- IDEAS
-- ============================================================
create table if not exists ideas (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  note text,
  tags text[],
  status text default 'Raw' check (status in ('Raw', 'Developing', 'Parked')),
  votes integer default 0,
  link text,
  created_by text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Auto-update updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger ideas_updated_at
  before update on ideas
  for each row
  execute function update_updated_at_column();

-- ============================================================
-- COMMENTS
-- ============================================================
create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  idea_id uuid references ideas(id) on delete cascade,
  author text,
  body text not null,
  created_at timestamptz default now()
);

-- ============================================================
-- CLUSTERS
-- ============================================================
create table if not exists clusters (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  idea_ids uuid[],
  generated_at timestamptz default now(),
  is_manual_override boolean default false
);

-- ============================================================
-- MORNING BRIEFS
-- ============================================================
create table if not exists morning_briefs (
  id uuid primary key default gen_random_uuid(),
  generated_at timestamptz default now(),
  digest_json jsonb,
  triggered_by text
);

-- ============================================================
-- TEAM MEMBERS
-- ============================================================
create table if not exists team_members (
  id uuid primary key default gen_random_uuid(),
  name text,
  email text unique,
  avatar_colour text
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table ideas enable row level security;
alter table comments enable row level security;
alter table clusters enable row level security;
alter table morning_briefs enable row level security;
alter table team_members enable row level security;

-- For a single shared workspace, authenticated users can do everything
create policy "Authenticated users can read ideas" on ideas
  for select using (auth.role() = 'authenticated');

create policy "Authenticated users can insert ideas" on ideas
  for insert with check (auth.role() = 'authenticated');

create policy "Authenticated users can update ideas" on ideas
  for update using (auth.role() = 'authenticated');

create policy "Authenticated users can delete ideas" on ideas
  for delete using (auth.role() = 'authenticated');

create policy "Authenticated users can read comments" on comments
  for select using (auth.role() = 'authenticated');

create policy "Authenticated users can insert comments" on comments
  for insert with check (auth.role() = 'authenticated');

create policy "Authenticated users can read clusters" on clusters
  for select using (auth.role() = 'authenticated');

create policy "Authenticated users can insert clusters" on clusters
  for insert with check (auth.role() = 'authenticated');

create policy "Authenticated users can update clusters" on clusters
  for update using (auth.role() = 'authenticated');

create policy "Authenticated users can read morning_briefs" on morning_briefs
  for select using (auth.role() = 'authenticated');

create policy "Authenticated users can insert morning_briefs" on morning_briefs
  for insert with check (auth.role() = 'authenticated');

create policy "Authenticated users can read team_members" on team_members
  for select using (auth.role() = 'authenticated');

-- ============================================================
-- REALTIME
-- ============================================================
-- Enable realtime for ideas table
alter publication supabase_realtime add table ideas;
alter publication supabase_realtime add table comments;

-- ============================================================
-- SEED DATA (optional demo ideas)
-- ============================================================
insert into ideas (title, note, tags, status, votes, created_by) values
  ('The Last Whaling Station', 'A small Norwegian town holds onto its whaling heritage as the world turns away. What does identity look like when your livelihood becomes a controversy?', array['environment', 'identity', 'Norway'], 'Developing', 7, 'team'),
  ('Sacred Algorithms', 'Faith communities building their own AI systems — from Mormon genealogy tools to Islamic fintech. Who owns the soul of the machine?', array['tech', 'religion', 'AI'], 'Raw', 4, 'team'),
  ('The Forgetting Curve', 'Following three people with early-stage dementia as they race to document their own memories before they lose them.', array['health', 'memory', 'personal'], 'Developing', 12, 'team'),
  ('Night Markets', 'An immersive portrait of the informal economy that feeds cities — from Manila to Lagos to Guadalajara — after midnight.', array['economy', 'food', 'cities'], 'Raw', 3, 'team'),
  ('Extinction Rehearsal', 'A theatre company in Vienna stages the last performances of dead languages. Every night, an audience grieves something they never knew.', array['language', 'culture', 'Europe'], 'Parked', 2, 'team')
  on conflict do nothing;
