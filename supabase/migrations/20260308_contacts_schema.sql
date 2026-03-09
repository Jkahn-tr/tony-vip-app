-- Blaze VIP Contact Schema
-- Migration: 20260308_contacts_schema
-- Adds contact-centric tables to sit alongside the existing AI assistant schema

-- CONTACTS
create table if not exists contacts (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references users(id) on delete cascade,
  name            text not null,
  role            text,
  organization    text,
  phone           text,
  email           text,
  tier            text not null default 'Key Contact'
                    check (tier in ('Inner Circle', 'VIP', 'Key Contact')),
  avatar_color_hex text,
  avatar_initials text,
  tags            text[],
  last_contacted_at timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- CONTACT MESSAGES (distinct from AI conversation messages)
create table if not exists contact_messages (
  id              uuid primary key default gen_random_uuid(),
  contact_id      uuid references contacts(id) on delete cascade,
  body            text not null,
  is_from_tony    boolean not null default true,
  sent_at         timestamptz not null default now(),
  channel         text not null default 'blaze'
                    check (channel in ('blaze', 'sms', 'email')),
  is_read         boolean not null default false,
  bluebubbles_id  text
);

-- CONTACT NOTES
create table if not exists contact_notes (
  id              uuid primary key default gen_random_uuid(),
  contact_id      uuid references contacts(id) on delete cascade,
  body            text not null,
  is_pinned       boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- RELATIONSHIP HEALTH
create table if not exists relationship_health (
  id                      uuid primary key default gen_random_uuid(),
  contact_id              uuid references contacts(id) on delete cascade unique,
  health                  text not null default 'Good'
                            check (health in ('Strong', 'Good', 'Fading', 'Cold')),
  score                   float not null default 0.7,
  days_since_contact      int,
  alert_threshold_reached boolean not null default false,
  updated_at              timestamptz not null default now()
);

-- INTERACTION LOG (scoring engine feed)
create table if not exists interaction_log (
  id                uuid primary key default gen_random_uuid(),
  contact_id        uuid references contacts(id) on delete cascade,
  channel           text not null
                      check (channel in ('call', 'text', 'email', 'in_person', 'blaze')),
  duration_seconds  int,                      -- null for text/email
  initiated_by      text not null default 'tony'
                      check (initiated_by in ('tony', 'contact')),
  sentiment_score   float,                    -- V2: Claude sentiment analysis
  notes             text,
  occurred_at       timestamptz not null default now(),
  created_at        timestamptz not null default now()
);

-- BLAZE CONTEXT (AI-generated per contact)
create table if not exists blaze_context (
  id               uuid primary key default gen_random_uuid(),
  contact_id       uuid references contacts(id) on delete cascade unique,
  summary          text,
  suggested_opener text,
  key_facts        text[],
  updated_at       timestamptz not null default now()
);

-- INDEXES
create index if not exists idx_contact_messages_contact_id on contact_messages(contact_id);
create index if not exists idx_contact_messages_sent_at on contact_messages(sent_at desc);
create index if not exists idx_contact_notes_contact_id on contact_notes(contact_id);
create index if not exists idx_interaction_log_contact_id on interaction_log(contact_id);
create index if not exists idx_interaction_log_occurred_at on interaction_log(occurred_at desc);
create index if not exists idx_contacts_user_id on contacts(user_id);
create index if not exists idx_contacts_tier on contacts(tier);

-- AUTO-UPDATE updated_at triggers
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger contacts_updated_at before update on contacts
  for each row execute function update_updated_at();

create trigger contact_notes_updated_at before update on contact_notes
  for each row execute function update_updated_at();

create trigger relationship_health_updated_at before update on relationship_health
  for each row execute function update_updated_at();

-- RLS
alter table contacts enable row level security;
alter table contact_messages enable row level security;
alter table contact_notes enable row level security;
alter table relationship_health enable row level security;
alter table interaction_log enable row level security;
alter table blaze_context enable row level security;

-- Service role bypass (Edge Functions use service key)
create policy "service_role_all" on contacts for all using (true);
create policy "service_role_all" on contact_messages for all using (true);
create policy "service_role_all" on contact_notes for all using (true);
create policy "service_role_all" on relationship_health for all using (true);
create policy "service_role_all" on interaction_log for all using (true);
create policy "service_role_all" on blaze_context for all using (true);
