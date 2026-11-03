// Auto-fills the English/Arabic/Hebrew translation columns on an event or
// benefit using the Google Cloud Translation API, right after the admin
// panel creates/updates one.
//
// Two modes, chosen by the caller's `mode` field:
//
//   fill_missing (default) — only fills columns that are currently empty, so
//     an admin's manual translation is never clobbered. This is what a plain
//     create wants, and what "Save this version only" wants.
//
//   propagate — regenerates every language EXCEPT `source_language` from the
//     canonical text, overwriting what was there. This is what the admin
//     panel's main Save means by "update all the language versions": the
//     admin edited one language and expects the other two to follow.
//
// Before this existed the function ignored `mode` entirely and always behaved
// as fill_missing. That silently broke the panel's main Save on every *edit*:
// the per-language columns were already populated from the original create,
// so nothing was ever empty, nothing was ever translated, and the call still
// returned 200 — the admin saw a successful save and stale translations.
//
// The language named by `source_language` is deliberately left alone in
// propagate mode: that column holds exactly what the admin just typed, and
// round-tripping it through Google Translate could only degrade it.
//
// The canonical (undecorated) column can be typed in ANY language — an
// admin isn't required to type in English. So every locale-specific slot
// (`_en`/`_ar`/`_he`) is filled via a real translate call when empty, even
// the one matching whatever language the canonical text happens to already
// be in: Google Translate is a no-op (returns the same text) when the
// detected source language equals the target, so this stays correct
// without needing a separate language-detection step.
//
// Runs with the service-role key so it can write these columns regardless
// of RLS, after checking the caller is a signed-in host/admin (the same
// roles allowed to create/update events/benefits in the first place).
//
// Deploy with: supabase functions deploy translate-content
// Needs the GOOGLE_TRANSLATE_API_KEY secret:
//   supabase secrets set GOOGLE_TRANSLATE_API_KEY=...

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

type TargetLang = "en" | "ar" | "he";
const TARGET_LANGS: TargetLang[] = ["en", "ar", "he"];

type Mode = "fill_missing" | "propagate";

function parseLang(value: unknown): TargetLang | null {
  return value === "en" || value === "ar" || value === "he" ? value : null;
}

// [canonical column, {en, ar, he} columns] per translatable field.
// `category` is deliberately excluded — it's a curated option_lists value
// translated via that table's own label_ar/label_he, not free text.
const FIELD_GROUPS: Record<string, [string, Record<TargetLang, string>][]> = {
  events: [
    ["title", { en: "title_en", ar: "title_ar", he: "title_he" }],
    ["description", { en: "description_en", ar: "description_ar", he: "description_he" }],
    ["location", { en: "location_en", ar: "location_ar", he: "location_he" }],
    ["organizer_name", { en: "organizer_name_en", ar: "organizer_name_ar", he: "organizer_name_he" }],
    [
      "organizer_description",
      { en: "organizer_description_en", ar: "organizer_description_ar", he: "organizer_description_he" },
    ],
  ],
  // Sessions are separate rows, so they get their own entry. They are never
  // requested directly by the admin app — it only ever has the event id, since
  // session ids are not returned when an event is created — so the handler
  // below fans out to them whenever an event is translated.
  event_sessions: [
    ["title", { en: "title_en", ar: "title_ar", he: "title_he" }],
    ["location", { en: "location_en", ar: "location_ar", he: "location_he" }],
  ],
  benefits: [
    ["title", { en: "title_en", ar: "title_ar", he: "title_he" }],
    ["description", { en: "description_en", ar: "description_ar", he: "description_he" }],
    ["location", { en: "location_en", ar: "location_ar", he: "location_he" }],
    [
      "partner_business_name",
      { en: "partner_business_name_en", ar: "partner_business_name_ar", he: "partner_business_name_he" },
    ],
    [
      "business_description",
      { en: "business_description_en", ar: "business_description_ar", he: "business_description_he" },
    ],
    ["how_to_redeem", { en: "how_to_redeem_en", ar: "how_to_redeem_ar", he: "how_to_redeem_he" }],
  ],
};

