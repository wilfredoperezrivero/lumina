# Database Schema

This directory contains the database schema files for the Lumina Admin application.

## Schema Files

### Table Definitions

1. **`01_admins.sql`** - Admin user settings and profile information
   - 1-1 relationship with users (admin_id as primary key)
   - Stores business name, email, phone, logo, and flexible JSONB info

2. **`02_capsules.sql`** - Digital time capsules
   - Links admin users to family users
   - Contains capsule metadata, status, and scheduling information

3. **`03_messages.sql`** - User contributions to capsules
   - Supports text, audio, and video content
   - Includes moderation features (hidden flag)
   - Links to capsules with cascade delete

4. **`04_packs.sql`** - Credit/pack management system
   - Tracks pack purchases and usage
   - Manages capsule credits for admins
   - Payment status tracking

5. **`05_storage.sql`** - Storage bucket configuration
   - Admin asset storage (logos)
   - User-specific folder structure
   - Security policies for file access

### Master Files

- **`00_init.sql`** - Master initialization script
  - Runs all schema files in the correct order
  - Handles dependencies between tables

## Installation

### Option 1: Run Master Script
```sql
-- In Supabase SQL Editor
\i 'database/schema/00_init.sql'
```

### Option 2: Run Individual Files
```sql
-- Run files in order:
\i 'database/01_admins.sql'
\i 'database/02_capsules.sql'
\i 'database/03_messages.sql'
\i 'database/04_packs.sql'
```

### Storage Setup
The storage configuration in `05_storage.sql` needs to be run manually in the Supabase dashboard:
1. Create storage bucket named `admin-assets`
2. Set bucket to public
3. Apply the storage policies

## Schema Overview

### Relationships
```
users (auth.users)
├── admins (1:1)
├── capsules (1:many)
│   └── messages (1:many)
└── packs (1:many)
```

### Key Features
- **Row Level Security (RLS)** - All tables have proper access controls
- **Foreign Key Constraints** - Maintains data integrity
- **Performance Indexes** - Optimized for common queries
- **Cascade Deletes** - Automatic cleanup of related data
- **Flexible JSONB** - Extensible data storage

## Security

All tables implement Row Level Security with policies that ensure:
- Users can only access their own data
- Admins have full control over their capsules and settings
- Family users have limited access to assigned capsules
- Message moderation is restricted to admins

## Maintenance

### Adding New Tables
1. Create new SQL file with numbered prefix
2. Update `00_init.sql` to include the new file
3. Update this README with table description

### Modifying Existing Tables
1. Create migration files in `database/migrations/`
2. Test changes in development environment
3. Apply to production with proper backup 