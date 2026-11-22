// Supabase Edge Function: send-push
//
// Invoked by a Database Webhook on `public.notifications` INSERT. For each new
// notification it looks up the recipient's device tokens and sends an FCM push
// (Android + iOS) via the FCM HTTP v1 API. Because every notification type
// (chat, events, benefits, approvals, reports, meetings, reminders) lands in
// the same table, this one function delivers push for all of them.
//
// Copy is built PER DEVICE, in the language that device reported through
// `register_device_token` (`device_tokens.language`, migration 0075). Two
// devices of the same person set to two languages therefore get two different
// pushes from one notification row. A device that has not reported a language
// yet falls back to English, which is the app's own `SupportedLocales.fallback`.
//
// Dynamic content (an event, benefit, or survey title) is localized from
// `title_en`/`title_he`/`title_ar` on the notification (migration 0075).
// When the device's language is missing — a survey has no translation
// columns, or the event was approved before translate-content ran — the
// canonical title is translated once and cached (migration
// 20261122115441) and that result is what this device receives. A
// translation already on the payload is left as written. Chat message
// text is not translated: that is the sender's own words.
//
// Required secrets (set with `supabase secrets set`):
//   FIREBASE_SERVICE_ACCOUNT  – the full service-account JSON (one line)
// Provided automatically by the platform:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//
// Deploy: supabase functions deploy send-push --no-verify-jwt
// (the webhook authenticates with a shared header, not a user JWT)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface NotificationRow {
  id: string;
  user_id: string;
  type: string;
  data: Record<string, unknown> | null;
}

interface WebhookPayload {
  type: string;
  table: string;
  record: NotificationRow;
}

// ---- FCM OAuth (service account → access token) ---------------------------

let cachedToken: { token: string; exp: number } | null = null;

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

function base64url(input: string | Uint8Array): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp > now + 60) return cachedToken.token;

  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64url(new Uint8Array(sig))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`oauth: ${JSON.stringify(json)}`);
  cachedToken = { token: json.access_token, exp: now + 3500 };
  return json.access_token;
}

// ---- Notification copy, per language -------------------------------------
//
// Mirrors the app's own `AppLocalizations` strings for the same types (see
// `NotificationTile._body` and `lib/core/l10n/*.arb`) so a push and the
// notification-centre row a student taps through to read the same.

type Lang = "en" | "he" | "ar";

function asLang(value: unknown): Lang {
  return value === "he" || value === "ar" ? value : "en";
}

