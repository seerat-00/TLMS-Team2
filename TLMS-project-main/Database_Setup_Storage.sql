-- Setup Supabase Storage for Lesson Content
-- Run this in Supabase SQL Editor

-- 1. Create storage bucket for lesson content
INSERT INTO storage.buckets (id, name, public)
VALUES ('lesson-content', 'lesson-content', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Drop existing policies if they exist (to allow re-running this script)
DROP POLICY IF EXISTS "Educators can upload lesson content" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view lesson content" ON storage.objects;
DROP POLICY IF EXISTS "Educators can update lesson content" ON storage.objects;
DROP POLICY IF EXISTS "Educators can delete lesson content" ON storage.objects;

-- 3. Allow authenticated users (educators) to upload files
CREATE POLICY "Educators can upload lesson content"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'lesson-content'
);

-- 4. Allow everyone to view files (public bucket)
CREATE POLICY "Anyone can view lesson content"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'lesson-content');

-- 5. Allow authenticated users to update their files
CREATE POLICY "Educators can update lesson content"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'lesson-content')
WITH CHECK (bucket_id = 'lesson-content');

-- 6. Allow authenticated users to delete their files
CREATE POLICY "Educators can delete lesson content"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'lesson-content');

-- Verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd as operation
FROM pg_policies 
WHERE tablename = 'objects'
AND policyname LIKE '%lesson%'
ORDER BY policyname;
