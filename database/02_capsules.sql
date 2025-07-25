-- Create capsules table
CREATE TABLE IF NOT EXISTS public.capsules (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    admin_id UUID,
    family_id UUID,
    name TEXT,
    date_of_birth TEXT,
    date_of_death TEXT,
    language TEXT,
    image TEXT,
    expires_at TIMESTAMP WITHOUT TIME ZONE,
    final_video_url TEXT,
    status TEXT DEFAULT 'active',
    family_email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    scheduled_date TIMESTAMP WITH TIME ZONE,
    CONSTRAINT capsules_pkey PRIMARY KEY (id),
    CONSTRAINT capsules_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users (id),
    CONSTRAINT capsules_family_id_fkey FOREIGN KEY (family_id) REFERENCES auth.users (id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_capsules_admin_id ON public.capsules (admin_id);
CREATE INDEX IF NOT EXISTS idx_capsules_family_id ON public.capsules (family_id);
CREATE INDEX IF NOT EXISTS idx_capsules_status ON public.capsules (status);

-- Enable Row Level Security (RLS)
ALTER TABLE public.capsules ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Admins can view, create, update, and delete their own capsules
CREATE POLICY "Admins can manage own capsules" ON public.capsules
    FOR ALL USING (auth.uid() = admin_id);

-- Families can view capsules assigned to them
CREATE POLICY "Families can view assigned capsules" ON public.capsules
    FOR SELECT USING (auth.uid() = family_id); 