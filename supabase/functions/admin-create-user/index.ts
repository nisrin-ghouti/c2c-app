// Manual account creation for the C2C admin panel.
//
// Runs with the project's service-role key (never exposed to the Flutter
// app) so it can call `auth.admin.createUser`, something the client SDK
// cannot do safely. The caller's own JWT is verified first — only an
// existing admin (a `user_roles` row with role = 'admin') may invoke this.
//
// Deploy with: supabase functions deploy admin-create-user
// (SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY are injected
// automatically by the Supabase platform — no extra secrets to configure.)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ALLOWED_ROLES = ["student", "host", "admin", "host_group_manager"];

// What a host group manager may create, and it is the whole list: host, and
// nothing else. Not a subset of ALLOWED_ROLES by coincidence — the check below
// compares against this array specifically, so widening ALLOWED_ROLES for
// admins can never widen what a manager can do.
const MANAGER_CREATABLE_ROLES = ["host"];

// The admin panel is a browser-based Flutter web app, so every call here is
// cross-origin — without these headers the browser's OPTIONS preflight fails
// before the request body (and the caller's Authorization JWT) ever reaches
// the handler below, and the client just sees an opaque network error.
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  // supabase_flutter's client adds `apikey`/`x-client-info` to every
  // request automatically (not just `authorization`/`content-type`) — a
  // header the actual request sends that isn't listed here gets the whole
  // call blocked client-side at the preflight, before it ever reaches this
  // function, and shows up as an opaque "Failed to fetch".
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
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

    // Verify the caller using their own JWT (RLS-scoped, no elevated access).
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: callerData, error: callerError } = await callerClient.auth.getUser();
    if (callerError || !callerData.user) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    // Two kinds of caller may reach this function, with very different
    // powers. Read both role rows in one query rather than two round trips.
    const { data: callerRoleRows, error: callerRoleError } = await callerClient
      .from("user_roles")
      .select("role")
      .eq("user_id", callerData.user.id)
      .in("role", ["admin", "host_group_manager"]);
    if (callerRoleError) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const callerRoles = (callerRoleRows ?? []).map((r) => r.role);
    const isAdmin = callerRoles.includes("admin");
    const isGroupManager = callerRoles.includes("host_group_manager");

    if (!isAdmin && !isGroupManager) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const body = await req.json().catch(() => null);
    const email = body?.email?.trim();
    const password = body?.password;
    const fullName = body?.fullName?.trim();
    // Accepts either the legacy single `role` string or a `roles` array —
    // an admin can now grant any combination (e.g. Host + Admin with no
    // Student) rather than always getting Student as an implicit baseline.
    const roles: string[] = Array.isArray(body?.roles)
      ? body.roles
      : body?.role
      ? [body.role]
      : [];

    if (!email || !password || !fullName || roles.length === 0) {
      return jsonResponse({ error: "invalid_request" }, 400);
    }
    if (roles.some((r) => !ALLOWED_ROLES.includes(r))) {
      return jsonResponse({ error: "invalid_role" }, 400);
    }

    // A group manager who is not also an admin may create hosts and nothing
    // else — no students, no admins, and in particular no further group
    // managers, which would otherwise let the role propagate itself.
    //
    // Checked here, server-side, because the admin panel hides the other
    // options but a direct call to this function would not be bound by that.
    if (!isAdmin) {
      const requested = [...new Set(roles)];
      const allowed =
        requested.length > 0 &&
        requested.every((r) => MANAGER_CREATABLE_ROLES.includes(r));
      if (!allowed) {
        return jsonResponse({ error: "forbidden_role" }, 403);
      }
    }

    // Elevated client — only used from here down, never touches the request's
    // own Authorization header.
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: created, error: createError } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      // `created_by_console` is read by the `assign_student_role_on_signup`
      // trigger (migration 0085), which auto-grants Student to anyone who
      // registers through the app. Accounts created here choose their roles
      // explicitly — an Admin-only or Host-only account is a supported thing,
      // and is excluded from matching/points/benefits server-side — so the
      // trigger must skip them. Removing this flag silently reintroduces the
      // implicit Student baseline this function exists to avoid.
      user_metadata: { full_name: fullName, created_by_console: true },
    });
    if (createError || !created.user) {
      const message = createError?.message ?? "create_failed";
      const code = /already|exists|registered/i.test(message) ? "user_already_exists" : message;
      return jsonResponse({ error: code }, 400);
    }

    const newUserId = created.user.id;

    const { error: profileError } = await adminClient.from("profiles").upsert({
      id: newUserId,
      full_name: fullName,
      email,
    });
    if (profileError) return jsonResponse({ error: profileError.message }, 500);

    // Exactly the roles the admin chose — no implicit Student baseline.
    // An account with only Admin and/or Host granted is deliberately not a
    // student: it won't appear in matching, and can't earn points or
    // redeem benefits (enforced server-side by `is_student_eligible`).
    const uniqueRoles = [...new Set(roles)];
    const roleRows = uniqueRoles.map((r) => ({
      user_id: newUserId,
      role: r,
    }));
    const { error: roleInsertError } = await adminClient.from("user_roles").insert(roleRows);
    if (roleInsertError) return jsonResponse({ error: roleInsertError.message }, 500);

    // A host created by a group manager joins that manager's group, and the
    // creator is recorded separately so it survives a later reassignment.
    //
    // Done here with the service-role key rather than from the client: the
    // RPC is not granted to `authenticated` precisely so a manager cannot
    // claim an account they did not create. Failing this step would leave an
    // orphan host nobody manages, so it is reported rather than swallowed.
    if (!isAdmin && isGroupManager) {
      const { data: bindResult, error: bindError } = await adminClient.rpc(
        "record_manager_created_host",
        { _host_id: newUserId, _manager_id: callerData.user.id },
      );
      if (bindError || bindResult?.status !== "ok") {
        return jsonResponse(
          { error: bindError?.message ?? "group_bind_failed", id: newUserId },
          500,
        );
      }
    }

    return jsonResponse({ id: newUserId, email, full_name: fullName }, 200);
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
