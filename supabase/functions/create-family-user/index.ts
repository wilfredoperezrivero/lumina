// deno-lint-ignore-file
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
};

const corsHeaders = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "OPTIONS,GET,POST",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Max-Age": "600",
};

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, capsuleName } = await req.json();
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const supabaseUrl = Deno.env.get('SUPABASE_URL');

    if (!serviceRoleKey || !supabaseUrl) {
      console.error('Missing environment variables');
      return new Response(JSON.stringify({
        success: false,
        message: 'Server configuration error'
      }), {
        status: 500,
        headers: corsHeaders,
      });
    }

    // Create Supabase client with service role key for admin operations
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    console.log('Creating family user for:', email, 'capsule:', capsuleName);

    // First, check if user already exists by listing users with email filter
    const { data: listData } = await supabase.auth.admin.listUsers();
    const existingUser = listData?.users?.find((u: { email?: string }) => u.email === email);

    let userId: string;

    if (existingUser) {
      // User already exists, use their ID
      console.log('User already exists:', existingUser.id);
      userId = existingUser.id;

      // Send magic link to existing user
      const { error: otpError } = await supabase.auth.signInWithOtp({
        email,
        options: {
          emailRedirectTo: 'https://app.luminamemorials.com/family/capsule',
        },
      });

      if (otpError) {
        console.error('Magic link error:', otpError);
        return new Response(JSON.stringify({
          error: otpError,
          message: 'Failed to send magic link to existing user'
        }), {
          status: 400,
          headers: corsHeaders,
        });
      }
    } else {
      // Create new user with admin API and generate invite link
      // This ensures the user gets a proper invite email with working login link
      const { data: newUser, error: createError } = await supabase.auth.admin.inviteUserByEmail(email, {
        redirectTo: 'https://app.luminamemorials.com/family/capsule',
        data: {
          role: 'family',
          capsule_name: capsuleName,
          display_name: `Capsule: ${capsuleName}`,
        },
      });

      if (createError) {
        console.error('User invitation error:', createError);
        return new Response(JSON.stringify({
          error: createError,
          message: 'Failed to invite user'
        }), {
          status: 400,
          headers: corsHeaders,
        });
      }

      console.log('User invited:', newUser.user.id);
      userId = newUser.user.id;
    }

    console.log('Magic link sent successfully');

    return new Response(JSON.stringify({
      success: true,
      message: 'User created and magic link sent',
      user: {
        id: userId,
        email: email,
      }
    }), {
      status: 200,
      headers: corsHeaders,
    });

  } catch (error: unknown) {
    console.error('Unexpected error:', error);
    const message = error instanceof Error ? error.message : 'An unexpected error occurred';
    return new Response(JSON.stringify({
      success: false,
      message
    }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});