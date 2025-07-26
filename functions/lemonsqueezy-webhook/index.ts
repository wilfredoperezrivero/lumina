import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Headers": "*",
    "Access-Control-Allow-Methods": "OPTIONS,POST",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Max-Age": "600",
  };

  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Parse webhook payload
  let payload;
  try {
    payload = await req.json();
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400, headers: corsHeaders });
  }

  // Map LemonSqueezy webhook fields to packs table fields
  // Adjust these mappings to match your actual schema and payload
  const pack = {
    id: payload.data?.id, // LemonSqueezy product or order ID
    name: payload.data?.attributes?.name || payload.data?.attributes?.product_name,
    price: payload.data?.attributes?.price || 0,
    // Add more fields as needed
  };

  // Upsert pack in Supabase using REST API
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  const upsertResponse = await fetch(`${supabaseUrl}/rest/v1/packs`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${serviceRoleKey}`,
      'apikey': serviceRoleKey,
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates',
    },
    body: JSON.stringify([pack]),
  });

  const upsertData = await upsertResponse.json();
  if (!upsertResponse.ok) {
    return new Response(JSON.stringify({ error: upsertData }), { status: 400, headers: corsHeaders });
  }

  return new Response(JSON.stringify({ success: true, data: upsertData }), { status: 200, headers: corsHeaders });
}); 