-- Create payments_logs table
CREATE TABLE IF NOT EXISTS public.payments_logs (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    webhook_payload JSONB NOT NULL,
    admin_id UUID NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT payments_logs_pkey PRIMARY KEY (id)
);

-- Create index for admin_id
CREATE INDEX IF NOT EXISTS idx_payments_logs_admin_id ON public.payments_logs(admin_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.payments_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for payments_logs
-- Only admins can view their own payment logs
CREATE POLICY "Admins can view own payment logs" ON public.payments_logs
    FOR SELECT USING (auth.uid() = admin_id);

-- Service role can insert payment logs (for webhook)
CREATE POLICY "Service can insert payment logs" ON public.payments_logs
    FOR INSERT WITH CHECK (true);

-- Service role can update payment logs
CREATE POLICY "Service can update payment logs" ON public.payments_logs
    FOR UPDATE USING (true); 