-- Migration: Add learner_reminder_settings table
-- Created: 2026-01-20
-- Description: Stores learner study reminder preferences

CREATE TABLE IF NOT EXISTS learner_reminder_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    study_reminder_enabled BOOLEAN DEFAULT false,
    study_reminder_time TEXT DEFAULT '20:00'
);

ALTER TABLE learner_reminder_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own reminder settings"
ON learner_reminder_settings
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