async function translateBatch(texts: string[], target: TargetLang, apiKey: string): Promise<string[]> {
  if (texts.length === 0) return [];
  const res = await fetch(`https://translation.googleapis.com/language/translate/v2?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ q: texts, target, format: "text" }),
  });
  if (!res.ok) {
    throw new Error(`Google Translate API error (${res.status}): ${await res.text()}`);
  }
  const json = await res.json();
  return json.data.translations.map((t: { translatedText: string }) => t.translatedText);
}


/// Writes the per-language columns of one row: the empty ones in
/// fill_missing mode, every non-source one in propagate mode. Returns the
/// columns it wrote, or null if the row is missing. Extracted so an event and
/// each of its sessions run identically.
async function translateRow(
  adminClient: ReturnType<typeof createClient>,
  table: string,
  id: string,
  translateApiKey: string,
  mode: Mode,
  sourceLang: TargetLang | null,
): Promise<string[] | null> {
  const groups = FIELD_GROUPS[table];
  if (!groups) return null;

  const columns = groups
    .flatMap(([canonicalCol, targets]) => [canonicalCol, targets.en, targets.ar, targets.he])
    .concat("id");
  const { data: row, error: rowError } = await adminClient
    .from(table)
    .select(columns.join(","))
    .eq("id", id)
    .single();
  if (rowError || !row) return null;

  // For each target language, collect the canonical texts that need writing
  // under the active mode, keeping track of which column each belongs to.
  const needs: Record<TargetLang, { column: string; text: string }[]> = { en: [], ar: [], he: [] };
  for (const [canonicalCol, targets] of groups) {
    const canonical = (row as Record<string, unknown>)[canonicalCol];
    if (typeof canonical !== "string" || canonical.trim() === "") continue;
    for (const lang of TARGET_LANGS) {
      const column = targets[lang];
      if (mode === "propagate") {
        // The admin just typed this language by hand — leave it exactly as
        // they wrote it, and refresh the other two from it.
        if (lang === sourceLang) continue;
        needs[lang].push({ column, text: canonical });
      } else if (!(row as Record<string, unknown>)[column]) {
        needs[lang].push({ column, text: canonical });
      }
    }
  }

  if (TARGET_LANGS.every((lang) => needs[lang].length === 0)) return [];

  const [enResults, arResults, heResults] = await Promise.all([
    translateBatch(needs.en.map((x) => x.text), "en", translateApiKey),
    translateBatch(needs.ar.map((x) => x.text), "ar", translateApiKey),
    translateBatch(needs.he.map((x) => x.text), "he", translateApiKey),
  ]);
  const results: Record<TargetLang, string[]> = { en: enResults, ar: arResults, he: heResults };

  const update: Record<string, string> = {};
  for (const lang of TARGET_LANGS) {
    needs[lang].forEach((x, i) => (update[x.column] = results[lang][i]));
  }

  const { error: updateError } = await adminClient.from(table).update(update).eq("id", id);
  if (updateError) throw new Error(updateError.message);

  return Object.keys(update);
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
    const translateApiKey = Deno.env.get("GOOGLE_TRANSLATE_API_KEY")!;

    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: callerData, error: callerError } = await callerClient.auth.getUser();
    if (callerError || !callerData.user) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const { data: roleRows } = await callerClient
      .from("user_roles")
      .select("role")
      .eq("user_id", callerData.user.id)
      .in("role", ["host", "admin"]);
    if (!roleRows || roleRows.length === 0) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const body = await req.json().catch(() => null);
    const table = body?.table;
    const id = body?.id;
    if (table !== "events" && table !== "benefits") {
      return jsonResponse({ error: "invalid_table" }, 400);
    }
    if (!id) {
      return jsonResponse({ error: "invalid_request" }, 400);
    }

    // Anything other than an explicit "propagate" stays on the safe,
    // never-overwrite path — including a caller that omits the field.
    const mode: Mode = body?.mode === "propagate" ? "propagate" : "fill_missing";
    const sourceLang = parseLang(body?.source_language);

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const translated = await translateRow(adminClient, table, id, translateApiKey, mode, sourceLang);
    if (translated === null) {
      return jsonResponse({ error: "not_found" }, 404);
    }

    // An event's sessions carry their own title and location, shown in the
    // student app's session list. The admin app cannot ask for these itself:
    // creating an event returns only the event id, never the session ids. So
    // translating an event fans out to its sessions here.
    //
    // A session failure is swallowed deliberately — the event's own
    // translation has already been written, and a missing session translation
    // just falls back to the canonical text.
    const sessionsTranslated: Record<string, string[]> = {};
    if (table === "events") {
      const { data: sessions } = await adminClient
        .from("event_sessions")
        .select("id")
        .eq("event_id", id);
      for (const session of sessions ?? []) {
        const sessionId = (session as { id?: string }).id;
        if (!sessionId) continue;
        try {
          const cols = await translateRow(
            adminClient,
            "event_sessions",
            sessionId,
            translateApiKey,
            mode,
            sourceLang,
          );
          if (cols && cols.length > 0) sessionsTranslated[sessionId] = cols;
        } catch (_) {
          // Leave this session untranslated rather than failing the request.
        }
      }
    }

    return jsonResponse(
      { status: "ok", mode, translated, sessions: sessionsTranslated },
      200,
    );
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }
});
