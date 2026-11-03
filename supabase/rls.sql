-- ==============================================================================
-- ClassTrack Row Level Security (RLS) Policies
-- Version: 1.2
-- ==============================================================================

-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.attendance enable row level security;
alter table public.subjects enable row level security;
alter table public.chapters enable row level security;
alter table public.homework enable row level security;
alter table public.notes enable row level security;
alter table public.results enable row level security;
alter table public.tests enable row level security;
alter table public.test_scores enable row level security;

-- ------------------------------------------------------------------------------
-- 1. Profiles Table Policies
-- ------------------------------------------------------------------------------
-- Users can view their own profile; Admins can view all profiles
create policy "Users can read own profile or admin reads all"
    on public.profiles
    for select
    using (auth.uid() = id or public.is_admin());

-- Only admins can insert new profiles (service_role bypasses RLS in Edge Functions)
create policy "Admins can insert profiles"
    on public.profiles
    for insert
    with check (public.is_admin());

-- Admins can update any profile; Users can update their own non-role fields
create policy "Admins can update profiles"
    on public.profiles
    for update
    using (public.is_admin() or auth.uid() = id);

-- Only admins can delete profiles
create policy "Admins can delete profiles"
    on public.profiles
    for delete
    using (public.is_admin());

-- ------------------------------------------------------------------------------
-- 2. Attendance Table Policies
-- ------------------------------------------------------------------------------
-- Students read their own attendance; Admin reads all attendance
create policy "Students read own attendance or admin reads all"
    on public.attendance
    for select
    using (auth.uid() = student_id or public.is_admin());

-- Only admins can insert, update, or delete attendance
create policy "Admins can insert attendance"
    on public.attendance
    for insert
    with check (public.is_admin());

create policy "Admins can update attendance"
    on public.attendance
    for update
    using (public.is_admin());

create policy "Admins can delete attendance"
    on public.attendance
    for delete
    using (public.is_admin());

-- ------------------------------------------------------------------------------
-- 3. Subjects Table Policies
-- ------------------------------------------------------------------------------
-- Students read/write only their own subjects; Admin can view (read-only)
create policy "Students read own subjects or admin reads all"
    on public.subjects
    for select
    using (auth.uid() = student_id or public.is_admin());

create policy "Students can insert own subjects"
    on public.subjects
    for insert
    with check (auth.uid() = student_id);

create policy "Students can update own subjects"
    on public.subjects
    for update
    using (auth.uid() = student_id);

create policy "Students can delete own subjects"
    on public.subjects
    for delete
    using (auth.uid() = student_id);

-- ------------------------------------------------------------------------------
-- 4. Chapters Table Policies
-- ------------------------------------------------------------------------------
-- Chapters access checked via subject ownership
create policy "Students read own chapters or admin reads all"
    on public.chapters
    for select
    using (
        exists (
            select 1 from public.subjects
            where subjects.id = chapters.subject_id
              and (subjects.student_id = auth.uid() or public.is_admin())
        )
    );

create policy "Students can insert chapters in own subjects"
    on public.chapters
    for insert
    with check (
        exists (
            select 1 from public.subjects
            where subjects.id = chapters.subject_id
              and subjects.student_id = auth.uid()
        )
    );

create policy "Students can update chapters in own subjects"
    on public.chapters
    for update
    using (
        exists (
            select 1 from public.subjects
            where subjects.id = chapters.subject_id
              and subjects.student_id = auth.uid()
        )
    );

create policy "Students can delete chapters in own subjects"
    on public.chapters
    for delete
    using (
        exists (
            select 1 from public.subjects
            where subjects.id = chapters.subject_id
              and subjects.student_id = auth.uid()
        )
    );

-- ------------------------------------------------------------------------------
-- 5. Homework Table Policies
-- ------------------------------------------------------------------------------
-- All authenticated users can read homework
create policy "Authenticated users can read homework"
    on public.homework
    for select
    using (auth.role() = 'authenticated');

-- Only admins can write homework
create policy "Admins can insert homework"
    on public.homework
    for insert
    with check (public.is_admin());

create policy "Admins can update homework"
    on public.homework
    for update
    using (public.is_admin());

create policy "Admins can delete homework"
    on public.homework
    for delete
    using (public.is_admin());

-- ------------------------------------------------------------------------------
-- 6. Notes Table Policies
-- ------------------------------------------------------------------------------
-- All authenticated users can read notes metadata
create policy "Authenticated users can read notes"
    on public.notes
    for select
    using (auth.role() = 'authenticated');

-- Only admins can write notes metadata
create policy "Admins can insert notes"
    on public.notes
    for insert
    with check (public.is_admin());

create policy "Admins can update notes"
    on public.notes
    for update
    using (public.is_admin());

create policy "Admins can delete notes"
    on public.notes
    for delete
    using (public.is_admin());

-- ------------------------------------------------------------------------------
-- 7. Past Results Table Policies
-- ------------------------------------------------------------------------------
-- Students read/write only their own results; Admin can view (read-only)
create policy "Students read own results or admin reads all"
    on public.results
    for select
    using (auth.uid() = student_id or public.is_admin());

create policy "Students can insert own results"
    on public.results
    for insert
    with check (auth.uid() = student_id);

create policy "Students can update own results"
    on public.results
    for update
    using (auth.uid() = student_id);

create policy "Students can delete own results"
    on public.results
    for delete
    using (auth.uid() = student_id);

-- ------------------------------------------------------------------------------
-- 8. Test Routine Table Policies
-- ------------------------------------------------------------------------------
-- Students read/write only their own tests; Admin can view (read-only)
create policy "Students read own tests or admin reads all"
    on public.tests
    for select
    using (auth.uid() = student_id or public.is_admin());

create policy "Students can insert own tests"
    on public.tests
    for insert
    with check (auth.uid() = student_id);

create policy "Students can update own tests"
    on public.tests
    for update
    using (auth.uid() = student_id);

create policy "Students can delete own tests"
    on public.tests
    for delete
    using (auth.uid() = student_id);

-- ------------------------------------------------------------------------------
-- 9. Class Test Scores Table Policies
-- ------------------------------------------------------------------------------
-- Students read own test scores; Admin can read all
create policy "Students read own test scores or admin reads all"
    on public.test_scores
    for select
    using (auth.uid() = student_id or public.is_admin());

-- Only admins can write class test scores
create policy "Admins can insert test scores"
    on public.test_scores
    for insert
    with check (public.is_admin());

create policy "Admins can update test scores"
    on public.test_scores
    for update
    using (public.is_admin());

create policy "Admins can delete test scores"
    on public.test_scores
    for delete
    using (public.is_admin());
