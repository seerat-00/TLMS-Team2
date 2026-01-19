-- Migration: Create Supabase Storage Buckets for Course Content
-- Created: 2026-01-19
-- Description: Sets up storage buckets for videos, PDFs, and presentations

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) 
VALUES 
    ('course-videos', 'course-videos', true),
    ('course-pdfs', 'course-pdfs', true),
    ('course-presentations', 'course-presentations', true)
ON CONFLICT (id) DO NOTHING;

-- Set up policies for course-videos bucket
CREATE POLICY "Anyone can view course videos"
ON storage.objects FOR SELECT
USING (bucket_id = 'course-videos');

CREATE POLICY "Educators can upload course videos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'course-videos' AND
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'educator'
    )
);

CREATE POLICY "Educators can update their course videos"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'course-videos' AND
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'educator'
    )
);

CREATE POLICY "Educators can delete their course videos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'course-videos' AND
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'educator'
    )
);

-- Set up policies for course-pdfs bucket
CREATE POLICY "Anyone can view course PDFs"
ON storage.objects FOR SELECT
USING (bucket_id = 'course-pdfs');

CREATE POLICY "Educators can upload course PDFs"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'course-pdfs' AND
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'educator'
    )
);

CREATE POLICY "Educators can update their course PDFs"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'course-pdfs' AND
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'educator'
    )
);

CREATE POLICY "Educators can delete their course PDFs"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'course-pdfs' AND
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'educator'
    )
);

-- Set up policies for course-presentations bucket
CREATE POLICY "Anyone can view course presentations"
ON storage.objects FOR SELECT
USING (bucket_id = 'course-presentations');

CREATE POLICY "Educators can upload course presentations"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'course-presentations' AND
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'educator'
    )
);

CREATE POLICY "Educators can update their course presentations"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'course-presentations' AND
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'educator'
    )
);

CREATE POLICY "Educators can delete their course presentations"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'course-presentations' AND
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.raw_user_meta_data->>'role' = 'educator'
    )
);

-- Add comments
COMMENT ON POLICY "Anyone can view course videos" ON storage.objects IS 'Public read access to course video files';
COMMENT ON POLICY "Anyone can view course PDFs" ON storage.objects IS 'Public read access to course PDF files';
COMMENT ON POLICY "Anyone can view course presentations" ON storage.objects IS 'Public read access to course presentation files';
