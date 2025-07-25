-- Function to calculate and update credits for an admin
-- Credits = Total capsules from paid packs - Total capsules created

CREATE OR REPLACE FUNCTION public.update_admin_credits(admin_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    total_from_packs INTEGER := 0;
    total_created INTEGER := 0;
    available_credits INTEGER := 0;
BEGIN
    -- Calculate total capsules from paid packs
    SELECT COALESCE(SUM(capsules_allowed), 0)
    INTO total_from_packs
    FROM public.packs
    WHERE admin_id = admin_uuid AND payment_status = 'paid';
    
    -- Calculate total capsules created
    SELECT COALESCE(COUNT(*), 0)
    INTO total_created
    FROM public.capsules
    WHERE admin_id = admin_uuid;
    
    -- Calculate available credits
    available_credits := total_from_packs - total_created;
    
    -- Update the admins table with new credit count
    UPDATE public.admins 
    SET 
        credits = available_credits,
        updated_at = NOW()
    WHERE admin_id = admin_uuid;
    
    -- Return the calculated credits
    RETURN available_credits;
END;
$$; 