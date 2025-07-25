-- ALTER TABLE statements to add new fields to existing admins table
-- Run these statements if you have an existing admins table

-- Add contact_name field
ALTER TABLE public.admins ADD COLUMN IF NOT EXISTS contact_name TEXT;

-- Add address field
ALTER TABLE public.admins ADD COLUMN IF NOT EXISTS address TEXT;

-- Add language field
ALTER TABLE public.admins ADD COLUMN IF NOT EXISTS language TEXT;

-- Update the updated_at timestamp for existing records
UPDATE public.admins SET updated_at = NOW() WHERE updated_at IS NULL; 