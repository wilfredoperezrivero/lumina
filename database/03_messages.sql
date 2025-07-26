-- Create messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    capsule_id UUID NOT NULL,
    content_text TEXT NULL,
    content_audio_url TEXT NULL,
    content_video_url TEXT NULL,
    content_image_url TEXT NULL,
    submitted_at TIMESTAMP WITHOUT TIME ZONE NULL DEFAULT NOW(),
    hidden BOOLEAN NULL DEFAULT false,
    contributor_name TEXT NULL,
    contributor_email TEXT NULL,
    created_at TIMESTAMP WITH TIME ZONE NULL DEFAULT NOW(),
    CONSTRAINT messages_pkey PRIMARY KEY (id),
    CONSTRAINT messages_capsule_id_fkey FOREIGN KEY (capsule_id) REFERENCES capsules (id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_capsule_id ON public.messages(capsule_id);
CREATE INDEX IF NOT EXISTS idx_messages_submitted_at ON public.messages(submitted_at);
CREATE INDEX IF NOT EXISTS idx_messages_hidden ON public.messages(hidden);

-- Enable Row Level Security (RLS)
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for messages
-- Users can view messages for capsules they have access to
CREATE POLICY "Users can view messages for accessible capsules" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.capsules 
            WHERE capsules.id = messages.capsule_id 
            AND (capsules.admin_id = auth.uid() OR capsules.family_id = auth.uid())
        )
    );

-- Users can insert messages for capsules they have access to
CREATE POLICY "Users can insert messages for accessible capsules" ON public.messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.capsules 
            WHERE capsules.id = messages.capsule_id 
            AND (capsules.admin_id = auth.uid() OR capsules.family_id = auth.uid())
        )
    );

-- Only admins can update messages (for moderation purposes)
CREATE POLICY "Admins can update messages" ON public.messages
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.capsules 
            WHERE capsules.id = messages.capsule_id 
            AND capsules.admin_id = auth.uid()
        )
    );

-- Only admins can delete messages
CREATE POLICY "Admins can delete messages" ON public.messages
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.capsules 
            WHERE capsules.id = messages.capsule_id 
            AND capsules.admin_id = auth.uid()
        )
    ); 