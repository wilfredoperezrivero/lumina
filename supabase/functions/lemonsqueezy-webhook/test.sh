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

# Set the function endpoint
FUNCTION_URL="$SUPABASE_URL/functions/v1/lemonsqueezy-webhook"

# Example LemonSqueezy webhook payload (edit as needed)
read -r -d '' PAYLOAD << EOM
{
  "meta": {
    "event_name": "order_created"
  },
  "data": {
    "id": 12345,
    "attributes": {
      "name": "Sample Pack",
      "price": 1999
    }
  }
}
EOM

# Print for debugging
echo "POST $FUNCTION_URL"
echo "Authorization: Bearer $SUPABASE_ANON_KEY"
echo "$PAYLOAD"

# Call the function using curl
curl -X POST "$FUNCTION_URL" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" 