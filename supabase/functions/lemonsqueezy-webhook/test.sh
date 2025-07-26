#!/bin/bash

# Load environment variables from .env if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Check required variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env file."
  exit 1
fi

# Set the path to test1.json
TEST_JSON_PATH="supabase/functions/lemonsqueezy-webhook/test1.json"
if [ ! -f "$TEST_JSON_PATH" ]; then
  echo "$TEST_JSON_PATH file not found."
  exit 1
fi

# Set the function endpoint
FUNCTION_URL="$SUPABASE_URL/functions/v1/lemonsqueezy-webhook"

# Print for debugging
echo "POST $FUNCTION_URL"
echo "Using payload from $TEST_JSON_PATH:"
cat "$TEST_JSON_PATH"
echo ""

# Call the function using curl with test1.json
curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d @"$TEST_JSON_PATH" 