# Lumina Admin

A Flutter web application for managing Lumina Memorial capsules - digital time capsules for preserving memories and messages for loved ones.

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
