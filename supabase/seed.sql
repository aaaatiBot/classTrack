-- ==============================================================================
-- ClassTrack Initial Admin Setup (Seed)
-- Version: 1.2
-- ==============================================================================
-- Admin User UID provided: a48aa0e1-2bc4-4241-853d-4387c116f2d4

insert into public.profiles (id, role, name, username, active)
values (
    'a48aa0e1-2bc4-4241-853d-4387c116f2d4',
    'admin',
    'Administrator',
    'admin',
    true
)
on conflict (id) do update set
    role = 'admin',
    name = excluded.name,
    username = excluded.username,
    active = true;
