-- Migration: Add lesson_completions table for progress tracking
-- Created: 2026-01-19
-- Description: This table tracks individual lesson completions for learners

-- Create lesson_completions table
CREATE TABLE IF NOT EXISTS lesson_completions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure a user can only complete a lesson once per course
    UNIQUE(user_id, course_id, lesson_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_lesson_completions_user_id ON lesson_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_lesson_completions_course_id ON lesson_completions(course_id);
CREATE INDEX IF NOT EXISTS idx_lesson_completions_user_course ON lesson_completions(user_id, course_id);

-- Enable Row Level Security
ALTER TABLE lesson_completions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own lesson completions
CREATE POLICY "Users can view own lesson completions"
    ON lesson_completions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own lesson completions
CREATE POLICY "Users can insert own lesson completions"
    ON lesson_completions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own lesson completions
CREATE POLICY "Users can update own lesson completions"
    ON lesson_completions
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy: Educators can view lesson completions for their courses
CREATE POLICY "Educators can view completions for their courses"
    ON lesson_completions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = lesson_completions.course_id
            AND courses.educator_id = auth.uid()
        )
    );

-- Policy: Admins can view all lesson completions
CREATE POLICY "Admins can view all lesson completions"
    ON lesson_completions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Add comment to table
COMMENT ON TABLE lesson_completions IS 'Tracks individual lesson completion status for learners to calculate course progress';
