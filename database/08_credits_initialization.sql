-- Function to initialize credits for all existing admins
-- Run this after setting up the credits system

CREATE OR REPLACE FUNCTION public.initialize_all_admin_credits()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    admin_record RECORD;
    updated_count INTEGER := 0;
BEGIN
    -- Loop through all admins and update their credits
    FOR admin_record IN 
        SELECT admin_id FROM public.admins
    LOOP
        PERFORM public.update_admin_credits(admin_record.admin_id);
        updated_count := updated_count + 1;
    END LOOP;
    
    RETURN updated_count;
END;
$$;

-- Function to get credits for current user (for RLS)
CREATE OR REPLACE FUNCTION public.get_current_user_credits()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_credits INTEGER := 0;
BEGIN
    SELECT credits INTO user_credits
    FROM public.admins
    WHERE admin_id = auth.uid();
    
    RETURN COALESCE(user_credits, 0);
END;
$$; 