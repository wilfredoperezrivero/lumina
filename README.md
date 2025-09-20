# Lumina Admin

A Flutter web application for managing Lumina Memorial capsules - digital time capsules for preserving memories and messages for loved ones.

## Repository overview for new contributors

### High-level purpose
- Lumina Admin is a Flutter web application that lets memorial administrators create and manage digital “capsules”, invite family members, purchase credit packs, and oversee branding/assets on top of a Supabase backend and Lemonsqueezy e-commerce integration.
- The wider Lumina platform also includes family- and invitee-facing experiences plus an external video generation service, all coordinated through the same Supabase project.

### Repository structure at a glance
- `lib/` contains the Flutter application split into the entrypoint (`main.dart`), feature pages (`pages/`), data models (`models/`), and service classes for Supabase and storage interactions (`services/`).
- `database/` holds SQL definitions for core tables (admins, capsules, messages, packs), helper functions, triggers, and queue integrations that enforce credits, welcome packs, and video processing workflows.
- `functions/` includes Supabase Edge Functions for automating family account creation and processing Lemonsqueezy purchase webhooks.
- Supporting assets (brand imagery and PDF backgrounds), deployment/build scripts, and Supabase CLI configuration live in the project root (`assets/`, `dev.sh`, `build.sh`, `deploy.sh`, `supabase/config.toml`, etc.).

### Flutter web app flow
- `main.dart` bootstraps Flutter, loads environment variables, initializes Supabase, and wires up a `GoRouter` configuration to handle admin, family, and public routes while enforcing auth- and role-based redirects. It also listens for recovery links via `uni_links` to support password resets.
- Riverpod’s `ProviderScope` wraps the app for state management, though most services are used via static helpers; `AuthService.authStateChanges()` feeds GoRouter’s `refreshListenable` so navigation reacts to Supabase auth events.

### Feature highlights by audience
#### Admin experience
- The dashboard offers quick navigation cards into capsule creation, listings, pack purchases, settings, and marketing tools, and includes logout controls tied to Supabase auth.
- Capsule creation validates available credits, captures memorial metadata, provisions a family account through an edge function, and then inserts the capsule record via `CapsuleService`. Clear error handling guides admins when API keys or responses are missing.
- Capsule lists support filtering, infinite scroll, quick access to capsule detail screens, and display status/family context for each record.
- Capsule detail pages collate metadata, expose a PDF export that overlays an optional admin logo, and link into editing flows.
- Settings let admins manage contact information, branding, and logo uploads (with resizing and Supabase storage integration).
- The “Buy Packs” page builds Lemonsqueezy checkout URLs with admin metadata and lists available bundles.

#### Family experience
- `FamilyCapsulePage` fetches the single capsule linked to the logged-in family user, shows memorial info, shares a QR/public URL, and exposes the “close capsule and trigger video generation” workflow that enqueues work in Supabase.
- `FamilyMessagesPage` lists capsule messages with pagination, moderation toggles, and quick links to media content, again scoped to the user’s assigned capsule.

#### Public invitees
- The public capsule page (routed via `/capsule/:id`) welcomes contributors, loads capsule context, and lets visitors submit text plus optional audio, video, or image attachments using Supabase storage helpers before creating a message record.

### Shared services and data models
- Service classes wrap Supabase operations: `AuthService` for sign-in/out and password resets, `CapsuleService` for CRUD plus role-aware queries and video job RPCs, `CreditsService` to check available credits, `MessageService` for paginated message management, `SettingsService` for profile data and logo uploads, `AdminService` for personalizing UI, `MediaUploadService` for binary uploads, and `PdfService` for generating branded memorial PDFs.
- Data models map Supabase rows to Dart objects for capsules (including invitation and message variants), messages, packs, and admin settings, providing JSON serialization helpers used throughout the services.

### Backend & integrations
- SQL scripts define tables and relationships, plus helper functions for credit bookkeeping (`update_admin_credits`), triggers that automatically recompute credits when packs or capsules change, a video job queue backed by PGMQ, and admin onboarding that grants a welcome pack.
- Edge functions enable frontend flows that require elevated permissions: one signs up family users via Supabase auth with role metadata, and another logs Lemonsqueezy webhooks, infers pack sizes, and upserts credits into `packs`.
- The video service integration guide documents how an external worker should consume the `video_jobs_queue`, assemble capsule content, and update Supabase once a memorial video is ready—critical reading before extending or operating the pipeline.
- `lumina.md` outlines how this admin app fits with other Lumina surfaces (funeral home UI, invitee portal, video service), helping you coordinate changes across products.

### Tooling, dependencies, and configuration
- `pubspec.yaml` lists core Flutter dependencies (Supabase Flutter SDK, Riverpod, GoRouter, multimedia helpers, DotEnv) and registers bundled assets including the `.env` file for runtime configuration.
- Shell scripts streamline development (`dev.sh` runs Flutter Web on port 3000), production builds, and Cloudflare Pages deployment.
- The Supabase CLI config (`supabase/config.toml`) enables local replication of the hosted environment; pair it with the SQL files to apply schema locally when needed.

