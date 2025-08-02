#!/bin/bash

# This script runs the lemonsqueezy-webhook/index.ts function locally with test1.json as input
# Requires: deno installed (https://deno.com/manual/getting_started/installation)

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

echo "Starting local webhook server..."
echo "Test payload from: $TEST_JSON_PATH"
echo ""

# Start the server in the background
deno run --allow-env --allow-net --allow-read "$FUNCTION_PATH" &
SERVER_PID=$!

# Wait a moment for server to start
sleep 2

# Send the test request
echo "Sending test request..."
curl -X POST http://localhost:8000 \
  -H "Content-Type: application/json" \
  -d @"$TEST_JSON_PATH" \
  -v

echo ""
echo "Test completed. Stopping server..."

# Stop the server
kill $SERVER_PID 2>/dev/null || true

echo "Server stopped." 