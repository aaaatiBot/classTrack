-- ==============================================================================
-- ClassTrack Database Schema
-- Version: 1.2
-- ==============================================================================

-- Enable UUID extension if not already enabled
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------------------------
-- 1. Profiles Table (Stores user roles, username, class batch, and status)
-- ------------------------------------------------------------------------------
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    role text not null check (role in ('admin', 'student')),
    name text not null,
    username text not null unique,
    class_batch text,
    active boolean not null default true,
    created_at timestamptz not null default now()
);

-- Index for quick lookup by username and role
create index if not exists idx_profiles_username on public.profiles(username);
create index if not exists idx_profiles_role on public.profiles(role);

-- Helper function: Check if current user is an active admin
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and active = true
  );
$$;

-- ------------------------------------------------------------------------------
-- 2. Attendance Table
-- ------------------------------------------------------------------------------
create table if not exists public.attendance (
    id uuid primary key default gen_random_uuid(),
    student_id uuid not null references public.profiles(id) on delete cascade,
    date date not null,
    status text not null check (status in ('present', 'absent')),
    marked_by uuid references public.profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    constraint unique_student_date unique (student_id, date)
);

create index if not exists idx_attendance_student_date on public.attendance(student_id, date);

-- ------------------------------------------------------------------------------
-- 3. Subjects Table (Owned by student)
-- ------------------------------------------------------------------------------
create table if not exists public.subjects (
    id uuid primary key default gen_random_uuid(),
    student_id uuid not null references public.profiles(id) on delete cascade,
    name text not null,
    sort_order integer not null default 0,
    created_at timestamptz not null default now()
);

create index if not exists idx_subjects_student on public.subjects(student_id);

-- ------------------------------------------------------------------------------
-- 4. Chapters Table (Belongs to subject, tagged with Term 1, 2, or 3)
-- ------------------------------------------------------------------------------
create table if not exists public.chapters (
    id uuid primary key default gen_random_uuid(),
    subject_id uuid not null references public.subjects(id) on delete cascade,
    term integer not null check (term in (1, 2, 3)),
    title text not null,
    sort_order integer not null default 0,
    is_complete boolean not null default false,
    completed_on date,
    created_at timestamptz not null default now()
);

create index if not exists idx_chapters_subject on public.chapters(subject_id);
create index if not exists idx_chapters_term on public.chapters(term);

-- ------------------------------------------------------------------------------
-- 5. Daily Homework Table (Posted by admin for a class/batch)
-- ------------------------------------------------------------------------------
create table if not exists public.homework (
    id uuid primary key default gen_random_uuid(),
    date date not null,
    subject_name text not null,
    description text not null,
    class_batch text,
    created_by uuid references public.profiles(id) on delete set null,
    created_at timestamptz not null default now()
);

create index if not exists idx_homework_date on public.homework(date);
create index if not exists idx_homework_class_batch on public.homework(class_batch);

-- ------------------------------------------------------------------------------
-- 6. Notes Table (Study materials uploaded by admin)
-- ------------------------------------------------------------------------------
create table if not exists public.notes (
    id uuid primary key default gen_random_uuid(),
    class_batch text,
    subject_name text not null,
    title text not null,
    file_path text not null,
    uploaded_by uuid references public.profiles(id) on delete set null,
    uploaded_on timestamptz not null default now()
);

create index if not exists idx_notes_class_batch on public.notes(class_batch);

-- ------------------------------------------------------------------------------
-- 7. Past Results Table (Report cards scanned/entered by student)
-- ------------------------------------------------------------------------------
create table if not exists public.results (
    id uuid primary key default gen_random_uuid(),
    student_id uuid not null references public.profiles(id) on delete cascade,
    term integer not null check (term in (1, 2, 3)),
    year integer not null,
    exam_name text,
    entries jsonb not null default '[]'::jsonb,
    created_at timestamptz not null default now()
);

create index if not exists idx_results_student on public.results(student_id);

-- ------------------------------------------------------------------------------
-- 8. Test Routine Table (Student's upcoming exams)
-- ------------------------------------------------------------------------------
create table if not exists public.tests (
    id uuid primary key default gen_random_uuid(),
    student_id uuid not null references public.profiles(id) on delete cascade,
    test_date date not null,
    subject_name text not null,
    topics text,
    created_at timestamptz not null default now()
);

create index if not exists idx_tests_student_date on public.tests(student_id, test_date);

-- ------------------------------------------------------------------------------
-- 9. Class Test Scores Table (Admin enters per student)
-- ------------------------------------------------------------------------------
create table if not exists public.test_scores (
    id uuid primary key default gen_random_uuid(),
    student_id uuid not null references public.profiles(id) on delete cascade,
    subject_name text not null,
    title text not null,
    test_date date not null,
    marks numeric not null,
    max_marks numeric not null,
    entered_by uuid references public.profiles(id) on delete set null,
    created_at timestamptz not null default now()
);

create index if not exists idx_test_scores_student on public.test_scores(student_id);
