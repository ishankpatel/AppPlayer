-- ============================================================
-- StreamVault - Supabase Schema
-- Run this in the Supabase SQL Editor.
-- ============================================================

create extension if not exists pgcrypto;

-- One household can share a simple Supabase auth account, while profiles
-- represent family members and store synced playback preferences.
-- Real-Debrid API tokens are intentionally not stored in Supabase; the app
-- keeps that credential per-device only.
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  avatar_color text default '#FF4F2E',
  preferred_subtitle_lang text default 'en',
  preferred_audio_lang text default 'en',
  autoplay_next_episode boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists watchlist (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  tmdb_id integer not null,
  media_type text not null check (media_type in ('movie', 'tv')),
  title text not null,
  poster_path text,
  backdrop_path text,
  added_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, tmdb_id, media_type)
);

create table if not exists continue_watching (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  tmdb_id integer not null,
  media_type text not null check (media_type in ('movie', 'tv')),
  title text not null,
  poster_path text,
  backdrop_path text,
  season_number integer,
  episode_number integer,
  episode_title text,
  position_seconds integer not null default 0,
  duration_seconds integer,
  preferred_subtitle_lang text,
  preferred_audio_lang text,
  last_watched_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, tmdb_id, media_type, season_number, episode_number)
);

create table if not exists favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  tmdb_id integer not null,
  media_type text not null check (media_type in ('movie', 'tv')),
  title text not null,
  poster_path text,
  backdrop_path text,
  added_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, tmdb_id, media_type)
);

create index if not exists watchlist_user_added_idx on watchlist(user_id, added_at desc);
create index if not exists continue_user_recent_idx on continue_watching(user_id, last_watched_at desc);
create index if not exists favorites_user_added_idx on favorites(user_id, added_at desc);

alter table profiles enable row level security;
alter table watchlist enable row level security;
alter table continue_watching enable row level security;
alter table favorites enable row level security;

create policy "Users can view own profile" on profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy "Users can insert own profile" on profiles
  for insert to authenticated with check ((select auth.uid()) = id);
create policy "Users can update own profile" on profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Users manage own watchlist" on watchlist
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users manage own continue watching" on continue_watching
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users manage own favorites" on favorites
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace function touch_updated_at()
returns trigger language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on profiles;
create trigger profiles_touch_updated_at
  before update on profiles
  for each row execute procedure touch_updated_at();

drop trigger if exists watchlist_touch_updated_at on watchlist;
create trigger watchlist_touch_updated_at
  before update on watchlist
  for each row execute procedure touch_updated_at();

drop trigger if exists continue_touch_updated_at on continue_watching;
create trigger continue_touch_updated_at
  before update on continue_watching
  for each row execute procedure touch_updated_at();

drop trigger if exists favorites_touch_updated_at on favorites;
create trigger favorites_touch_updated_at
  before update on favorites
  for each row execute procedure touch_updated_at();

create or replace function handle_new_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', 'Family Member'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

revoke execute on function public.handle_new_user() from public;
revoke execute on function public.touch_updated_at() from public;
