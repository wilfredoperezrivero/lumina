-- Create packs table
CREATE TABLE IF NOT EXISTS public.packs (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    admin_id UUID NULL,
    pack_type TEXT NULL,
    purchased_at TIMESTAMP WITH TIME ZONE NULL,
    capsules_allowed INTEGER NULL,
    capsules_used INTEGER NULL DEFAULT 0,
    payment_status TEXT NULL,
    CONSTRAINT packs_pkey PRIMARY KEY (id),
    CONSTRAINT packs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users (id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_packs_admin_id ON public.packs(admin_id);
CREATE INDEX IF NOT EXISTS idx_packs_pack_type ON public.packs(pack_type);
CREATE INDEX IF NOT EXISTS idx_packs_payment_status ON public.packs(payment_status);
CREATE INDEX IF NOT EXISTS idx_packs_purchased_at ON public.packs(purchased_at);

-- Enable Row Level Security (RLS)
ALTER TABLE public.packs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for packs
-- Admins can view their own packs
CREATE POLICY "Admins can view own packs" ON public.packs
    FOR SELECT USING (auth.uid() = admin_id);

-- Admins can insert their own packs
CREATE POLICY "Admins can insert own packs" ON public.packs
    FOR INSERT WITH CHECK (auth.uid() = admin_id);

-- Admins can update their own packs
CREATE POLICY "Admins can update own packs" ON public.packs
    FOR UPDATE USING (auth.uid() = admin_id);

-- Admins can delete their own packs
CREATE POLICY "Admins can delete own packs" ON public.packs
    FOR DELETE USING (auth.uid() = admin_id); 