/// Frame copy: everything that isn't user-authored content.
const COPY: Record<Lang, Record<string, string>> = {
  en: {
    newMessageTitle: "New message",
    newMessageBody: "sent you a message",
    newEvent: "New event",
    newEventBody: "A new event was published",
    newBenefit: "New benefit",
    newBenefitBody: "A new benefit is available",
    eventNeedsApproval: "Event needs approval",
    eventNeedsApprovalBody: "An event is waiting for approval",
    eventApproved: "Event approved",
    eventRejected: "Event rejected",
    eventReviewedBody: "Your event was reviewed",
    newReport: "New report",
    newReportBody: "A user report was submitted",
    groupMeeting: "Group meeting",
    groupMeetingBody: "A group meeting is waiting for approval",
    benefitRedeemed: "Benefit redeemed",
    benefitRedeemedBody: "Congratulations! The benefit ({title}) has been successfully redeemed.",
    yourBenefit: "your benefit",
    meetingRequest: "Meeting request",
    meetingRequestBody: "You have a new meeting request",
    newSurvey: "New survey",
    newSurveyBody: "A new survey is available",
    pointsEarned: "Points earned",
    pointsEarnedBody: "You earned {amount} points",
    reminderTomorrowTitle: "Your event is tomorrow",
    reminderTomorrowBody: "Tomorrow: {title}",
    reminderTomorrowBodyGeneric: "You have an event tomorrow",
    reminderTodayTitle: "Your event is today",
    reminderTodayBody: "Today: {title}",
    reminderTodayBodyGeneric: "You have an event today",
    fallbackTitle: "C2C",
    fallbackBody: "You have a new notification",
  },
  he: {
    newMessageTitle: "הודעה חדשה",
    newMessageBody: "שלח לך הודעה",
    newEvent: "אירוע חדש",
    newEventBody: "פורסם אירוע חדש",
    newBenefit: "הטבה חדשה",
    newBenefitBody: "זמינה הטבה חדשה",
    eventNeedsApproval: "אירוע ממתין לאישור",
    eventNeedsApprovalBody: "יש אירוע שממתין לאישור",
    eventApproved: "האירוע אושר",
    eventRejected: "האירוע נדחה",
    eventReviewedBody: "האירוע שלך נבדק",
    newReport: "דיווח חדש",
    newReportBody: "הוגש דיווח על משתמש",
    groupMeeting: "מפגש קבוצתי",
    groupMeetingBody: "יש מפגש קבוצתי שממתין לאישור",
    benefitRedeemed: "ההטבה מומשה",
    benefitRedeemedBody: "מזל טוב! ההטבה ({title}) מומשה בהצלחה.",
    yourBenefit: "ההטבה שלך",
    meetingRequest: "בקשת פגישה",
    meetingRequestBody: "יש לך בקשת פגישה חדשה",
    newSurvey: "סקר חדש",
    newSurveyBody: "זמין סקר חדש",
    pointsEarned: "נצברו נקודות",
    pointsEarnedBody: "צברת {amount} נקודות",
    reminderTomorrowTitle: "האירוע שלכם מתקיים מחר",
    reminderTomorrowBody: "מחר: {title}",
    reminderTomorrowBodyGeneric: "יש לכם אירוע מחר",
    reminderTodayTitle: "האירוע שלכם מתקיים היום",
    reminderTodayBody: "היום: {title}",
    reminderTodayBodyGeneric: "יש לכם אירוע היום",
    fallbackTitle: "C2C",
    fallbackBody: "יש לך התראה חדשה",
  },
  ar: {
    newMessageTitle: "رسالة جديدة",
    newMessageBody: "أرسل لك رسالة",
    newEvent: "حدث جديد",
    newEventBody: "تم نشر حدث جديد",
    newBenefit: "ميزة جديدة",
    newBenefitBody: "تتوفر ميزة جديدة",
    eventNeedsApproval: "حدث بانتظار الموافقة",
    eventNeedsApprovalBody: "هناك حدث بانتظار الموافقة",
    eventApproved: "تم اعتماد الحدث",
    eventRejected: "تم رفض الحدث",
    eventReviewedBody: "تمت مراجعة حدثك",
    newReport: "تقرير جديد",
    newReportBody: "تم تقديم تقرير عن مستخدم",
    groupMeeting: "لقاء جماعي",
    groupMeetingBody: "هناك لقاء جماعي بانتظار الموافقة",
    benefitRedeemed: "تم استخدام الميزة",
    benefitRedeemedBody: "تهانينا! تم استخدام الميزة ({title}) بنجاح.",
    yourBenefit: "ميزتك",
    meetingRequest: "طلب موعد",
    meetingRequestBody: "لديك طلب موعد جديد",
    newSurvey: "استبيان جديد",
    newSurveyBody: "يتوفر استبيان جديد",
    pointsEarned: "تم ربح نقاط",
    pointsEarnedBody: "لقد ربحت {amount} نقطة",
    reminderTomorrowTitle: "حدثك غدًا",
    reminderTomorrowBody: "غدًا: {title}",
    reminderTomorrowBodyGeneric: "لديك حدث غدًا",
    reminderTodayTitle: "حدثك اليوم",
    reminderTodayBody: "اليوم: {title}",
    reminderTodayBodyGeneric: "لديك حدث اليوم",
    fallbackTitle: "C2C",
    fallbackBody: "لديك إشعار جديد",
  },
};

