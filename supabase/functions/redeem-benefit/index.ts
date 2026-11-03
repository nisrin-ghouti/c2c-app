// Supabase Edge Function: redeem-benefit
//
// JSON API backing the public redemption page (hosted on Firebase Hosting,
// since Supabase's edge gateway forces every non-`application/json` response
// into `text/plain` + a sandboxing CSP — it will not serve real HTML/JS from
// a *.supabase.co URL). The QR code points at the Firebase-hosted page,
// which calls GET here to look up the card and POST here to confirm the
// redemption via the same `redeem_digital_card` RPC the in-app admin
// scanner already uses.
//
// Security model: the token is an unguessable opaque UUID embedded in the
// QR, and `redeem_digital_card` is idempotent server-side (a second scan is
// rejected as `already_redeemed`) — same guarantees as the in-app scanner,
// just without requiring the partner to have an account.
//
// Provided automatically by the platform: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// Deploy: supabase functions deploy redeem-benefit --no-verify-jwt
// (must be public — the confirmation page calls it with no auth header)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "content-type",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

function tokenFromUrl(req: Request): string | null {
  const url = new URL(req.url);
  const fromQuery = url.searchParams.get("token");
  if (fromQuery) return fromQuery;
  const segments = url.pathname.split("/").filter(Boolean);
  const last = segments[segments.length - 1];
  if (!last || last === "redeem-benefit") return null;
  return last;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  const token = tokenFromUrl(req);
  if (!token) {
    return json({ status: "invalid" }, 200);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  if (req.method === "GET") {
    const { data: card } = await supabase
      .from("digital_cards")
      .select("status, benefits(title, partner_business_name)")
      .eq("qr_token", token)
      .maybeSingle();

    if (!card) {
      return json({ status: "not_found" });
    }

    const benefit = card.benefits as { title?: string; partner_business_name?: string } | null;

    if (card.status === "redeemed") {
      return json({
        status: "already_redeemed",
        title: benefit?.title,
        business: benefit?.partner_business_name,
      });
    }

    return json({
      status: "ok",
      title: benefit?.title,
      business: benefit?.partner_business_name,
    });
  }

  if (req.method === "POST") {
    const { data: result, error } = await supabase.rpc("redeem_digital_card_public", { _token: token });

    if (error) {
      return json({ status: "error" });
    }

    const status = (result as { status?: string; title?: string })?.status ?? "not_found";
    const title = (result as { status?: string; title?: string })?.title ?? "";

    return json({ status, title });
  }

  return json({ status: "method_not_allowed" }, 200);
});