### What to learn next
- Follow the video service guide to understand how closing a capsule triggers downstream video rendering and what responsibilities the external worker bears.
- Dive into the SQL helpers (especially the credit functions and video queue RPCs) to see how business rules are enforced at the database layer before adjusting capsule creation or purchasing flows.
- Review the edge functions to grasp how Supabase service role keys and REST endpoints are used so you can confidently extend automation (for example, sending transactional emails or syncing CRM data).
- Explore related apps described in `lumina.md` to align UI/UX changes across admin, family, and invitee experiences and ensure consistent data contracts.

## Features

### Authentication & User Management
- **Magic Link Login**: Secure authentication without passwords
- **Password Reset**: Email-based password recovery
- **GDPR Compliance**: Built-in consent management

### Capsule Management
- **Create Capsules**: Generate new digital time capsules with custom names and descriptions
- **Family User Creation**: Automatically create family accounts for capsule recipients
- **Credit System**: Manage capsule creation limits with credit tracking
- **Capsule Listing**: View and filter all capsules by status
- **Responsive Dashboard**: Modern UI with responsive design

### Admin Settings
- **Profile Management**: Update business name, email, and phone number
- **Logo Upload**: Upload and manage custom business logos
- **Settings Storage**: Flexible JSONB storage for additional configuration
- **Image Storage**: Secure logo storage in Supabase storage buckets

### E-commerce Integration
- **Lemonsqueezy Integration**: Purchase capsule packs directly from the admin panel
- **Credit Purchasing**: Buy packs of 5, 10, 20, 50, or 100 capsules
- **Webhook Support**: Automatic credit allocation via webhooks

## Tech Stack

- **Frontend**: Flutter Web
- **Backend**: Supabase (PostgreSQL + Auth + Edge Functions)
- **E-commerce**: Lemonsqueezy
- **Environment**: Flutter 3.x

## Setup Instructions

### Prerequisites
- Flutter SDK (3.x or higher)
- Supabase account and project
- Lemonsqueezy account

### Environment Configuration

1. Create a `.env` file in the project root:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
LEMON_SQUEEZY_STORE_ID=your_store_id
```

2. Update `pubspec.yaml` to include environment variables:
```yaml
flutter:
  assets:
    - .env
```

### Database Schema

The application uses the following Supabase tables:

#### users
- `id`: UUID (primary key)
- `email`: String
- `role`: String (admin/family)
- `credits`: Integer
- `family_id`: UUID (nullable)
- `created_at`: Timestamp

#### capsules
- `id`: UUID (primary key)
- `name`: String
- `description`: String
- `admin_id`: UUID (references users.id)
- `family_id`: UUID (references users.id)
- `status`: String
- `scheduled_date`: Timestamp (nullable)
- `created_at`: Timestamp

#### admins
- `admin_id`: UUID (primary key, references users.id)
- `name`: String (nullable)
- `email`: String (nullable)
- `phone`: String (nullable)
- `logo_image`: String (nullable)
- `info`: JSONB (nullable)
- `created_at`: Timestamp
- `updated_at`: Timestamp

### Installation

1. Clone the repository
2. Install dependencies:
```bash
flutter pub get
```

3. Configure environment variables (see above)

4. Run the development server:
```bash
flutter run -d chrome
```

### Production Deployment

Use the provided deployment scripts:
```bash
# Build for production
./build.sh

# Deploy to your hosting platform
./deploy.sh
```

## Key Features Implementation

### Authentication Flow
- Magic link authentication via Supabase
- Session management and restoration
- GDPR consent enforcement
- Password reset functionality

### Capsule Creation Process
1. Admin enters capsule details (name, description, family email)
2. System creates new family user account
3. Capsule is created with admin and family associations
4. Credits are deducted from admin account
5. Family receives email with login credentials

### E-commerce Integration
- Dynamic checkout URL generation with user ID
- Credit allocation via webhook processing
- Multiple pack sizes with volume discounts

## Security Considerations

- Environment variables for sensitive configuration
- Backend user creation via Supabase Edge Functions
- CORS configuration for API endpoints
- Session-based authentication
- Role-based access control

## Development

### Project Structure
```
lib/
├── main.dart              # App entry point
├── models/
│   └── capsule.dart       # Data models
├── pages/
│   ├── admin/            # Admin-specific pages
│   └── auth/             # Authentication pages
├── services/
│   ├── auth_service.dart # Authentication logic
│   └── capsule_service.dart # Capsule management
└── widgets/
    └── media_upload.dart # Reusable components
```

### Key Services

#### AuthService
- User authentication and session management
- Magic link and password reset functionality
- User role and credit management

#### CapsuleService
- Capsule CRUD operations
- Family user creation
- Credit management

#### SettingsService
- Admin settings management
- Logo upload and storage
- Profile information updates

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[Add your license information here]

## Support

For support and questions, please contact [your contact information].
