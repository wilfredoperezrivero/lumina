import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Headers": "*",
    "Access-Control-Allow-Methods": "OPTIONS,GET,POST",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Max-Age": "600",
  };

  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const { email, password, capsuleName } = await req.json();
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const supabaseUrl = Deno.env.get('SUPABASE_URL');

  // Create Supabase client with service role key for admin operations
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  // 🔄  Create-OR-login via magic link (signInWithOtp creates the user automatically)
  console.log('Sending magic link to:', email, 'for capsule:', capsuleName);

  const { data, error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: 'https://app.luminamemorials.com/family/capsule',
      data: {
        role: 'family',
        capsule_name: capsuleName,
        display_name: `Capsule: ${capsuleName}`,
      },
    },
  });

  if (error) {
    console.error('Magic link error:', error);
    return new Response(JSON.stringify({ 
      error,
      message: 'Failed to send magic link'
    }), {
      status: 400,
      headers: corsHeaders,
    });
  }

  console.log('Magic link sent successfully:', data);

  return new Response(JSON.stringify({ 
    success: true, 
    message: 'User created and magic link sent',
    user: data.user 
  }), {
    status: 200,
    headers: corsHeaders,
  });
});