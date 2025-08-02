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

  // Save payment data to payments_logs table FIRST - before any processing
  const paymentLog = {
    webhook_payload: payload,
    admin_id: null // Will be extracted and updated later
  };

  // Insert payment log first
  console.log('Saving payment log to:', `${supabaseUrl}/rest/v1/payments_logs`);
  console.log('Payment log data:', JSON.stringify(paymentLog));
  
  const logResponse = await fetch(`${supabaseUrl}/rest/v1/payments_logs`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${serviceRoleKey}`,
      'apikey': serviceRoleKey,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
    body: JSON.stringify([paymentLog]),
  });

  console.log('Log response status:', logResponse.status);
  console.log('Log response headers:', Object.fromEntries(logResponse.headers.entries()));

  if (!logResponse.ok) {
    let logError;
    try {
      const errorText = await logResponse.text();
      console.log('Error response text:', errorText);
      logError = JSON.parse(errorText);
    } catch (e) {
      logError = { error: 'Failed to parse error response', status: logResponse.status };
    }
    console.error('Failed to save payment log:', logError);
    return new Response(JSON.stringify({ error: 'Failed to save payment log', details: logError }), { status: 500, headers: corsHeaders });
  }

  let logData;
  try {
    const responseText = await logResponse.text();
    console.log('Success response text:', responseText);
    
    if (responseText.trim() === '') {
      console.log('Empty response, creating dummy log data');
      logData = [{ id: 'temp-id-' + Date.now() }];
    } else {
      logData = JSON.parse(responseText);
    }
  } catch (e) {
    console.error('Failed to parse log response:', e);
    console.log('Response text was:', await logResponse.text());
    return new Response(JSON.stringify({ error: 'Failed to parse log response', details: e.message }), { status: 500, headers: corsHeaders });
  }
  
  const paymentLogId = logData[0]?.id;
  console.log('Payment log saved with ID:', paymentLogId);

  // Extract admin_id: try meta.custom_data.admin_id, then attributes.custom_data.admin_id, then attributes.admin_id
  let adminId = payload?.meta?.custom_data?.admin_id
    || payload?.data?.attributes?.custom_data?.admin_id
    || payload?.data?.attributes?.admin_id;
  console.log('Parsed admin_id:', adminId);

  // Calculate capsulesAllowed from first_order_item.variant_name (e.g., 'Pack 25')
  let capsulesAllowed = 0;
  const variantName = payload?.data?.attributes?.first_order_item?.variant_name;
  if (variantName) {
    const match = variantName.match(/(\d+)/);
    if (match) {
      capsulesAllowed = parseInt(match[1], 10);
    }
  }
  console.log('Parsed capsulesAllowed from variant_name:', capsulesAllowed, 'variant_name:', variantName);

  // Update payment log with admin_id if we found one
  if (adminId && paymentLogId) {
    const updateResponse = await fetch(`${supabaseUrl}/rest/v1/payments_logs?id=eq.${paymentLogId}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${serviceRoleKey}`,
        'apikey': serviceRoleKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ admin_id: adminId }),
    });
    
    if (updateResponse.ok) {
      console.log('Updated payment log with admin_id:', adminId);
    } else {
      console.error('Failed to update payment log with admin_id');
    }
  }

  // Validate required fields
  if (!adminId) {
    return new Response(JSON.stringify({ error: 'Missing admin_id in webhook payload' }), { status: 400, headers: corsHeaders });
  }
  if (!capsulesAllowed || capsulesAllowed <= 0) {
    return new Response(JSON.stringify({ error: 'Could not determine capsules_allowed from variant_name' }), { status: 400, headers: corsHeaders });
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

  let upsertData;
  try {
    upsertData = await upsertResponse.json();
  } catch (e) {
    console.error('Failed to parse upsert response:', e);
    return new Response(JSON.stringify({ error: 'Failed to parse upsert response' }), { status: 500, headers: corsHeaders });
  }
  
  if (!upsertResponse.ok) {
    console.error('Failed to upsert pack:', upsertData);
    return new Response(JSON.stringify({ error: upsertData }), { status: 400, headers: corsHeaders });
  }

  console.log('Successfully created pack:', { adminId, capsulesAllowed, packId: upsertData[0]?.id });
  return new Response(JSON.stringify({ success: true, data: upsertData }), { status: 200, headers: corsHeaders });
}); 