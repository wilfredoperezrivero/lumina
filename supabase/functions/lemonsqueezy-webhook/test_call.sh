#!/bin/bash

# This script opens the LemonSqueezy buy URL with admin_id parameter for testing
# This simulates what happens when a user clicks "Buy Packs" in the Flutter app

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from .env.server in the root folder
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../" && pwd)"
ENV_FILE="$ROOT_DIR/.env.server"

if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE"
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "Warning: .env.server file not found at $ENV_FILE"
  echo "Please create a .env.server file in the root folder with the following variables:"
  echo "SUPABASE_URL=your_supabase_url"
  echo "SUPABASE_SERVICE_ROLE_KEY=your_service_role_key"
  echo "SUPABASE_ANON_KEY=your_anon_key"
  echo "LEMON_SQUEEZY_WEBHOOK_SECRET=your_webhook_secret"
  exit 1
fi

# Get admin_id from environment or prompt user
ADMIN_ID=${ADMIN_ID:-""}

if [ -z "$ADMIN_ID" ]; then
  echo "No ADMIN_ID found in environment variables."
  echo "Please enter an admin_id (UUID) to test with:"
  read -p "Admin ID: " ADMIN_ID
  
  if [ -z "$ADMIN_ID" ]; then
    echo "No admin_id provided. Exiting."
    exit 1
  fi
fi

# Validate UUID format (basic check)
if [[ ! $ADMIN_ID =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
  echo "Warning: Admin ID doesn't appear to be in valid UUID format: $ADMIN_ID"
  echo "Continue anyway? (y/N)"
  read -p "" -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Get checkout information
echo ""
echo "Enter checkout information (or press Enter to use defaults):"

# Email
DEFAULT_EMAIL="test@example.com"
read -p "Email [$DEFAULT_EMAIL]: " EMAIL
EMAIL=${EMAIL:-$DEFAULT_EMAIL}

# Name
DEFAULT_NAME="Test User"
read -p "Name [$DEFAULT_NAME]: " NAME
NAME=${NAME:-$DEFAULT_NAME}

# Build the LemonSqueezy URL with all checkout parameters
BASE_URL="https://luminamemorials.lemonsqueezy.com/buy/5a9d4848-1038-48ae-ba71-9c81412c9789"
FULL_URL="${BASE_URL}?checkout[custom][admin_id]=${ADMIN_ID}&checkout[email]=${EMAIL}&checkout[name]=${NAME}"

echo "=== LemonSqueezy Test Call ==="
echo "Admin ID: $ADMIN_ID"
echo "Email: $EMAIL"
echo "Name: $NAME"
echo "Base URL: $BASE_URL"
echo "Full URL: $FULL_URL"
echo ""

# Check if we're on macOS (for open command)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Opening LemonSqueezy URL in default browser..."
  open "$FULL_URL"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "Opening LemonSqueezy URL in default browser..."
  xdg-open "$FULL_URL" 2>/dev/null || sensible-browser "$FULL_URL" 2>/dev/null || echo "Please open manually: $FULL_URL"
else
  echo "Please open this URL manually in your browser:"
  echo "$FULL_URL"
fi

echo ""
echo "After completing the purchase, the webhook will be called with admin_id: $ADMIN_ID"
echo "You can monitor webhook calls using:"
echo "  supabase functions logs lemonsqueezy-webhook --follow"
echo ""
echo "Or test locally with:"
echo "  bash test_local.sh" 