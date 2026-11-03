-- ==============================================================================
-- ClassTrack Storage Setup
-- Version: 1.2
-- ==============================================================================

-- Create private bucket 'notes' if it does not already exist
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'notes',
    'notes',
    false, -- Private bucket: access through signed URLs only
    10485760, -- 10MB file limit per note (keeps within free plan limits)
    array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = array['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];

-- Storage Policies for 'notes' bucket
-- Authenticated users (students & admin) can download / read objects via signed URLs
create policy "Authenticated users can read note files"
    on storage.objects
    for select
    using (
        bucket_id = 'notes'
        and auth.role() = 'authenticated'
    );

-- Only admin can upload note files
create policy "Admins can upload note files"
    on storage.objects
    for insert
    with check (
        bucket_id = 'notes'
        and public.is_admin()
    );

-- Only admin can update note files
create policy "Admins can update note files"
    on storage.objects
    for update
    using (
        bucket_id = 'notes'
        and public.is_admin()
    );

-- Only admin can delete note files
create policy "Admins can delete note files"
    on storage.objects
    for delete
    using (
        bucket_id = 'notes'
        and public.is_admin()
    );
