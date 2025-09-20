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
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const supabaseUrl = Deno.env.get('SUPABASE_URL');

  // Create Supabase client with anon key
  const supabase = createClient(supabaseUrl, anonKey);

  // Use signUp to create a user (sends confirmation email if enabled)
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        role: 'family',
        capsule_name: capsuleName,
        display_name: `Capsule: ${capsuleName}`,
      },
      emailRedirectTo: 'https://app.luminamemorials.com'
    }
  });

  if (error) {
    return new Response(JSON.stringify({ error }), {
      status: 400,
      headers: corsHeaders,
    });
  }

  return new Response(
    JSON.stringify({
      message:
        'Magic-link email sent. The family user must click the link to complete sign-up.',
      user: data.user, // may be null until email is confirmed
      session: data.session,
    }),
    {
      status: 200,
      headers: corsHeaders,
    }
  );
});