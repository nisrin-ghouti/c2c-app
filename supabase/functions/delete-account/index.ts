// Self-service account deletion for the C2C app.
//
// Required by App Store Guideline 5.1.1(v): an app that lets users create an
// account must let them delete it from inside the app. The Flutter client
// cannot remove its own `auth.users` row, so this runs with the project's
// service-role key (never exposed to the app).
//
// It deletes the *calling* user and takes no user id argument: the caller is
// resolved from their own JWT, so this endpoint can never be used to delete
// somebody else's account.
//
// Deploy with: supabase functions deploy delete-account
// (SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY are injected
// automatically by the Supabase platform — no extra secrets to configure.)
//
// NOTE: since migration 0088 this SCHEDULES deletion rather than performing
// it. The account is deactivated immediately and purged 30 days later by
// `purge_expired_deleted_accounts()`, unless the user signs in first — which
// cancels it. See 0088 for the full reasoning.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, content-type, apikey, x-client-info",
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return jsonResponse({ error: "unauthorized" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Identify the caller from their own JWT (RLS-scoped, no elevated access).
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: callerData, error: callerError } =
      await callerClient.auth.getUser();
    if (callerError || !callerData.user) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const userId = callerData.user.id;

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // Deletion is now a 30-DAY DEACTIVATION, not an immediate purge.
    //
    // `request_account_deletion` stamps `deletion_requested_at` and sets
    // `deleted_at`, which deactivates the account everywhere that already
    // filters soft-deleted profiles. Nothing is destroyed yet: signing in
    // before the deadline calls `cancel_account_deletion()` and the account
    // comes back whole. The irreversible work still happens exactly once, in
    // `purge_user_account`, driven by the scheduled sweep (migration 0088).
    //
    // The auth user is deliberately LEFT IN PLACE. Removing it would make
    // signing in impossible, and signing in is the documented way to cancel —
    // deleting it here would turn the grace period into a 30-day wait for a
    // deletion the user could no longer stop.
    const { data: requested, error: requestError } = await adminClient.rpc(
      "request_account_deletion",
      { _user_id: userId },
    );
    if (requestError) {
      return jsonResponse({ error: requestError.message }, 500);
    }
    if (requested?.status === "not_found") {
      return jsonResponse({ error: "Profile not found" }, 404);
    }

    return jsonResponse({
      ok: true,
      scheduled: true,
      requested_at: requested?.requested_at ?? null,
      purge_after: requested?.purge_after ?? null,
    }, 200);
  } catch (err) {
    return jsonResponse({ error: String(err) }, 500);
  }
});
