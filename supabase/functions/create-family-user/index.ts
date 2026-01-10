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

    // Check if user already exists
    const { data: listData } = await supabase.auth.admin.listUsers();
    const existingUser = listData?.users?.find((u: { email?: string }) => u.email === email);

    let userId: string;

    if (existingUser) {
      // User already exists, use their ID
      console.log('User already exists:', existingUser.id);
      userId = existingUser.id;
    } else {
      // Create new user with admin API (no password - magic link only)
      // Generate a random password that won't be used (magic link login only)
      const randomPassword = crypto.randomUUID() + crypto.randomUUID();

      const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
        email,
        password: randomPassword,
        email_confirm: true, // Auto-confirm email so magic link works immediately
        user_metadata: {
          role: 'family',
          capsule_name: capsuleName,
          display_name: `Capsule: ${capsuleName}`,
        },
      });

      if (createError) {
        console.error('User creation error:', createError);
        return new Response(JSON.stringify({
          error: createError,
          message: 'Failed to create user'
        }), {
          status: 400,
          headers: corsHeaders,
        });
      }

      console.log('User created:', newUser.user.id);
      userId = newUser.user.id;
    }

    // Send magic link to the user (works for both new and existing users)
    const { error: otpError } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: 'https://app.luminamemorials.com/family/capsule',
      },
    });

    if (otpError) {
      console.error('Magic link error:', otpError);
      return new Response(JSON.stringify({
        success: true, // User was created, just magic link failed
        message: 'User created but failed to send magic link. You can resend from capsule details.',
        user: {
          id: userId,
          email: email,
        },
        warning: otpError.message,
      }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    console.log('Magic link sent successfully to:', email);

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
