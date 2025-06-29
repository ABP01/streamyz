-- Table des utilisateurs
create table if not exists users (
  id uuid primary key default uuid_generate_v4(),
  email text unique not null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Table des channels (salons de streaming)
create table if not exists channels (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  owner_id uuid references users(id),
  created_at timestamp with time zone default timezone('utc'::text, now())
);


-- Table des lives
create table if not exists lives (
  id uuid primary key default uuid_generate_v4(),
  channel_id uuid references channels(id),
  host_id uuid references users(id),
  title text,
  started_at timestamp with time zone default timezone('utc'::text, now()),
  ended_at timestamp with time zone
);

-- Table des messages (chat)
create table if not exists messages (
  id uuid primary key default uuid_generate_v4(),
  live_id uuid references lives(id),
  sender_id uuid references users(id),
  content text,
  sent_at timestamp with time zone default timezone('utc'::text, now())
);

-- Table des réactions
create table if not exists reactions (
  id uuid primary key default uuid_generate_v4(),
  live_id uuid references lives(id),
  sender_id uuid references users(id),
  type text,
  sent_at timestamp with time zone default timezone('utc'::text, now())
);

ALTER TABLE users ADD COLUMN username text;


-- Table des abonnements (follows)
create table if not exists follows (
  id uuid primary key default uuid_generate_v4(),
  follower_id uuid references users(id) on delete cascade,
  followed_id uuid references users(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique (follower_id, followed_id)
);