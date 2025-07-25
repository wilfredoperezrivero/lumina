-- Triggers to automatically update admin credits when packs or capsules change

-- Function to handle trigger events
CREATE OR REPLACE FUNCTION public.trigger_update_admin_credits()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update credits for the affected admin
    IF TG_OP = 'INSERT' THEN
        -- New pack or capsule added
        PERFORM public.update_admin_credits(NEW.admin_id);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Pack or capsule updated
        PERFORM public.update_admin_credits(NEW.admin_id);
        -- If admin_id changed, also update the old admin
        IF OLD.admin_id IS DISTINCT FROM NEW.admin_id THEN
            PERFORM public.update_admin_credits(OLD.admin_id);
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Pack or capsule deleted
        PERFORM public.update_admin_credits(OLD.admin_id);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Trigger for packs table
DROP TRIGGER IF EXISTS trigger_packs_update_credits ON public.packs;
CREATE TRIGGER trigger_packs_update_credits
    AFTER INSERT OR UPDATE OR DELETE ON public.packs
    FOR EACH ROW
    EXECUTE FUNCTION public.trigger_update_admin_credits();

-- Trigger for capsules table
DROP TRIGGER IF EXISTS trigger_capsules_update_credits ON public.capsules;
CREATE TRIGGER trigger_capsules_update_credits
    AFTER INSERT OR UPDATE OR DELETE ON public.capsules
    FOR EACH ROW
    EXECUTE FUNCTION public.trigger_update_admin_credits(); 