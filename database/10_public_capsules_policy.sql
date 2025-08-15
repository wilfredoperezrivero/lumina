-- Allow unauthenticated (anonymous) users to view capsules with status 'active'
-- This is required so public capsule pages can be displayed without login
CREATE POLICY "Public can view active capsules" ON public.capsules
    FOR SELECT
    USING (status = 'active');
