-- Create capsules table
CREATE TABLE IF NOT EXISTS public.capsules (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    admin_id UUID NULL,
    family_id UUID NULL,
    title TEXT NULL,
    description TEXT NULL,
    expires_at TIMESTAMP WITHOUT TIME ZONE NULL,
    final_video_url TEXT NULL,
    status TEXT NULL DEFAULT 'active'::text,
    family_email TEXT NULL,
    created_at TIMESTAMP WITH TIME ZONE NULL DEFAULT NOW(),
    scheduled_date TIMESTAMP WITH TIME ZONE NULL,
    CONSTRAINT capsules_pkey PRIMARY KEY (id),
    CONSTRAINT capsules_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users (id),
    CONSTRAINT capsules_family_id_fkey FOREIGN KEY (family_id) REFERENCES auth.users (id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_capsules_admin_id ON public.capsules(admin_id);
CREATE INDEX IF NOT EXISTS idx_capsules_family_id ON public.capsules(family_id);
CREATE INDEX IF NOT EXISTS idx_capsules_status ON public.capsules(status);

-- Enable Row Level Security (RLS)
ALTER TABLE public.capsules ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for capsules
-- Admins can view their own capsules
CREATE POLICY "Admins can view own capsules" ON public.capsules
    FOR SELECT USING (auth.uid() = admin_id);

-- Admins can insert their own capsules
CREATE POLICY "Admins can insert own capsules" ON public.capsules
    FOR INSERT WITH CHECK (auth.uid() = admin_id);

-- Admins can update their own capsules
CREATE POLICY "Admins can update own capsules" ON public.capsules
    FOR UPDATE USING (auth.uid() = admin_id);

-- Admins can delete their own capsules
CREATE POLICY "Admins can delete own capsules" ON public.capsules
    FOR DELETE USING (auth.uid() = admin_id);

-- Family users can view capsules assigned to them
CREATE POLICY "Family can view assigned capsules" ON public.capsules
    FOR SELECT USING (auth.uid() = family_id); 