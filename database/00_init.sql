-- Master script to initialize the entire database schema
-- Run this script to set up all tables, views, and policies

-- Create tables
\i 01_admins.sql
\i 02_capsules.sql
\i 03_messages.sql
\i 04_packs.sql
\i 05_payments_logs.sql

-- Create credits system
\i 06_credits_function.sql
\i 07_credits_triggers.sql
\i 08_credits_initialization.sql

-- Initialize credits for existing admins (if any)
SELECT public.initialize_all_admin_credits();

-- Schema initialization complete
SELECT 'Lumina Admin database schema initialized successfully!' as status; 