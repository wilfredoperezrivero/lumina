-- Function to create admin record and welcome pack during registration
CREATE OR REPLACE FUNCTION create_admin_with_welcome_pack(
  admin_id UUID,
  admin_name TEXT,
  admin_email TEXT,
  admin_logo_image TEXT DEFAULT NULL,
  admin_country TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  -- Insert admin record with SECURITY DEFINER to bypass RLS
  INSERT INTO public.admins (
    admin_id,
    name,
    email,
    logo_image,
    info,
    language,
    credits,
    created_at,
    updated_at
  ) VALUES (
    admin_id,
    admin_name,
    admin_email,
    admin_logo_image,
    jsonb_build_object(
      'country', admin_country,
      'registration_date', NOW()::text
    ),
    'English',
    0,
    NOW(),
    NOW()
  );
  
  -- Insert welcome pack with SECURITY DEFINER to bypass RLS
  INSERT INTO public.packs (
    admin_id,
    pack_type,
    capsules_allowed,
    capsules_used,
    payment_status,
    purchased_at
  ) VALUES (
    admin_id,
    'welcome pack',
    3,
    0,
    'paid',
    NOW()
  );
  
  -- Log the creation for debugging
  RAISE NOTICE 'Created admin record and welcome pack for user %', admin_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_admin_with_welcome_pack(UUID, TEXT, TEXT, TEXT, TEXT) TO authenticated; 