/// The `<field>` of `data` in `lang`, falling back through the canonical
/// field and then to an empty string.
///
/// `title_he` etc. are written by the notify triggers (0075). A row from
/// before that migration has only `title`, and a row whose translation was
/// never filled in has a null — both land on the canonical text rather than
/// on nothing, which is the same fallback rule the app's own
/// `localizedTitle(...)` uses.
function localizedField(
  data: Record<string, unknown>,
  field: string,
  lang: Lang,
): string {
  const candidates = [`${field}_${lang}`, field, `${field}_en`];
  for (const key of candidates) {
    const value = data[key];
    if (typeof value === "string" && value.trim() !== "") return value;
  }
  return "";
}

function messageFor(
  type: string,
  data: Record<string, unknown> | null,
  lang: Lang,
): { title: string; body: string } {
  const d = data ?? {};
  const t = COPY[lang];
  const s = (k: string) => (typeof d[k] === "string" ? (d[k] as string) : "");
  const n = (k: string) => (typeof d[k] === "number" ? (d[k] as number) : 0);
  const eventTitle = localizedField(d, "title", lang);

  switch (type) {
    case "new_message":
      // The sender's name and their message are not translatable content.
      return { title: s("sender_name") || t.newMessageTitle, body: s("preview") || t.newMessageBody };
    case "event_published":
      return { title: t.newEvent, body: eventTitle || t.newEventBody };
    case "benefit_published":
      return { title: t.newBenefit, body: eventTitle || t.newBenefitBody };
    case "event_pending_approval":
      return { title: t.eventNeedsApproval, body: eventTitle || t.eventNeedsApprovalBody };
    case "event_decision":
      return {
        title: d["status"] === "approved" ? t.eventApproved : t.eventRejected,
        body: eventTitle || t.eventReviewedBody,
      };
    case "report_submitted":
      return { title: t.newReport, body: t.newReportBody };
    case "group_meeting_pending":
      return { title: t.groupMeeting, body: t.groupMeetingBody };
    case "benefit_redeemed":
      return {
        title: t.benefitRedeemed,
        body: t.benefitRedeemedBody.replace("{title}", eventTitle || t.yourBenefit),
      };
    case "meeting_proposal":
      return { title: t.meetingRequest, body: t.meetingRequestBody };
    case "survey_published":
      return { title: t.newSurvey, body: eventTitle || t.newSurveyBody };
    case "points_earned":
      return { title: t.pointsEarned, body: t.pointsEarnedBody.replace("{amount}", String(n("amount"))) };
    case "event_reminder_tomorrow":
      return {
        title: t.reminderTomorrowTitle,
        body: eventTitle
          ? t.reminderTomorrowBody.replace("{title}", eventTitle)
          : t.reminderTomorrowBodyGeneric,
      };
    case "event_reminder_today":
      return {
        title: t.reminderTodayTitle,
        body: eventTitle
          ? t.reminderTodayBody.replace("{title}", eventTitle)
          : t.reminderTodayBodyGeneric,
      };
    default:
      return { title: t.fallbackTitle, body: t.fallbackBody };
  }
}

// Titles whose body is a piece of content (event, benefit, survey), as
// opposed to a chat message or a fixed sentence. These are the ones that
// follow the device language even when the stored translation is missing.
const LOCALIZED_TITLE_TYPES = new Set([
  "event_published",
  "benefit_published",
  "event_pending_approval",
  "event_decision",
  "benefit_redeemed",
  "survey_published",
  "event_reminder_tomorrow",
  "event_reminder_today",
]);

type TitleClient = ReturnType<typeof createClient>;

function decodeHtml(value: string): string {
  const named: Record<string, string> = {
    amp: "&",
    lt: "<",
    gt: ">",
    quot: '"',
    apos: "'",
  };
  return value
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
    .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCodePoint(parseInt(n, 16)))
    .replace(/&([a-z]+);/gi, (entity, name) => named[name.toLowerCase()] ?? entity);
}

