-- Create admins table
CREATE TABLE IF NOT EXISTS public.admins (
    admin_id UUID NOT NULL,
    name TEXT,
    email TEXT,
    phone TEXT,
    contact_name TEXT,
    address TEXT,
    language TEXT,
    logo_image TEXT,
    info JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT admins_pkey PRIMARY KEY (admin_id),
    CONSTRAINT admins_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users (id) ON DELETE CASCADE
);

-- No need for index on admin_id since it's the primary key

-- Enable Row Level Security (RLS)
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only access their own settings
CREATE POLICY "Users can view own settings" ON public.admins
    FOR SELECT USING (auth.uid() = admin_id);

CREATE POLICY "Users can insert own settings" ON public.admins
    FOR INSERT WITH CHECK (auth.uid() = admin_id);

CREATE POLICY "Users can update own settings" ON public.admins
    FOR UPDATE USING (auth.uid() = admin_id);

CREATE POLICY "Users can delete own settings" ON public.admins
    FOR DELETE USING (auth.uid() = admin_id); 