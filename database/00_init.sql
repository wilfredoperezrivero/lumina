-- Lumina Admin Database Schema
-- Master initialization file
-- Run this file to set up the complete database schema

-- Execute schema files in order:
-- 1. Admins
\i '01_admins.sql'

-- 2. Capsules
\i '02_capsules.sql'

-- 3. Messages
\i '03_messages.sql'

-- 4. Packs
\i '04_packs.sql'

-- 5. Storage Configuration (commented out - run manually in Supabase dashboard)
-- \i '05_storage.sql'

-- Schema initialization complete
SELECT 'Lumina Admin database schema initialized successfully!' as status; 