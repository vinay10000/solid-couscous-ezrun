-- EZRUN: Follow requests + user privacy flag
-- This migration adds:
-- 1) users.is_private (default false)
-- 2) ezrun_follow_requests table for Instagram-like follow requests
--
-- NOTE:
-- - Assumes `users` table exists with `id` matching `auth.uid()`.
-- - Uses gen_random_uuid() (pgcrypto). If your project uses uuid_generate_v4(),
--   replace accordingly.

-- Ensure pgcrypto for gen_random_uuid()
create extension if not exists "pgcrypto";

-- Add privacy flag to users (optional, but enables public vs private logic)
alter table public.users
add column if not exists is_private boolean not null default false;

-- Follow requests table
create table if not exists public.ezrun_follow_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.users(id) on delete cascade,
  requested_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'denied')),
  created_at timestamptz not null default now(),
  acted_at timestamptz null
);

-- Prevent duplicate pending requests for the same pair
create unique index if not exists ezrun_follow_requests_unique_pending
on public.ezrun_follow_requests (requester_id, requested_id)
where status = 'pending';

-- Helpful index for "my incoming requests"
create index if not exists ezrun_follow_requests_requested_id_created_at
on public.ezrun_follow_requests (requested_id, created_at desc);

-- RLS
alter table public.ezrun_follow_requests enable row level security;

-- Requester can create a request for themselves
drop policy if exists "follow_requests_insert_requester" on public.ezrun_follow_requests;
create policy "follow_requests_insert_requester"
on public.ezrun_follow_requests
for insert
to authenticated
with check (requester_id = auth.uid());

-- Requester and requested can view requests involving them
drop policy if exists "follow_requests_select_involved" on public.ezrun_follow_requests;
create policy "follow_requests_select_involved"
on public.ezrun_follow_requests
for select
to authenticated
using (requester_id = auth.uid() or requested_id = auth.uid());

-- Requested user can accept/deny (update) pending requests directed to them
drop policy if exists "follow_requests_update_requested" on public.ezrun_follow_requests;
create policy "follow_requests_update_requested"
on public.ezrun_follow_requests
for update
to authenticated
using (requested_id = auth.uid())
with check (requested_id = auth.uid());

-- Either party can delete (optional; allows requester to cancel, requested to clear)
drop policy if exists "follow_requests_delete_involved" on public.ezrun_follow_requests;
create policy "follow_requests_delete_involved"
on public.ezrun_follow_requests
for delete
to authenticated
using (requester_id = auth.uid() or requested_id = auth.uid());


