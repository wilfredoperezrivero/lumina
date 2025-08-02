#!/bin/bash

# Debug script for lemonsqueezy-webhook - starts server and keeps it running
# You can then manually test with curl or other tools

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTION_PATH="$SCRIPT_DIR/index.ts"
TEST_JSON_PATH="$SCRIPT_DIR/test1.json"

if [ ! -f "$FUNCTION_PATH" ]; then
  echo "index.ts not found at $FUNCTION_PATH"
  exit 1
fi
if [ ! -f "$TEST_JSON_PATH" ]; then
  echo "test1.json not found at $TEST_JSON_PATH"
  exit 1
fi

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

echo "=== LemonSqueezy Webhook Debug Mode ==="
echo "Server will start on http://localhost:8000"
echo "Test payload available at: $TEST_JSON_PATH"
echo ""
echo "To test the webhook, run in another terminal:"
echo "curl -X POST http://localhost:8000 \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d @$TEST_JSON_PATH"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server in foreground (for debugging)
deno run --allow-env --allow-net --allow-read "$FUNCTION_PATH" 