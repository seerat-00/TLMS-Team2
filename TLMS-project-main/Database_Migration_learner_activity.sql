-- Migration: Add learner_activity table
-- Created: 2026-01-20
-- Description: Track last active time of learner for learning nudges

CREATE TABLE IF NOT EXISTS learner_activity (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE learner_activity ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own activity"
ON learner_activity
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
