-- Fills the Privacy Policy document, which has been empty since 0017 seeded it.
--
-- `legal_documents` has ONE title/body and no per-locale columns, so both
-- languages live in a single field: Hebrew first, English below. Every student
-- sees the same text regardless of their app language. Making it truly
-- per-locale needs a schema change plus viewer and admin-editor work.
--
-- Operator: Nesrin Gouti. Minimum age: 16 — keep this in step with the age
-- rating declared in App Store Connect, or the two contradict each other.
-- The "last updated" date is stamped from today, in campus time.

update public.legal_documents
set
  title = 'מדיניות פרטיות · Privacy Policy',
  body = $body$מדיניות פרטיות
C2C — Connect to Collect · עודכן לאחרונה: __DATE__

מדיניות פרטיות זו מסבירה כיצד נסרין גותי (Nesrin Gouti) ("אנחנו", "אנו", "שלנו"), מפעילת אפליקציית C2C — Connect to Collect ("האפליקציה"), אוספת מידע אישי אודותיך, משתמשת בו ומגנה עליו. ביצירת חשבון ובשימוש באפליקציה, הנך מסכים/ה למדיניות זו.

1. למי מיועדת האפליקציה
C2C היא אפליקציית קהילה קמפוסית המיועדת לסטודנטים באוניברסיטה. היא אינה מיועדת לילדים מתחת לגיל 16. אם גילך נמוך מהגיל המזערי במדינתך, אנא הימנע/י משימוש באפליקציה.

2. מידע שאנו אוספים
אנו אוספים אך ורק את המידע הדרוש להפעלת השירות:

• פרטי חשבון — כתובת הדואר האלקטרוני והסיסמה שלך (הסיסמאות מטופלות על ידי ספק האימות שלנו ואינן נשמרות אצלנו בצורה קריאה), וכן שמך.
• פרטי פרופיל שאת/ה מוסר/ת — פקולטה, תחום לימודים, תואר, שנת לימודים, תיאור קצר, מגדר, תחומי עניין, תחביבים, שפות ותמונת פרופיל (רשות).
• מספר הסטודנט/ית שלך — מזהה ייחודי המוקצה בתוך האפליקציה ומוצג למארגני אירועים לצורך אישור נוכחות.
• תוכן שאת/ה יוצר/ת — הודעות צ'אט עם סטודנטים אחרים, בקשות לפגישות, הרשמות לאירועים ודיווחים שהגשת.
• נתוני פעילות — נקודות שנצברו, נוכחות באירועים, היסטוריית פגישות ומיקום בטבלאות המצטיינים.
• מידע על המכשיר לצורך התראות — אסימון להתראות דחיפה המאפשר לנו לשלוח לך התראות (הודעות חדשות, אירועים, הטבות ואישורים).
• נתונים טכניים — מידע טכני בסיסי הדרוש לפעולה אמינה ומאובטחת של האפליקציה.

המצלמה משמשת אך ורק לסריקת קודי QR בזמן אמת (לצורך רישום נוכחות באירועים ולפגישות בין סטודנטים). תמונות מהמצלמה אינן נשמרות ואינן מועברות.

3. כיצד אנו משתמשים במידע שלך
• ליצירת חשבונך ופרופילך ולניהולם.
• להתאמה בינך לבין סטודנטים אחרים ולאפשור צ'אט ופגישות.
• להפעלת אירועי קמפוס, תוכניות, נקודות ומימוש הטבות.
• לשליחת התראות על פעילות הרלוונטית לך.
• לשמירה על בטיחות הקהילה, לבחינת דיווחים ולמניעת שימוש לרעה.
• להפעלה, לתחזוקה ולשיפור של האפליקציה.

4. מה משתמשים אחרים יכולים לראות
הפרופיל שלך (שם, תמונה, פקולטה, תחום לימודים, תחומי עניין, תחביבים, שפות ומידע על התאמה) גלוי לסטודנטים אחרים לצורך ההתאמה. הודעות שאת/ה שולח/ת גלויות לסטודנט/ית שאליו/ה נשלחו. אין לשתף מידע שאינך מעוניין/ת שאחרים יראו.

5. כיצד המידע שלך משותף
איננו מוכרים את המידע האישי שלך. אנו משתפים אותו אך ורק עם ספקי שירות המפעילים עבורנו את האפליקציה, במסגרת התקשרות חוזית, ורק במידה הנדרשת לאספקת השירות:

• Supabase — בסיס נתונים, אימות ואחסון קבצים (אירוח צד שרת).
• Resend — שליחת הודעות דואר אלקטרוני לחשבון ולאימות.
• Google Firebase (Cloud Messaging) — משלוח התראות דחיפה.

כמו כן, ייתכן שנחשוף מידע אם נידרש לכך על פי דין, או כדי להגן על זכויותיהם ועל בטיחותם של משתמשינו.

6. אחסון ואבטחת מידע
הנתונים שלך מאוחסנים בתשתית המאובטחת של ספקינו ומועברים בחיבורים מוצפנים (HTTPS). אנו נוקטים אמצעים טכניים וארגוניים סבירים להגנה עליהם. אין מערכת מאובטחת באופן מושלם, ואיננו יכולים להבטיח אבטחה מוחלטת.

7. העברות בין-לאומיות
ספקינו עשויים לעבד ולאחסן נתונים בשרתים הממוקמים מחוץ למדינתך. במקרים שבהם הדבר נדרש, אנו מסתמכים על אמצעי הגנה מתאימים להעברות מסוג זה.

8. שמירת מידע
אנו שומרים את המידע שלך כל עוד חשבונך פעיל. עם מחיקת חשבונך, אנו מוחקים את המידע האישי שלך או הופכים אותו לאנונימי, למעט במקרים שבהם עלינו לשמרו לצורך עמידה בחובות חוקיות.

9. הזכויות שלך
באפשרותך לעיין ברוב המידע שלך ולעדכנו ישירות באפליקציה (עריכת פרופיל). כמו כן, באפשרותך לבקש לעיין במידע האישי שלך, לתקנו או למוחקו, או לחזור בך מהסכמתך, בפנייה אלינו לכתובת שלהלן. באפשרותך להוסיף, לשנות או להסיר את תמונת הפרופיל שלך בכל עת, וכן למחוק את חשבונך.

10. שינויים במדיניות זו
אנו עשויים לעדכן מדיניות זו מעת לעת. שינויים מהותיים יבואו לידי ביטוי בעדכון תאריך "עודכן לאחרונה" שלמעלה, ובמקרים המתאימים גם בהודעה בתוך האפליקציה.

11. יצירת קשר
לכל שאלה או בקשה בנושא פרטיות, ניתן לפנות אלינו בכתובת:
connecttocollect2026@gmail.com

────────────────────────────────────────

Privacy Policy
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
where kind = 'privacy';

-- Stamp today's date into both headers.
update public.legal_documents
set body = replace(body, '__DATE__', to_char(now() at time zone 'Asia/Jerusalem', 'DD/MM/YYYY'))
where kind = 'privacy';

-- Confirm.
select kind, title, length(body) as body_chars, updated_at
from public.legal_documents where kind = 'privacy';
