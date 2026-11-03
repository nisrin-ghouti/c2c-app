-- Replaces the text of the ACTIVE sign-up policy, in place. English only.
--
-- This is the `policies` table (the "I agree" gate shown before entering the
-- app, labelled "version N"), NOT `legal_documents` — those are the separate
-- reference documents in Settings.
--
-- Editing in place is deliberate: bumping the version would re-prompt every
-- user who has already agreed. That is safe here because the previous body
-- was only the placeholder "תוכן המדיניות יעודכן בהמשך." ("the policy content
-- will be updated later"), so no one has meaningfully consented to anything.
--
-- Operator: Nesrin Gouti. Minimum age: 16.
--
-- Confirmed against production: one row, version 1, active = true. Columns:
-- id, title, body, version, active, created_by, created_at, updated_at.

-- STEP 1 — look before you write.
select id, version, active, title, length(body) as body_chars
from public.policies order by version desc;

-- STEP 2 — update the row you saw above. Targets version 1 explicitly rather
-- than "the newest", so it cannot silently hit a different row.
update public.policies
set
  title = 'Privacy Policy',
  body = $body$Privacy Policy
C2C — Connect to Collect · Last updated: __DATE__

This Privacy Policy explains how Nesrin Gouti ("we", "us", "our"), the operator of the C2C — Connect to Collect mobile application ("the App"), collects, uses, and protects your personal information. By creating an account and using the App, you agree to this Policy.

1. Who the App is for
C2C is a campus community app intended for university students. It is not directed at children under the age of 16. If you are below the minimum age in your country, please do not use the App.

2. Information we collect
We collect only the information needed to run the service:

• Account information — your email address and password (passwords are handled by our authentication provider and are never stored in readable form by us), and your name.
• Profile information you provide — faculty, field of study, degree, year, short bio, gender, interests, hobbies, languages, and an optional profile photo.
• Your Student ID — a unique identifier assigned within the App and shown to event hosts to confirm attendance.
• Content you create — chat messages with other students, meeting requests, event registrations, and reports you submit.
• Activity data — points earned, event attendance, meeting history, and leaderboard standings.
• Device information for notifications — a push-notification token that lets us send you alerts (new messages, events, benefits, approvals).
• Technical data — basic technical information needed for the App to function reliably and securely.

The camera is used only to scan QR codes in real time (for event check-in and student meetings). Camera images are not stored or transmitted.

3. How we use your information
• To create and manage your account and profile.
• To match you with other students and enable chat and meetings.
• To run campus events, programs, points, and benefit redemptions.
• To send you notifications about activity relevant to you.
• To keep the community safe, review reports, and prevent misuse.
• To operate, maintain, and improve the App.

4. What other users can see
Your profile (name, photo, faculty, field of study, interests, hobbies, languages, and compatibility information) is visible to other students to enable matching. Messages you send are visible to the student you send them to. Do not share information you do not wish others to see.

5. How your information is shared
We do not sell your personal information. We share it only with service providers that operate the App on our behalf, under contract, and only as needed to provide the service:

• Supabase — database, authentication, and file storage (backend hosting).
• Resend — sending account and verification emails.
• Google Firebase (Cloud Messaging) — delivering push notifications.

We may also disclose information if required by law or to protect the rights and safety of our users.

6. Data storage and security
Your data is stored on our providers' secure infrastructure and transmitted over encrypted (HTTPS) connections. We apply reasonable technical and organizational measures to protect it. No system is perfectly secure, and we cannot guarantee absolute security.

7. International transfers
Our providers may process and store data on servers located outside your country. Where required, we rely on appropriate safeguards for such transfers.

8. Data retention
We keep your information for as long as your account is active. When you delete your account, we delete or anonymize your personal information, except where we must retain it to comply with legal obligations.

9. Your rights
You can access and update most of your information directly in the App (Edit Profile). You may also request to access, correct, or delete your personal data, or withdraw consent, by contacting us at the address below. You can add, change, or remove your profile photo at any time, and delete your account.

10. Changes to this Policy
We may update this Policy from time to time. Material changes will be reflected by updating the "Last updated" date above and, where appropriate, notifying you in the App.

11. Contact us
For any privacy question or request, contact us at:
connecttocollect2026@gmail.com
$body$,
  updated_at = now()
where version = 1;

-- STEP 3 — stamp today's date into the header.
update public.policies
set body = replace(body, '__DATE__', to_char(now() at time zone 'Asia/Jerusalem', 'DD/MM/YYYY'))
where version = 1;

-- STEP 4 — confirm.
select id, version, active, title, length(body) as body_chars, updated_at
from public.policies where version = 1;
