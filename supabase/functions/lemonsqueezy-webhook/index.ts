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

  // Get Supabase configuration
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  // Extract admin_id from custom fields
  const customFields = payload.data?.attributes?.custom_data || {};
  const adminId = customFields.admin_id;

  // Save payment data to payments_logs table first
  const paymentLog = {
    webhook_payload: payload,
    admin_id: adminId
  };

  // Insert payment log
  const logResponse = await fetch(`${supabaseUrl}/rest/v1/payments_logs`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${serviceRoleKey}`,
      'apikey': serviceRoleKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify([paymentLog]),
  });

  if (!logResponse.ok) {
    const logError = await logResponse.json();
    console.error('Failed to save payment log:', logError);
    return new Response(JSON.stringify({ error: 'Failed to save payment log' }), { status: 500, headers: corsHeaders });
  }

  return new Response(JSON.stringify({ success: true, data: logResponse }), { status: 200, headers: corsHeaders });

  const logData = await logResponse.json();
  const paymentLogId = logData[0]?.id;

  console.log('Payment log saved:', { paymentLogId, adminId });

  // Validate required fields
  if (!adminId) {
    return new Response(JSON.stringify({ error: 'Missing admin_id in custom fields' }), { status: 400, headers: corsHeaders });
  }

  // Determine capsules_allowed based on product ID or variant
  const productId = payload.data?.attributes?.product_id;
  const variantId = payload.data?.attributes?.variant_id;
  const productName = payload.data?.attributes?.product_name;
  let capsulesAllowed = 0;

  // Map product/variant IDs to capsule counts
  // You'll need to update these IDs based on your actual LemonSqueezy product setup
  if (productId === 'your-5-pack-product-id' || variantId === 'your-5-pack-variant-id') {
    capsulesAllowed = 5;
  } else if (productId === 'your-10-pack-product-id' || variantId === 'your-10-pack-variant-id') {
    capsulesAllowed = 10;
  } else if (productId === 'your-20-pack-product-id' || variantId === 'your-20-pack-variant-id') {
    capsulesAllowed = 20;
  } else if (productId === 'your-50-pack-product-id' || variantId === 'your-50-pack-variant-id') {
    capsulesAllowed = 50;
  } else if (productId === 'your-100-pack-product-id' || variantId === 'your-100-pack-variant-id') {
    capsulesAllowed = 100;
  } else {
    // Fallback: try to extract from product name
    const match = productName?.match(/(\d+)/);
    if (match) {
      capsulesAllowed = parseInt(match[1]);
    }
  }

  if (!capsulesAllowed || capsulesAllowed <= 0) {
    return new Response(JSON.stringify({ error: 'Could not determine capsules_allowed from product data' }), { status: 400, headers: corsHeaders });
  }

  // Map LemonSqueezy webhook fields to packs table fields
  const pack = {
    id: payload.data?.id, // LemonSqueezy order ID
    admin_id: adminId,
    pack_type: payload.data?.attributes?.product_name || 'Unknown',
    purchased_at: payload.data?.attributes?.created_at,
    capsules_allowed: capsulesAllowed,
    capsules_used: 0, // Default to 0 for new packs
    payment_status: payload.data?.attributes?.status === 'paid' ? 'paid' : 'pending',
  };

  // Upsert pack in Supabase using REST API
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
    console.error('Failed to upsert pack:', upsertData);
    return new Response(JSON.stringify({ error: upsertData }), { status: 400, headers: corsHeaders });
  }

  console.log('Successfully created pack:', { adminId, capsulesAllowed, packId: upsertData[0]?.id, paymentLogId });
  return new Response(JSON.stringify({ success: true, data: upsertData }), { status: 200, headers: corsHeaders });
}); 