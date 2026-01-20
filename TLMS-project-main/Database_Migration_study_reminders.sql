-- Migration: Add learner_reminder_settings table for study reminders
-- Created: 2026-01-20
-- Description: Stores user reminder preferences (enabled + time)

CREATE TABLE IF NOT EXISTS learner_reminder_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    reminder_time TIME NOT NULL DEFAULT '20:00:00',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE learner_reminder_settings ENABLE ROW LEVEL SECURITY;

-- Policy: user can view own reminder settings
CREATE POLICY "Users can view own reminder settings"
    ON learner_reminder_settings
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: user can insert own reminder settings
CREATE POLICY "Users can insert own reminder settings"
    ON learner_reminder_settings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: user can update own reminder settings
CREATE POLICY "Users can update own reminder settings"
    ON learner_reminder_settings
    FOR UPDATE
    USING (auth.uid() = user_id);
