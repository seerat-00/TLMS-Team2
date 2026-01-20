-- Migration: Add course_deadlines table for deadline reminders
-- Created: 2026-01-20
-- Description: Tracks deadlines for quizzes/lessons and supports reminder scheduling

CREATE TABLE IF NOT EXISTS course_deadlines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    lesson_id UUID, -- optional (deadline can be per lesson)
    quiz_id UUID,   -- optional (deadline can be per quiz)
    
    title TEXT NOT NULL,
    deadline_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_deadlines_course ON course_deadlines(course_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_deadline ON course_deadlines(deadline_at);

-- Enable RLS
ALTER TABLE course_deadlines ENABLE ROW LEVEL SECURITY;

-- Learners can view deadlines for courses they are enrolled in
CREATE POLICY "Learners can view enrolled course deadlines"
    ON course_deadlines
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM enrollments
            WHERE enrollments.course_id = course_deadlines.course_id
              AND enrollments.user_id = auth.uid()
        )
    );

-- Educators can view deadlines for their own courses
CREATE POLICY "Educators can view deadlines for their courses"
    ON course_deadlines
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_deadlines.course_id
              AND courses.educator_id = auth.uid()
        )
    );

-- Educators can insert/update/delete deadlines for their courses
CREATE POLICY "Educators can manage deadlines for their courses"
    ON course_deadlines
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_deadlines.course_id
              AND courses.educator_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_deadlines.course_id
              AND courses.educator_id = auth.uid()
        )
    );