async function translateTitle(text: string, target: Lang, apiKey: string): Promise<string> {
  const res = await fetch(
    `https://translation.googleapis.com/language/translate/v2?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ q: text, target, format: "text" }),
    },
  );
  if (!res.ok) throw new Error(`translate ${target} failed (${res.status})`);
  const json = await res.json();
  const value = json?.data?.translations?.[0]?.translatedText;
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`translate ${target} returned nothing`);
  }
  return decodeHtml(value).trim();
}

/// Fills empty `title_en` / `title_he` / `title_ar` on [data] from the
/// canonical `title`. Never overwrites a translation the payload already
/// has, and never throws — a failed translation leaves the old fallback
/// (the organizer's text) in place so the push still goes out.
async function ensureLocalizedTitles(
  supabase: TitleClient,
  data: Record<string, unknown>,
): Promise<void> {
  try {
    const canonical = typeof data.title === "string" ? data.title.trim() : "";
    if (!canonical) return;

    const langs: Lang[] = ["en", "he", "ar"];
    const missing = () =>
      langs.filter((lang) => {
        const value = data[`title_${lang}`];
        return typeof value !== "string" || value.trim() === "";
      });
    if (missing().length === 0) return;

    const apiKey = Deno.env.get("GOOGLE_TRANSLATE_API_KEY");
    if (!apiKey) return;

    const apply = (row: Partial<Record<Lang, string>>) => {
      for (const lang of missing()) {
        const value = row[lang];
        if (typeof value === "string" && value.trim() !== "") {
          data[`title_${lang}`] = value.trim();
        }
      }
    };

    const read = async (): Promise<Partial<Record<Lang, string>> | null> => {
      const { data: row, error } = await supabase.rpc("get_push_title_translation", {
        _source: canonical,
      });
      if (error || !row || typeof row !== "object") return null;
      const record = row as Record<string, unknown>;
      if (record.ready !== true) return null;
      return {
        en: typeof record.title_en === "string" ? record.title_en : "",
        he: typeof record.title_he === "string" ? record.title_he : "",
        ar: typeof record.title_ar === "string" ? record.title_ar : "",
      };
    };

    const cached = await read();
    if (cached) apply(cached);
    if (missing().length === 0) return;

    const { data: claim, error: claimError } = await supabase.rpc(
      "claim_push_title_translation",
      { _source: canonical },
    );
    if (claimError || claim === "skip") return;

    if (claim === "ready") {
      const row = await read();
      if (row) apply(row);
      return;
    }

    if (claim === "wait") {
      for (let attempt = 0; attempt < 8; attempt++) {
        await new Promise((resolve) => setTimeout(resolve, 400));
        const row = await read();
        if (!row) continue;
        apply(row);
        if (missing().length === 0) return;
      }
      return;
    }

    if (claim !== "translate") return;

    try {
      const [en, he, ar] = await Promise.all([
        translateTitle(canonical, "en", apiKey),
        translateTitle(canonical, "he", apiKey),
        translateTitle(canonical, "ar", apiKey),
      ]);
      const { error: saveError } = await supabase.rpc("save_push_title_translation", {
        _source: canonical,
        _title_en: en,
        _title_he: he,
        _title_ar: ar,
      });
      if (saveError) throw new Error(saveError.message);
      apply({ en, he, ar });
    } catch (error) {
      console.error("push title translation failed", error);
      await supabase.rpc("release_push_title_translation", { _source: canonical });
    }
  } catch (error) {
    console.error("push title translation skipped", error);
  }
}

// ---- Handler --------------------------------------------------------------

Deno.serve(async (req) => {
  try {
    const payload = (await req.json()) as WebhookPayload;
    const note = payload?.record;
    // INSERT only. Filling a missing title writes the translations back onto
    // this row so the in-app list matches the push; that UPDATE must not
    // send the push a second time.
    if (!note || payload.table !== "notifications" || (payload.type && payload.type !== "INSERT")) {
      return new Response("ignored", { status: 200 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: tokens } = await supabase
      .from("device_tokens")
      .select("token, platform, language")
      .eq("user_id", note.user_id);

    if (!tokens || tokens.length === 0) {
      return new Response("no tokens", { status: 200 });
    }

    const data = note.data ?? {};
    note.data = data;
    if (LOCALIZED_TITLE_TYPES.has(note.type)) {
      const titlesBefore = JSON.stringify([data.title_en, data.title_he, data.title_ar]);
      await ensureLocalizedTitles(supabase, data);
      if (titlesBefore !== JSON.stringify([data.title_en, data.title_he, data.title_ar])) {
        // The in-app row was stored before the translation existed. Keep it
        // in step with the push. Failure here still sends the push.
        const { error } = await supabase.from("notifications").update({ data }).eq("id", note.id);
        if (error) console.error("push title write-back failed", error.message);
      }
    }

    const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
    const accessToken = await getAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id as string;

    // Built once per language rather than once per device: a user with five
    // devices in the same language renders the copy once. Keyed by language so
    // each send below picks its own.
    const copyByLang: Record<Lang, { title: string; body: string }> = {
      en: messageFor(note.type, note.data, "en"),
      he: messageFor(note.type, note.data, "he"),
      ar: messageFor(note.type, note.data, "ar"),
    };

    // Stringify data values — FCM data payloads must be string→string.
    const dataStr: Record<string, string> = { type: note.type, notification_id: note.id };
    for (const [k, v] of Object.entries(note.data ?? {})) {
      dataStr[k] = typeof v === "string" ? v : JSON.stringify(v);
    }

    const stale: string[] = [];
    await Promise.all(
      tokens.map(async ({ token, platform, language }) => {
        const { title, body } = copyByLang[asLang(language)];

        // Android chat messages go out data-only: an OS-auto-displayed
        // notification can't carry a custom "Reply" action, so the client
        // builds the notification itself (see firebaseMessagingBackgroundHandler
        // in lib/core/push/push_service.dart) for this one case only. Every
        // other type/platform combo keeps the normal notification+data shape.
        const androidChatReply = note.type === "new_message" && platform === "android";

        const message: Record<string, unknown> = { token, data: dataStr };
        if (androidChatReply) {
          // Data-only, so nothing here is rendered by the OS — the client
          // builds the notification. Hand it the already-localized strings
          // (`notif_title`/`notif_body`) so that isolate, which has no
          // AppLocalizations of its own, doesn't have to fall back to English.
          message.data = { ...dataStr, notif_title: title, notif_body: body };
          message.android = { priority: "high" };
        } else {
          message.notification = { title, body };
          message.android = { priority: "high", notification: { channel_id: "c2c_default" } };
          message.apns = {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                // iOS keeps the OS-delivered alert but tags it with a category
                // so the same "Reply" action can attach without going data-only
                // (Apple won't wake a force-quit app for a silent/data push).
                ...(note.type === "new_message" ? { category: "NEW_MESSAGE_CATEGORY" } : {}),
              },
            },
          };
        }

        const res = await fetch(
          `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ message }),
          },
        );
        if (!res.ok) {
          const err = await res.text();
          // A token FCM no longer recognizes → drop it so we stop trying.
          if (res.status === 404 || err.includes("UNREGISTERED") || err.includes("InvalidArgument")) {
            stale.push(token);
          } else {
            console.error("fcm send failed", res.status, err);
          }
        }
      }),
    );

    if (stale.length > 0) {
      await supabase.from("device_tokens").delete().in("token", stale);
    }

    return new Response(JSON.stringify({ sent: tokens.length - stale.length, pruned: stale.length }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (e) {
    console.error("send-push error", e);
    return new Response(String(e), { status: 500 });
  }
});
