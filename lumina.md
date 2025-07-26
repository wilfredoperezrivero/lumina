# Lumina Memorials Platform



## Overview
This repository contains the backend and edge functions for the Lumina Memorials platform, which includes several apps for funeral homes, families, invitees, video services, and admin management.

## Apps

1. Funeral Homes: app.luminamemorials.com
2. Families: app.luminamemorials.com
3. Invitees: capsule.luminamemorials.com
4. Video Service
5. Admin: admin.luminamemorials.com


### 1. Funeral Homes ([app.luminamemorials.com](https://app.luminamemorials.com))
- **Features:**
  - Create capsules (name, description, date)
    - Creates a user and sends an email with an autologin link
    - Captures GDPR consent (to be reviewed for compliance)
  - List capsules and download QR codes
  - Purchase packs (integrated with LemonSqueezy)
    - Linked to a test product; webhook for order completion and credit update is pending
  - Settings: Update billing information (additional options TBD)

### 2. Families ([app.luminamemorials.com](https://app.luminamemorials.com))
- **Features:**
  - Receive an autologin link (currently not working when created by the funeral home)
  - Edit capsule name and description
  - View list of messages

### 3. Invitees ([capsule.luminamemorials.com](https://capsule.luminamemorials.com))
- **Features:**
  - Access via a link forwarded by the family (link includes `capsuleid` as a query parameter)

### 4. Video Service
- **Features:**
  - Internal service that generates videos and uploads them to Supabase Storage at `/v/capsuleid.mp4`
  - Saves the video URL in the `capsules.videourl` table
  - Reads videos to generate from a pgmq queue

### 5. Admin ([admin.luminamemorials.com](https://admin.luminamemorials.com))
- **Features (pending):**
  - Create, activate/deactivate users
  - Add credit

---

## Testing Instructions

1. **Funeral Homes Admin Dashboard:**
   - [https://app.luminamemorials.com/#/admin/dashboard](https://app.luminamemorials.com/#/admin/dashboard)
   - Login: `wilfredo.perez@gmail.com` / `test2025`
2. **Capsule Creation:**
   - You can create capsules and will receive an email (functionality still in progress)
3. **Invitee Link Example:**
   - [https://capsule.luminamemorials.com/?c=09a6a35f-b5c5-42a4-9b76-8245ad15c0e7](https://capsule.luminamemorials.com/?c=09a6a35f-b5c5-42a4-9b76-8245ad15c0e7)
4. **Video Service:**
   - N/A
5. **Admin:**
   - N/A

---

## Notes
- Some features are still under development or pending integration.
- Please review GDPR consent flow for compliance.
- Webhook integration for LemonSqueezy order completion is pending.

