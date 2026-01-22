-- Check and fix RLS policies for enrollments table
-- This ensures users can read their own enrollments after creating them

-- Verify current policies
SELECT * FROM pg_policies WHERE tablename = 'enrollments';

-- Drop existing SELECT policy if it exists
DROP POLICY IF EXISTS "Users can view their own enrollments" ON enrollments;

-- Create policy to allow users to view their own enrollments
CREATE POLICY "Users can view their own enrollments"
ON enrollments FOR SELECT
USING (auth.uid() = user_id);

-- Verify all policies are in place
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd as operation,
    qual as using_expression,
    with_check as check_expression
FROM pg_policies 
WHERE tablename = 'enrollments'
ORDER BY policyname;
