// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'C2C';

  @override
  String get languageSelectionTitle => 'בחרו שפה';

  @override
  String get languageSelectionSubtitle => 'תוכלו לשנות זאת מאוחר יותר בהגדרות.';

  @override
  String get languageContinue => 'המשך';

  @override
  String get welcomeTitle => 'ברוכים הבאים';

  @override
  String get welcomeSubtitle => 'הקמפוס שלך, מחובר.';

  @override
  String get tabSignup => 'הרשמה';

  @override
  String get tabLogin => 'התחברות';

  @override
  String get methodPassword => 'כניסה עם סיסמה';

  @override
  String get methodOtp => 'כניסה עם קוד למייל';

  @override
  String get fieldFirstName => 'שם פרטי';

  @override
  String get fieldLastName => 'שם משפחה';

  @override
  String get fieldEmail => 'אימייל';

  @override
  String emailHint(String domain) {
    return 'you@$domain';
  }

  @override
  String get fieldPassword => 'סיסמה';

  @override
  String get fieldPasswordSignupHint => 'סיסמה (לפחות 8 תווים)';

  @override
  String get fieldConfirmPassword => 'אימות סיסמה';

  @override
  String get buttonLogin => 'התחבר';

  @override
  String get buttonSendCode => 'שלח לי קוד אימות';

  @override
  String get buttonCreateAccount => 'צור חשבון';

  @override
  String get linkForgotPassword => 'שכחתי סיסמה';

  @override
  String domainNote(String domain) {
    return 'הרשמה מותרת עם מייל $domain בלבד.';
  }

  @override
  String errorDomainNotAllowed(String domain) {
    return 'מותר רק עם מייל $domain';
  }

  @override
  String get errorEnterEmail => 'יש להזין כתובת אימייל';

  @override
  String get errorEnterFirstName => 'יש להזין שם פרטי';

  @override
  String get errorEnterLastName => 'יש להזין שם משפחה';

  @override
  String get errorEnterPassword => 'יש להזין סיסמה';

  @override
  String get errorPasswordTooShort => 'הסיסמה חייבת להכיל לפחות 8 תווים';

  @override
  String get errorPasswordsDontMatch => 'הסיסמאות אינן תואמות';

  @override
  String get errorInvalidCredentials => 'מייל או סיסמה שגויים';

  @override
  String get errorEmailNotConfirmedSendingCode =>
      'יש לאמת את המייל לפני התחברות. שולחים קוד…';

  @override
  String get errorUserAlreadyExists => 'קיים כבר משתמש עם מייל זה — נסו להתחבר';

  @override
  String get errorUserNotFound => 'לא נמצא חשבון עם מייל זה — יש להירשם תחילה';

  @override
  String get errorGeneric => 'משהו השתבש. נסו שוב.';

  @override
  String get verifyTitle => 'אימות כתובת המייל';

  @override
  String get verifySubtitle =>
      'שלחנו קוד בן 6 ספרות לכתובת המייל שלך. הזינו אותו כאן כדי להמשיך.';

  @override
  String get otpHint => '000000';

  @override
  String get errorInvalidOtp => 'יש להזין קוד בן 6 ספרות';

  @override
  String get errorOtpIncorrect => 'הקוד שגוי או שפג תוקפו.';

  @override
  String get errorBlockedUser =>
      'החשבון נחסם על ידי הנהלת C2C עקב הפרת תנאי השימוש.';

  @override
  String get actionClose => 'סגור';

  @override
  String get buttonVerify => 'אימות והמשך';

  @override
  String get linkResend => 'לא קיבלתי קוד — שלחו שוב';

  @override
  String linkResendIn(int seconds) {
    return 'ניתן לשלוח שוב בעוד $seconds שניות';
  }

  @override
  String get infoResent => 'נשלח קוד חדש למייל שלך.';

  @override
  String get linkBackToLogin => 'חזרה להתחברות';

  @override
  String get forgotTitle => 'שחזור סיסמה';

  @override
  String get forgotSubtitle => 'נשלח קישור איפוס למייל שלך.';

  @override
  String get buttonSendResetLink => 'שלח קישור איפוס';

  @override
  String get infoResetLinkSent => 'שלחנו לך קישור לאיפוס סיסמה למייל.';

  @override
  String get errorEnterUniversityEmail => 'יש להזין כתובת אימייל תקינה';

  @override
  String get resetTitle => 'איפוס סיסמה';

  @override
  String get fieldNewPasswordHint => 'סיסמה חדשה (לפחות 8 תווים)';

  @override
  String get buttonUpdatePassword => 'עדכן סיסמה';

  @override
  String get infoPasswordUpdated => 'הסיסמה עודכנה. מעבירים אותך לאפליקציה…';

  @override
  String get resetLinkInactive =>
      'קישור איפוס לא פעיל. אנא בקשו קישור חדש דרך \"שכחתי סיסמה\".';

  @override
  String get completeProfileTitle => 'השלמת פרופיל';

  @override
  String get completeProfileSubtitle => 'עוד כמה פרטים לפני שמתחילים.';

  @override
  String get fieldFacultyOptional => 'פקולטה (לא חובה)';

  @override
  String get fieldYearOptional => 'שנה (לא חובה)';

  @override
  String get buttonContinue => 'המשך';

  @override
  String get errorSaveProfileFailed => 'לא ניתן לשמור את הפרופיל. נסו שוב.';

  @override
  String get policyTitle => 'מדיניות ותנאי שימוש';

  @override
  String policyVersionLabel(int version) {
    return 'גרסה $version';
  }

  @override
  String get policyNoneActive => 'אין מדיניות פעילה כרגע.';

  @override
  String get buttonAgree => 'אני מסכים/ה לתנאי השימוש';

  @override
  String get buttonAlreadyAgreed => 'כבר אישרת את המדיניות';

  @override
  String get buttonContinueToApp => 'המשך לאפליקציה';

  @override
  String get errorLoadPolicyFailed => 'לא ניתן לטעון את המדיניות.';

  @override
  String get errorAgreePolicyFailed => 'לא ניתן לשמור את ההסכמה. נסו שוב.';

  @override
  String get restrictedAccessTitle => 'הגישה מוגבלת';

  @override
  String get restrictedAccessMessage =>
      'האפליקציה מיועדת לסטודנטים בלבד. לחשבון שלכם אין הרשאת גישה של סטודנט.';

  @override
  String homeSignedInAs(String email) {
    return 'מחובר/ת בתור $email';
  }

  @override
  String get actionSignOut => 'התנתקות';

  @override
  String homeGreeting(String name) {
    return 'שלום, $name';
  }

  @override
  String get homeMyPoints => 'הנקודות שלי';

  @override
  String get homeHeroTitle => 'מה עושים היום בקמפוס?';

  @override
  String get homeMonthlyChampions => 'אלופי החודש';

  @override
  String get coachMarkNavHomeTitle => 'בית';

  @override
  String get coachMarkNavHomeDescription =>
      'לוח הבית שלך — אירועים, התראות ומה חדש.';

  @override
  String get coachMarkNavMatchesTitle => 'התאמות';

  @override
  String get coachMarkNavMatchesDescription => 'גלו והתחברו לסטודנטים אחרים.';

  @override
  String get coachMarkNavScanTitle => 'סריקה';

  @override
  String get coachMarkNavScanDescription =>
      'סרקו קוד QR לצ\'ק-אין או לצבירת נקודות.';

  @override
  String get coachMarkNavBenefitsTitle => 'הטבות';

  @override
  String get coachMarkNavBenefitsDescription =>
      'ממשו את הנקודות שלכם להטבות שותפים.';

  @override
  String get coachMarkNavProfileTitle => 'פרופיל';

  @override
  String get coachMarkNavProfileDescription =>
      'ערכו את הפרופיל שלכם ונהלו הגדרות.';

  @override
  String get coachMarkMyEventsTitle => 'האירועים שלי';

  @override
  String get coachMarkMyEventsDescription =>
      'צפו באירועים ובמפגשים שנרשמתם אליהם.';

  @override
  String get coachMarkUpcomingEventsTitle => 'אירועים קרובים';

  @override
  String get coachMarkUpcomingEventsDescription =>
      'עיינו באירועי הקמפוס הקרובים.';

  @override
  String get coachMarkNotificationsTitle => 'בחירה מרובה';

  @override
  String get coachMarkNotificationsDescription =>
      'לחיצה ארוכה על התראה מאפשרת לבחור כמה פריטים ולסמן אותם כנקראו, לא נקראו, או למחוק אותם יחד.';

  @override
  String get coachMarkChampionsTitle => 'אלופי החודש';

  @override
  String get coachMarkChampionsDescription =>
      'צפו במי שצברו הכי הרבה נקודות החודש.';

  @override
  String get homeMyNotifications => 'התרעות שלי';

  @override
  String get homeUpcomingEvents => 'כל האירועים';

  @override
  String get homeMyEventsCalendar => 'היומן אירועים שלי';

  @override
  String get homeNewStudents => 'סטודנטים חדשים';

  @override
  String get homeSeeAll => 'הכל';

  @override
  String get actionSeeMore => 'עוד';

  @override
  String get homeCampusEvents => 'אירועים בקמפוס';

  @override
  String get filterAll => 'הכל';

  @override
  String get filtersTitle => 'מסננים';

  @override
  String get filtersClearAll => 'ניקוי הכול';

  @override
  String get filtersApply => 'החלת סינון';

  @override
  String get comingSoon => 'בקרוב';

  @override
  String get eventUpcomingTag => 'קרוב';

  @override
  String get eventRegisteredLabel => 'נרשמת לאירוע';

  @override
  String get eventAttendedLabel => 'נכחת באירוע';

  @override
  String get eventRegisterAction => 'הרשמה לאירוע';

  @override
  String eventPointsLabel(int points) {
    return '‎+$points נק\'';
  }

  @override
  String get homeEmptyEvents => 'אין אירועים קרובים כרגע.';

  @override
  String get homeEmptySurveys => 'אין סקרים זמינים כרגע.';

  @override
  String get homeEmptyStudents => 'אין סטודנטים חדשים כרגע.';

  @override
  String get homeLoadError => 'לא ניתן לטעון את הדף הראשי. נסו שוב.';

  @override
  String get registerSuccess => 'נרשמת בהצלחה!';

  @override
  String get registerErrorAlready => 'כבר נרשמת לאירוע הזה';

  @override
  String get registerErrorFull => 'האירוע מלא';

  @override
  String get registerErrorEnded => 'האירוע כבר הסתיים';

  @override
  String get registerErrorNotPublished => 'האירוע אינו פתוח להרשמה';

  @override
  String get registerErrorNotFound => 'האירוע לא נמצא';

  @override
  String get registerErrorGeneric => 'ההרשמה נכשלה. נסו שוב.';

  @override
  String get deleteEventTitle => 'מחיקת אירוע';

  @override
  String get deleteEventMessage => 'האם אתה בטוח שברצונך למחוק את האירוע?';

  @override
  String get deleteEventConfirm => 'מחק';

  @override
  String get actionCancel => 'ביטול';

  @override
  String get deleteEventSuccess => 'האירוע נמחק.';

  @override
  String get deleteEventError => 'לא ניתן למחוק את האירוע. נסו שוב.';

  @override
  String get registrantsTitle => 'נרשמים לאירוע';

  @override
  String get registrantsEmpty => 'אין עדיין נרשמים.';

  @override
  String get registrantAttended => 'נכח';

  @override
  String get registrantRegisteredOnly => 'נרשם';

  @override
  String get navProfile => 'פרופיל';

  @override
  String get navBenefits => 'הטבות';

  @override
  String get navScanning => 'סריקה';

  @override
  String get navMatches => 'הכרויות';

  @override
  String get navHome => 'בית';

  @override
  String get matchesTitle => 'הכרויות';

  @override
  String get matchesEmpty => 'אין עדיין סטודנטים אחרים.';

  @override
  String get matchesLoadError => 'לא ניתן לטעון את ההכרויות. נסו שוב.';

  @override
  String get matchesConnectAction => 'התחברות באמצעות QR';

  @override
  String get profileAboutLabel => 'אודות';

  @override
  String get profileLanguagesLabel => 'שפות';

  @override
  String get profileMessageAction => 'שליחת הודעה';

  @override
  String get profileViewAction => 'צפייה בפרופיל';

  @override
  String get matchesSearchHint => 'חיפוש לפי שם, תחביב, שפה...';

  @override
  String get matchesFilterToggle => 'סינון';

  @override
  String get matchesSortToggle => 'מיון';

  @override
  String get matchesSortHighToLow => 'התאמה: מהגבוה לנמוך';

  @override
  String get matchesSortLowToHigh => 'התאמה: מהנמוך לגבוה';

  @override
  String matchesCompatibilityBadge(int percent) {
    return '$percent% התאמה';
  }

  @override
  String matchesResultsCount(int count) {
    return '$count התאמות סטודנטים';
  }

  @override
  String matchesYearInline(int year) {
    return 'שנה $year';
  }

  @override
  String get matchesSendHelloAction => 'שליחת שלום';

  @override
  String get filterFacultyLabel => 'פקולטה';

  @override
  String get filterFieldOfStudyLabel => 'תחום לימוד';

  @override
  String get filterDegreeLabel => 'תואר';

  @override
  String get filterYearLabel => 'שנת לימודים';

  @override
  String get filterLanguageLabel => 'שפה';

  @override
  String get filterGenderLabel => 'מגדר';

  @override
  String get scanningTitle => 'סריקה ונקודות';

  @override
  String get scanTabLabel => 'סרוק/הזן קוד';

  @override
  String get scanCardTitle => 'מספר הזהות הסטודנטיאלי שלך';

  @override
  String get scanCardSubtitle =>
      'הציגו זאת למארח האירוע אם לא ניתן לסרוק את קוד ה-QR.';

  @override
  String get scanEventQrAction => 'סריקת QR של אירוע';

  @override
  String get scanEventCameraTitle => 'סרוק באמצעות מצלמת המכשיר';

  @override
  String get scanEventGenericSubtitle =>
      'כוון את המצלמה אל קוד ה-QR — הוא יזוהה אוטומטית.';

  @override
  String get scanCameraPermissionHint =>
      'אם המצלמה לא נפתחת, אפשר גישה למצלמה בהגדרות המכשיר.';

  @override
  String get scanAnotherAction => 'סרוק שוב';

  @override
  String get scanEventQrPickerTitle => 'לאיזה אירוע?';

  @override
  String get scanEventQrEmpty =>
      'יש להירשם לאירוע קודם כדי לבצע צ\'ק-אין באמצעות קוד ה-QR שלו.';

  @override
  String get scanEnterCodeLabel => 'הזינו קוד באופן ידני';

  @override
  String get scanEnterCodeAction => 'אישור';

  @override
  String get scanEnterCodeError => 'יש להזין קוד';

  @override
  String get pointsHistoryTitle => 'היסטוריית נקודות';

  @override
  String get pointsHistoryEmpty => 'אין עדיין פעילות נקודות.';

  @override
  String get pointsHistoryLoadError => 'לא ניתן לטעון את היסטוריית הנקודות.';

  @override
  String get howToEarnTitle => 'איך צוברים נקודות';

  @override
  String get howToEarnEvent =>
      'השתתפות בפעילות (סריקת קוד האירוע בזמן הפעילות): +20 לכל אחד';

  @override
  String get howToEarnFirstMeeting =>
      'פגישה ראשונה עם סטודנט/ית חדש/ה: +25 לכל אחד';

  @override
  String get howToEarnSecondMeeting =>
      'פגישה שנייה עם אותו/ה סטודנט/ית: +20 לכל אחד';

  @override
  String get howToEarnRepeatMeeting =>
      'פגישה שלישית ואילך עם אותו/ה סטודנט/ית: +10 לכל אחד';

  @override
  String get reasonEventAttendance => 'השתתפות באירוע';

  @override
  String get reasonMeetingFirst => 'פגישה ראשונה';

  @override
  String get reasonMeetingSecond => 'פגישה שנייה';

  @override
  String get reasonMeetingRepeat => 'פגישה חוזרת';

  @override
  String get reasonGroupMeeting => 'מפגש קבוצתי';

  @override
  String get reasonMonthlyPrize => 'פרס חודשי';

  @override
  String get reasonBenefitRedeem => 'מימוש הטבה';

  @override
  String get reasonGeneric => 'נקודות';

  @override
  String get championsTabLabel => 'אלופי החודש';

  @override
  String get championsTitle => 'אלופי החודש';

  @override
  String get actionBack => 'חזרה';

  @override
  String get actionNext => 'הבא';

  @override
  String get actionSkip => 'דלג';

  @override
  String get actionGotIt => 'הבנתי';

  @override
  String get championsHeroLabel => 'דירוג החודש';

  @override
  String get championsHeroTitle => 'אלופי החודש';

  @override
  String get championsMyRankLabel => 'הדירוג שלי';

  @override
  String get championsMyPointsLabel => 'הנקודות שלי החודש';

  @override
  String championsGapLabel(int gap, String name) {
    return '‎$gap נק\' כדי לעקוף את $name';
  }

  @override
  String get championsUnranked => 'עדיין לא צברת נקודות החודש.';

  @override
  String get championsListTitle => 'נקודות החודש';

  @override
  String get championsHeroMonthPrefix => 'אלופי';

  @override
  String get championsUpdateFrequency => 'מתעדכן פעם בחודש';

  @override
  String get championsTableRankCol => 'דירוג';

  @override
  String get championsTableNameCol => 'שם';

  @override
  String get championsTablePointsCol => 'נקודות';

  @override
  String get championsEmpty => 'אין עדיין דירוג החודש.';

  @override
  String get championsLoadError => 'לא ניתן לטעון את הדירוג.';

  @override
  String get adminAccessDenied => 'אין לך גישה לעמוד זה.';

  @override
  String get eventsTitle => 'אירועים';

  @override
  String get eventTypeSingle => 'חד פעמי';

  @override
  String get eventTypeProgram => 'תוכנית';

  @override
  String get eventFiltersButton => 'סינון';

  @override
  String get eventFiltersTitle => 'סינון אירועים';

  @override
  String get eventFilterTypeLabel => 'סוג';

  @override
  String get eventFilterCategoryLabel => 'קטגוריה';

  @override
  String get eventFilterOrganizerLabel => 'מארגן';

  @override
  String get eventFiltersApply => 'החל סינון';

  @override
  String get eventFiltersReset => 'איפוס';

  @override
  String get eventDescriptionLabel => 'על האירוע';

  @override
  String get eventCancelAction => 'ביטול הרשמה';

  @override
  String get eventEndedLabel => 'האירוע הסתיים';

  @override
  String get cancelEventRegistrationTitle => 'לבטל את ההרשמה?';

  @override
  String get cancelEventRegistrationMessage =>
      'תוכל/י להירשם שוב מאוחר יותר אם תשני את דעתך.';

  @override
  String get cancelEventRegistrationConfirm => 'ביטול הרשמה';

  @override
  String get cancelEventRegistrationSuccess => 'ההרשמה בוטלה.';

  @override
  String get cancelEventRegistrationError => 'לא ניתן היה לבטל את ההרשמה.';

  @override
  String get myEventsTitle => 'האירועים שלי';

  @override
  String get myEventsFilterUpcoming => 'קרובים';

  @override
  String get myEventsFilterAttended => 'השתתפתי';

  @override
  String get myEventsFilterMissed => 'פספסתי';

  @override
  String get myEventsAttendedMessage => 'כל הכבוד! אנחנו גאים שהצטרפת!';

  @override
  String get myEventsMissedMessage => 'התגעגענו! חבל שלא הצלחת להצטרף.';

  @override
  String get myEventsUpcomingMessage => 'מצפים לראות אותך!';

  @override
  String get myEventsEmpty => 'עדיין לא נרשמת לאף אירוע.';

  @override
  String get myEventsLoadError => 'לא ניתן לטעון את האירועים שלך.';

  @override
  String get eventEditAction => 'עריכה';

  @override
  String get eventFormCreateTitle => 'יצירת אירוע';

  @override
  String get eventFormEditTitle => 'עריכת אירוע';

  @override
  String get eventFormTitleLabel => 'כותרת';

  @override
  String get eventFormDescriptionLabel => 'תיאור';

  @override
  String get eventFormCategoryLabel => 'קטגוריה';

  @override
  String get eventFormLocationLabel => 'מיקום';

  @override
  String get eventFormStartLabel => 'התחלה';

  @override
  String get eventFormEndLabel => 'סיום';

  @override
  String get eventFormPointsLabel => 'נקודות';

  @override
  String get eventFormCapacityLabel => 'תפוסה (אופציונלי)';

  @override
  String get eventFormImageUrlLabel => 'קישור לתמונה (אופציונלי)';

  @override
  String get eventFormOrganizerLabel => 'שם המארגן (אופציונלי)';

  @override
  String get eventFormVisibilityLabel => 'מי יכול לראות את האירוע?';

  @override
  String get eventVisibilityOnlyMe => 'רק אני';

  @override
  String get eventVisibilityEveryone => 'כולם';

  @override
  String get eventVisibilitySpecificFaculties => 'פקולטות ספציפיות';

  @override
  String get eventVisibilitySpecificGroups => 'קבוצות ספציפיות';

  @override
  String get eventFormFacultiesLabel => 'בחירת פקולטות';

  @override
  String get eventFormGroupTagsLabel => 'תגיות קבוצה (מופרדות בפסיקים)';

  @override
  String get eventFormErrorTitleRequired => 'הזן/י כותרת';

  @override
  String get eventFormErrorDatesRequired => 'בחר/י שעת התחלה וסיום';

  @override
  String get eventFormErrorEndBeforeStart =>
      'שעת הסיום חייבת להיות אחרי שעת ההתחלה';

  @override
  String get eventFormErrorGeneric =>
      'לא ניתן היה לשמור את האירוע. בדוק/בדקי את הפרטים ונסה/י שוב.';

  @override
  String get eventFormSubmitCreate => 'שליחה לאישור';

  @override
  String get eventFormSubmitUpdate => 'שמירת שינויים';

  @override
  String get eventShowQrAction => 'הצגת קוד QR';

  @override
  String get eventQrScanningLabel => 'סריקה';

  @override
  String eventQrRefreshesIn(int seconds) {
    return 'מתרענן בעוד $seconds שנ\'';
  }

  @override
  String get eventQrLoadError => 'לא ניתן היה ליצור קוד QR.';

  @override
  String get eventQrHint =>
      'הציגו קוד QR זה לסטודנטים במהלך האירוע. הוא מתרענן כל 10 שניות.';

  @override
  String get eventScanningClosedMessage => 'הסריקה סגורה.';

  @override
  String get eventScanTitle => 'סריקה לצורך רישום נוכחות';

  @override
  String get eventScanGenericHeading =>
      'סרוק את קוד ה-QR של כל אירוע כדי לבצע צ\'ק-אין';

  @override
  String get eventScanToCheckInAction => 'סריקה לרישום נוכחות';

  @override
  String eventScanSuccess(int points) {
    return 'צברת $points נקודות!';
  }

  @override
  String get eventScanErrorExpired => 'סרקת לאחר תום הזמן המוקצב.';

  @override
  String get eventScanErrorAlreadyScanned =>
      'כבר סרקת אירוע זה. לא ניתן לסרוק שוב.';

  @override
  String get eventScanErrorNotRegistered =>
      'עליך להירשם לאירוע זה לפני הסריקה.';

  @override
  String get eventScanErrorInvalid => 'קוד QR לא תקין.';

  @override
  String get eventStatsRegistered => 'נרשמו';

  @override
  String get eventStatsAttended => 'השתתפו';

  @override
  String get eventStatsMissed => 'פספסו';

  @override
  String programPointsEquation(int points, int count, int total) {
    return '$points נקודות × $count מפגשים = $total נקודות אפשריות';
  }

  @override
  String get programSessionsTitle => 'מפגשים';

  @override
  String get programSessionsEmpty => 'עדיין אין מפגשים.';

  @override
  String get programSessionsLoadError => 'לא ניתן היה לטעון את המפגשים.';

  @override
  String get programManageSessionsAction => 'ניהול מפגשים';

  @override
  String get programViewSessionsAction => 'צפייה במפגשים';

  @override
  String programAttendanceProgress(int attended, int total) {
    return 'נכחת ב-$attended מתוך $total מפגשים';
  }

  @override
  String get programAttendedAllSessions => 'נכחת בכל המפגשים!';

  @override
  String get programSessionsFormTitle => 'מפגשים';

  @override
  String get programSessionLabel => 'מפגש';

  @override
  String get programAddSessionAction => 'הוספת מפגש נוסף';

  @override
  String get eventFormErrorSessionsRequired => 'הוסף/הוסיפי לפחות מפגש אחד';

  @override
  String get eventFormErrorSessionIncomplete =>
      'מלא/י כותרת ושני זמנים לכל מפגש';

  @override
  String get chatsTitle => 'צ\'אטים';

  @override
  String get chatsEmpty => 'עדיין אין שיחות.';

  @override
  String get chatsSearchHint => 'חיפוש בשיחות';

  @override
  String get chatsSearchEmpty => 'לא נמצאו שיחות התואמות לחיפוש.';

  @override
  String get chatsLoadError => 'לא ניתן היה לטעון את הצ\'אטים שלך.';

  @override
  String get chatMessageHint => 'כתוב/כתבי הודעה…';

  @override
  String get chatBlockAction => 'חסימה';

  @override
  String get chatUnblockAction => 'ביטול חסימה';

  @override
  String get chatBlockedBanner =>
      'חסמת את המשתמש/ת הזו. בטל/י חסימה כדי לשלוח הודעות.';

  @override
  String get chatBlockedByOtherBanner => 'לא ניתן לשלוח הודעות בשיחה זו.';

  @override
  String get chatBlockConfirmTitle => 'לחסום את המשתמש/ת?';

  @override
  String get chatBlockConfirmMessage =>
      'הם לא יוכלו לשלוח לך הודעות עד שתבטל/י את החסימה.';

  @override
  String get chatEmptyThread => 'תגיד/י שלום 👋';

  @override
  String get chatDateToday => 'היום';

  @override
  String get chatDateYesterday => 'אתמול';

  @override
  String get proposeMeetingTitle => 'הצעת פגישה';

  @override
  String get proposeMeetingPickDateTime => 'בחירת תאריך ושעה';

  @override
  String get proposeMeetingPickEndDateTime => 'בחירת שעת סיום';

  @override
  String get proposeMeetingNotesLabel => 'הערות (אופציונלי)';

  @override
  String get proposeMeetingSubmit => 'שליחת הצעה';

  @override
  String get proposeMeetingErrorDateRequired => 'בחר/י תאריך ושעה';

  @override
  String get proposeMeetingErrorEndBeforeStart =>
      'שעת הסיום חייבת להיות אחרי שעת ההתחלה';

  @override
  String get proposeMeetingError => 'לא ניתן היה לשלוח את ההצעה';

  @override
  String get proposeMeetingErrorSameStudentToday =>
      'כבר קבועה לכם פגישה עם הסטודנט/ית הזה/ו באותו יום. אפשר להיפגש עם אותו/ה סטודנט/ית פעם אחת ביום.';

  @override
  String get proposeMeetingErrorDailyLimitSelf =>
      'כבר קבועות לכם פגישות עם 5 סטודנטים/ות שונים/ות באותו יום, וזו המגבלה היומית. נסו תאריך אחר.';

  @override
  String get proposeMeetingErrorDailyLimitOther =>
      'לסטודנט/ית הזה/ו כבר קבועות פגישות עם 5 סטודנטים/ות שונים/ות באותו יום. נסו תאריך אחר.';

  @override
  String get proposeMeetingCardTitle => 'הצעת פגישה';

  @override
  String get proposeMeetingAccept => 'קבלה';

  @override
  String get proposeMeetingDecline => 'דחייה';

  @override
  String get proposeMeetingWaiting => 'ממתין/ה לתגובה…';

  @override
  String get proposeMeetingAccepted => 'התקבלה';

  @override
  String get proposeMeetingDeclined => 'נדחתה';

  @override
  String get reportUserAction => 'דיווח';

  @override
  String reportUserTitle(String name) {
    return 'דיווח על $name';
  }

  @override
  String get reportUserReasonLabel => 'סיבה';

  @override
  String get reportUserDetailsLabel => 'פרטים';

  @override
  String get reportUserErrorReasonRequired => 'יש להזין סיבה';

  @override
  String get reportUserErrorDetailsRequired => 'יש להזין פרטים';

  @override
  String get reportUserImagesLabel => 'צילומי מסך (אופציונלי)';

  @override
  String get reportUserAddImage => 'הוספה';

  @override
  String get reportUserSubmit => 'שליחת דיווח';

  @override
  String get reportUserSuccess => 'הדיווח נשלח.';

  @override
  String get reportUserError => 'לא ניתן היה לשלוח את הדיווח.';

  @override
  String get groupMeetingListEntryPoint => 'מפגשים קבוצתיים';

  @override
  String get groupMeetingListTitle => 'המפגשים הקבוצתיים שלי';

  @override
  String get groupMeetingCreateAction => 'מפגש קבוצתי חדש';

  @override
  String get groupMeetingListLoadError =>
      'לא ניתן היה לטעון את המפגשים הקבוצתיים שלך.';

  @override
  String get groupMeetingListEmpty => 'אין לך עדיין מפגשים קבוצתיים.';

  @override
  String get groupMeetingStatusApproved => 'אושר';

  @override
  String get groupMeetingStatusRejected => 'נדחה';

  @override
  String get groupMeetingStatusPending => 'ממתין לאישור';

  @override
  String get groupMeetingRoleOrganizer => 'את/ה מארגן/ת את המפגש הזה';

  @override
  String groupMeetingRoleParticipant(String name) {
    return 'מאורגן על ידי $name';
  }

  @override
  String get groupMeetingFinishedTag => 'הסתיים';

  @override
  String get groupMeetingShowQrAction => 'הצג קוד QR';

  @override
  String get groupMeetingScanAction => 'סרוק';

  @override
  String get groupMeetingEnterCodeTitle => 'הזנת קוד';

  @override
  String get groupMeetingEnterCodeHint => 'הדביקו את הקוד שקיבלתם מהמארגן';

  @override
  String get groupMeetingEnterCodeAction => 'הזנת קוד';

  @override
  String get groupMeetingCreateTitle => 'מפגש קבוצתי חדש';

  @override
  String get groupMeetingCreateHint =>
      'הבקשה שלך תישלח לאישור מנהל לפני שייווצר קישור הרשמה.';

  @override
  String get groupMeetingLocationLabel => 'מיקום';

  @override
  String get groupMeetingLocationHint =>
      'מפגשים קבוצתיים חייבים להתקיים בקמפוס האוניברסיטה.';

  @override
  String get groupMeetingLocationRequired => 'יש לבחור מיקום בקמפוס.';

  @override
  String groupMeetingMaxParticipantsLabel(int count) {
    return 'מספר משתתפים מרבי: $count';
  }

  @override
  String get groupMeetingCreateSubmit => 'שליחת בקשה';

  @override
  String get groupMeetingCreateSuccess => 'בקשת המפגש הקבוצתי שלך נשלחה.';

  @override
  String get groupMeetingCreateError => 'לא ניתן היה לשלוח את הבקשה.';

  @override
  String get groupMeetingRegistrationTitle => 'מפגש קבוצתי';

  @override
  String get groupMeetingRegistrationInvalid =>
      'הקישור אינו תקין או שפג תוקפו.';

  @override
  String groupMeetingRegisteredCount(int count, int max) {
    return '$count מתוך $max נרשמו';
  }

  @override
  String get groupMeetingRegisterAction => 'הרשמה';

  @override
  String get groupMeetingRegisterSuccess => 'נרשמת בהצלחה!';

  @override
  String get groupMeetingAlreadyRegistered => 'כבר נרשמת למפגש הזה.';

  @override
  String get groupMeetingRegisterErrorFull => 'המפגש הזה מלא.';

  @override
  String get groupMeetingRegisterErrorAlready => 'כבר נרשמת.';

  @override
  String get groupMeetingRegisterErrorOwn => 'את/ה מארגן/ת את המפגש הזה.';

  @override
  String get groupMeetingRegisterErrorGeneric =>
      'לא ניתן היה להירשם למפגש הזה.';

  @override
  String get groupMeetingQrHint =>
      'הציגו את קוד ה-QR הזה למשתתפים. הוא מתעדכן כל 10 שניות.';

  @override
  String get groupMeetingFinishAction => 'סיום המפגש';

  @override
  String get groupMeetingFinishError => 'לא ניתן היה לסיים את המפגש.';

  @override
  String get groupMeetingFinishDialogTitle => 'המפגש הסתיים';

  @override
  String get groupMeetingFinishDialogOk => 'אישור';

  @override
  String get groupMeetingFinishOutcomeNone =>
      'אף אחד לא סרק, ולכן לא הוענקו נקודות.';

  @override
  String groupMeetingFinishOutcomeOneToOne(int points) {
    return 'רק אדם אחד סרק, ולכן זה נחשב כמפגש אישי — שניכם קיבלתם $points נקודות.';
  }

  @override
  String get groupMeetingFinishOutcomeCapped =>
      'רק אדם אחד סרק, ולכן זה נחשב כמפגש אישי — אך המכסה היומית לזוג הזה כבר מוצתה, ולא הוענקו נקודות.';

  @override
  String groupMeetingFinishOutcomeGroup(int organizerPoints, int scanners) {
    return 'קיבלת $organizerPoints נקודות, ו-$scanners משתתפים קיבלו נקודות כל אחד.';
  }

  @override
  String get groupMeetingScanTitle => 'סריקה להצטרפות';

  @override
  String get groupMeetingScanSuccess => 'הצטרפת למפגש!';

  @override
  String get groupMeetingScanErrorOwnCode =>
      'אי אפשר לסרוק את קוד ה-QR של עצמך.';

  @override
  String get benefitsCatalogTabLabel => 'קטלוג';

  @override
  String get benefitsWalletTabLabel => 'הארנק שלי';

  @override
  String benefitsPointsBalance(int points) {
    return 'יש לך $points נקודות';
  }

  @override
  String get benefitsCatalogLoadError => 'לא ניתן היה לטעון את קטלוג ההטבות.';

  @override
  String get benefitsCatalogEmpty => 'אין הטבות זמינות כרגע.';

  @override
  String get benefitsWalletLoadError => 'לא ניתן היה לטעון את הארנק שלך.';

  @override
  String get benefitsWalletEmpty => 'עדיין לא מימשת אף הטבה.';

  @override
  String get benefitsWalletTitle => 'הארנק הדיגיטלי שלי';

  @override
  String get benefitsWalletSubtitle => 'כל הכרטיסים הדיגיטליים שלך במקום אחד';

  @override
  String get benefitsWalletPointsLabel => 'יתרת נקודות';

  @override
  String get benefitsWalletFilterAll => 'הכל';

  @override
  String get benefitsWalletFilterNotUsed => 'לא מומש';

  @override
  String get benefitsWalletFilterUsed => 'מומש';

  @override
  String get benefitsWalletFilterButton => 'סנן';

  @override
  String get benefitsWalletFilterByBusiness => 'סינון לפי עסק';

  @override
  String get benefitsWalletFilterClear => 'ניקוי סינון';

  @override
  String get benefitsStatusLabel => 'הסטטוס שלי';

  @override
  String get benefitsCatalogHeading => 'המרת נקודות להטבות';

  @override
  String get benefitsOpenWalletAction => 'הארנק הדיגיטלי שלי';

  @override
  String get benefitsCategoryAll => 'הכל';

  @override
  String benefitPointCost(int points) {
    return '$points נקודות';
  }

  @override
  String get benefitRedeemAction => 'מימוש';

  @override
  String get benefitNotEnoughPoints => 'אין מספיק נקודות';

  @override
  String get benefitAlreadyActiveLabel => 'בארנק שלך';

  @override
  String get benefitAlreadyActiveMessage =>
      'יש לך כרטיס דיגיטלי בארנק עבור ההטבה הזו.';

  @override
  String get benefitRedeemConfirmTitle => 'מימוש הטבה';

  @override
  String benefitRedeemConfirmMessage(String title, int points) {
    return 'לממש את \"$title\" תמורת $points נקודות?';
  }

  @override
  String get benefitRedeemErrorInsufficientPoints =>
      'אין לך מספיק נקודות עבור ההטבה הזו.';

  @override
  String get benefitRedeemErrorUnavailable => 'ההטבה הזו כבר אינה זמינה.';

  @override
  String get benefitRedeemErrorAlreadyActive =>
      'כבר יש לך כרטיס דיגיטלי בארנק עבור ההטבה הזו.';

  @override
  String get benefitRedeemErrorNotAStudent =>
      'לחשבון זה אין אפשרות לממש הטבות — רק חשבונות סטודנטים יכולים.';

  @override
  String get benefitRedeemErrorGeneric => 'לא ניתן היה לממש את ההטבה.';

  @override
  String get benefitCardRedeemedTag => 'מומש';

  @override
  String get benefitCardAvailableTag => 'פעיל';

  @override
  String get benefitCardStatusLabel => 'סטטוס';

  @override
  String get benefitCardOpenAction => 'כרטיס דיגיטלי';

  @override
  String get benefitCardShowHint => 'הציגו את קוד ה-QR הזה לשותף לצורך המימוש.';

  @override
  String get benefitCardCodeLabel => 'או מסרו קוד זה אם לא ניתן לסרוק את ה-QR';

  @override
  String benefitCardAcquiredOn(String date) {
    return 'מומש בנקודות בתאריך $date';
  }

  @override
  String benefitCardRedeemedOn(String date) {
    return 'נוצל אצל השותף בתאריך $date';
  }

  @override
  String get supportContactsRowLabel => 'תמיכה טכנית';

  @override
  String get supportContactsTitle => 'תמיכה טכנית';

  @override
  String get supportContactsError => 'טעינת אנשי הקשר לתמיכה נכשלה.';

  @override
  String get supportContactsEmpty => 'עדיין לא הוגדרו אנשי קשר לתמיכה.';

  @override
  String get supportContactsCopy => 'העתקת מספר הטלפון';

  @override
  String get supportContactsCopied => 'מספר הטלפון הועתק';

  @override
  String get benefitFormCreateTitle => 'הטבה חדשה';

  @override
  String get benefitFormEditTitle => 'עריכת הטבה';

  @override
  String get benefitFormPartnerLabel => 'שם העסק השותף';

  @override
  String get benefitFormImageUrlLabel => 'כתובת תמונה (URL)';

  @override
  String get benefitFormPointCostLabel => 'עלות בנקודות';

  @override
  String get benefitFormErrorPointCostInvalid =>
      'יש להזין עלות נקודות גדולה מ-0';

  @override
  String get benefitFormCreateAction => 'יצירת הטבה';

  @override
  String get benefitFormSaveAction => 'שמירה';

  @override
  String get benefitProfileAboutBenefit => 'על ההטבה';

  @override
  String get benefitProfileAboutBusiness => 'על העסק';

  @override
  String get benefitProfileHowToRedeem => 'איך לממש';

  @override
  String get benefitProfileLinkLabel => 'קישור';

  @override
  String get benefitProfileOpenLink => 'פתיחת קישור';

  @override
  String get benefitProfileLocationLabel => 'מיקום';

  @override
  String get benefitProfileOpenMaps => 'פתיחה במפות';

  @override
  String get benefitProfileCategoryLabel => 'קטגוריה';

  @override
  String get benefitProfileCostLabel => 'עלות בנקודות';

  @override
  String get benefitFormSectionBasics => 'פרטים בסיסיים';

  @override
  String get benefitFormSectionBusiness => 'פרטי העסק';

  @override
  String get benefitFormSectionRedemption => 'פרטי המימוש';

  @override
  String get benefitFormSectionLocation => 'מיקום';

  @override
  String get benefitFormBusinessDescriptionLabel => 'תיאור העסק';

  @override
  String get benefitFormHowToRedeemLabel => 'איך לממש';

  @override
  String get benefitFormExternalLinkLabel => 'קישור חיצוני (אינסטגרם, אתר…)';

  @override
  String get benefitFormLocationLabel => 'מיקום';

  @override
  String get benefitFormMapsLinkLabel => 'קישור לגוגל מפות';

  @override
  String get benefitFormImageLabel => 'תמונת ההטבה';

  @override
  String get benefitFormEditAction => 'עריכה';

  @override
  String get benefitDigitalCardSection => 'כרטיס דיגיטלי';

  @override
  String get benefitDigitalCardPreviewAction => 'תצוגה מקדימה של הכרטיס';

  @override
  String get benefitDigitalCardPreviewTitle => 'תצוגה מקדימה של הכרטיס';

  @override
  String get benefitDigitalCardPreviewNote =>
      'כך בדיוק ייראה הכרטיס בארנק של הסטודנט.';

  @override
  String get benefitCardSampleStudent => 'שם הסטודנט';

  @override
  String get benefitCardStudentLabel => 'בעל הכרטיס';

  @override
  String notificationEventPending(String title) {
    return '\"$title\" ממתין לאישורך';
  }

  @override
  String get notificationEventPendingGeneric => 'אירוע ממתין לאישורך';

  @override
  String get eventProfileOrganizerLabel => 'מארגן';

  @override
  String get eventProfilePointsLabel => 'נקודות שיוענקו';

  @override
  String get eventProfileDescriptionLabel => 'תיאור האירוע';

  @override
  String get eventProfileLocationLabel => 'מיקום';

  @override
  String get eventProfileScheduleLabel => 'תאריך ושעה';

  @override
  String get eventProfileOrganizerDescriptionLabel => 'על המארגן';

  @override
  String get eventProfileExternalLinkLabel => 'קישור חיצוני';

  @override
  String get eventProfileCategoryLabel => 'קטגוריה';

  @override
  String get eventProfileSessionsLabel => 'מפגשי התוכנית';

  @override
  String get eventProfileSessionColumn => 'מפגש';

  @override
  String get eventProfileWhenColumn => 'מתי';

  @override
  String get eventProfileWhereColumn => 'היכן';

  @override
  String get eventProfileStatusColumn => 'סטטוס';

  @override
  String get eventProfileSessionMissed => 'פספסת';

  @override
  String get eventProfileSessionUpcoming => 'קרוב';

  @override
  String eventProfileTotalPoints(int points) {
    return '$points נקודות על השלמת התוכנית';
  }

  @override
  String eventProfileSessionCount(int count) {
    return '$count מפגשים';
  }

  @override
  String eventProfilePerSessionPoints(int points) {
    return '$points נקודות לכל מפגש';
  }

  @override
  String get eventProfileReviewTitle => 'סקירת אירוע';

  @override
  String get eventFormImageLabel => 'תמונת האירוע';

  @override
  String notificationEventPublished(String title) {
    return 'אירוע חדש: $title';
  }

  @override
  String get notificationEventPublishedGeneric => 'פורסם אירוע חדש';

  @override
  String notificationBenefitPublished(String title) {
    return 'הטבה חדשה: $title';
  }

  @override
  String get notificationBenefitPublishedGeneric => 'זמינה הטבה חדשה';

  @override
  String get notificationReportSubmitted => 'התקבל דיווח חדש';

  @override
  String notificationEventApproved(String title) {
    return '\"$title\" אושר';
  }

  @override
  String get notificationEventApprovedGeneric => 'האירוע שלך אושר';

  @override
  String notificationEventRejected(String title) {
    return '\"$title\" נדחה';
  }

  @override
  String notificationEventRejectedWithReason(String title, String reason) {
    return '\"$title\" נדחה: $reason';
  }

  @override
  String get notificationEventRejectedGeneric => 'האירוע שלך נדחה';

  @override
  String get notificationGroupMeetingPending => 'מפגש קבוצתי ממתין לאישור';

  @override
  String notificationBenefitRedeemed(String title) {
    return 'כל הכבוד! ההטבה ($title) מומשה בהצלחה.';
  }

  @override
  String get notificationBenefitRedeemedGeneric =>
      'כל הכבוד! ההטבה שלך מומשה בהצלחה.';

  @override
  String notificationSurveyPublished(String title) {
    return 'סקר חדש: $title';
  }

  @override
  String get notificationSurveyPublishedGeneric => 'סקר חדש זמין';

  @override
  String get scanStudentIdLabel => 'מספר סטודנט (הציגו אותו למארגן האירוע)';

  @override
  String get scanStudentIdCopied => 'מספר הסטודנט הועתק';

  @override
  String get attendanceManualTitle => 'אישור לפי מספר סטודנט';

  @override
  String get attendanceManualHint => 'הזינו את מספר הסטודנט';

  @override
  String get attendanceManualAction => 'אישור נוכחות';

  @override
  String get attendanceManualLookupError => 'לא נמצא סטודנט עם מספר זה';

  @override
  String get attendanceManualConfirmTitle => 'אישור נוכחות';

  @override
  String attendanceManualConfirmMessage(String name) {
    return 'לסמן את $name כנוכח/ת?';
  }

  @override
  String attendanceManualSuccess(String name) {
    return '$name סומן/ה כנוכח/ת';
  }

  @override
  String get optionNoTranslations => 'אין תרגומים — יוצג באנגלית';

  @override
  String get optionEditTranslations => 'עריכת תרגומים';

  @override
  String get optionLabelArabic => 'תווית בערבית';

  @override
  String get optionLabelHebrew => 'תווית בעברית';

  @override
  String get actionSave => 'שמירה';

  @override
  String get championsRewardsTitle => 'פרסים חודשיים';

  @override
  String championsRewardFirst(int points) {
    return '🥇 מקום ראשון: $points נק\'';
  }

  @override
  String championsRewardSecond(int points) {
    return '🥈 מקום שני: $points נק\'';
  }

  @override
  String championsRewardThird(int points) {
    return '🥉 מקום שלישי: $points נק\'';
  }

  @override
  String get legalPrivacyTitle => 'מדיניות פרטיות';

  @override
  String get legalTermsTitle => 'תנאים והגבלות';

  @override
  String get legalEditAction => 'עריכה';

  @override
  String get legalTitleLabel => 'כותרת';

  @override
  String get legalBodyLabel => 'תוכן';

  @override
  String get legalLoadError => 'לא ניתן לטעון מסמך זה.';

  @override
  String get legalSaveError => 'השמירה נכשלה. נסו שוב.';

  @override
  String get legalEditDenied => 'רק מנהל העל יכול לערוך זאת.';

  @override
  String get legalEmpty => 'מסמך זה עדיין לא נכתב.';

  @override
  String get profilePhotoRemove => 'הסרת התמונה';

  @override
  String get meetingInProgressTitle => 'פגישה מתקיימת';

  @override
  String get meetingWithLabel => 'עם';

  @override
  String get meetingYourQrTitle => 'קוד ה-QR שלך';

  @override
  String get meetingScanOtherTitle => 'סרקו את קוד ה-QR של הסטודנט השני';

  @override
  String get meetingQrRotatingHint => 'הקוד מתרענן כל 10 שניות';

  @override
  String get meetingSectionDone => 'בוצע';

  @override
  String get meetingBothActionsHint =>
      'השלימו את שתי הפעולות כדי לאשר את הפגישה ולזכות בנקודות.';

  @override
  String get meetingScanOwnCode => 'זה הקוד שלך';

  @override
  String get meetingScanExpired => 'הקוד פג — בקשו להציג אותו שוב';

  @override
  String get meetingScanError => 'הסריקה נכשלה. נסו שוב.';

  @override
  String meetingCompletedPoints(int points) {
    return 'הפגישה אושרה! זכית ב-$points נקודות.';
  }

  @override
  String get meetingCompletedNoPoints =>
      'הפגישה אושרה! (אין נקודות — כבר נפגשתם היום.)';

  @override
  String get meetingOpenAction => 'פתיחת הפגישה';

  @override
  String get meetingNotYetOpen => 'מוכנים להתחבר? בדקו שוב בזמן שנקבע.';

  @override
  String get meetingWindowEnded => 'חלון הזמן של הפגישה הזו הסתיים';

  @override
  String get myEventsMeetingsTitle => 'פגישות';

  @override
  String get meetingCardCompleted => 'הושלמה';

  @override
  String get meetingAttendedMessage => 'מעולה! אנחנו שמחים שנפגשתם.';

  @override
  String get meetingMissedMessage =>
      'פספסת את חלון הזמן של הפגישה הזו. אין בעיה — אפשר לתאם פגישה נוספת בכל עת.';

  @override
  String meetingCardWith(String name) {
    return 'פגישה עם $name';
  }

  @override
  String get passwordShow => 'הצג סיסמה';

  @override
  String get passwordHide => 'הסתר סיסמה';

  @override
  String get benefitFormSubmitError => 'לא ניתן היה לשמור את ההטבה.';

  @override
  String monthAnnouncementTitle(String month) {
    return 'אלופי $month';
  }

  @override
  String get monthAnnouncementBody =>
      'תוצאות החודש שעבר פורסמו! הנה השלושה המובילים:';

  @override
  String get monthAnnouncementOk => 'אישור';

  @override
  String winnerBonusTitle(int rank) {
    return 'סיימת במקום ה-$rank!';
  }

  @override
  String winnerBonusPoints(int points) {
    return 'סיימת את החודש שעבר עם $points נקודות.';
  }

  @override
  String winnerBonusAmount(int bonus) {
    return 'בונוס של $bonus+ נקודות';
  }

  @override
  String get winnerBonusOk => 'מעולה!';

  @override
  String get accessibilityPanelTitle => 'נגישות';

  @override
  String get accessibilityFloatingToggle => 'כפתור נגישות צף';

  @override
  String get accessibilityFloatingRemovedHint =>
      'כפתור הנגישות הוסתר. ניתן להפעילו שוב בהגדרות.';

  @override
  String get actionRemove => 'הסר';

  @override
  String get accessibilityTextSizeLabel => 'גודל טקסט';

  @override
  String get accessibilityTextSizeNormal => 'רגיל';

  @override
  String get accessibilityTextSizeLarge => 'גדול';

  @override
  String get accessibilityTextSizeExtraLarge => 'גדול מאוד';

  @override
  String get accessibilityReduceMotionLabel => 'הפחתת אנימציות';

  @override
  String get accessibilityHighContrastLabel => 'ניגודיות גבוהה';

  @override
  String get tutorialWelcomeTitle => 'ברוכים הבאים ל-C2C – Connect to Collect';

  @override
  String get tutorialWelcomeBody =>
      'התחברו עם סטודנטים, גלו את כל אירועי הקמפוס, צברו נקודות ותיהנו מהטבות בלעדיות.';

  @override
  String get tutorialMatchesTitle => 'מצאו את האנשים שלכם';

  @override
  String get tutorialMatchesBody =>
      'עיינו בסטודנטים שחולקים איתכם פקולטה, תחומי עניין ותחביבים, ושלחו הודעה כדי לתאם מפגש.';

  @override
  String get tutorialScanTitle => 'סרקו כדי להרוויח';

  @override
  String get tutorialScanBody =>
      'הציגו או סרקו קוד QR במפגשים ובאירועים כדי להרוויח נקודות אוטומטית.';

  @override
  String get tutorialBenefitsTitle => 'ממשו את הנקודות שלכם';

  @override
  String get tutorialBenefitsBody =>
      'מממשים נקודות תמורת הטבות אמיתיות משותפי הקמפוס בלשונית ההטבות.';

  @override
  String get tutorialChampionsTitle => 'טפסו בטבלת המובילים';

  @override
  String get tutorialChampionsBody =>
      'שלושת הסטודנטים המובילים בכל חודש זוכים בבונוס — בדקו את אלופי החודש כדי לראות איפה אתם עומדים.';

  @override
  String get tutorialBackAction => 'הקודם';

  @override
  String get tutorialNextAction => 'הבא';

  @override
  String get tutorialGetStartedAction => 'בואו נתחיל';

  @override
  String get demoEventCheckInTitle => 'איך צוברים נקודות באירועים';

  @override
  String get demoEventCheckInMessage =>
      'הרשמה לאירוע לא מזכה בנקודות באופן אוטומטי. כשתגיעו, סרקו את קוד ה-QR של האירוע — או בקשו מהמארח להזין את מספר הסטודנט שלכם — כדי לקבל את הנקודות.';

  @override
  String get demoMeetingStep1Title => 'קוד ה-QR שלכם';

  @override
  String get demoMeetingStep1Message =>
      'הראו אותו לסטודנט השני — הוא מתחדש כל 10 שניות מטעמי אבטחה.';

  @override
  String get demoMeetingStep2Title => 'סרקו את קוד ה-QR של הסטודנט השני';

  @override
  String get demoMeetingStep2Message =>
      'סרקו גם את הקוד שלהם. הנקודות ניתנות רק לאחר ששניכם סרקתם אחד את השני.';

  @override
  String get demoGroupMeetingTitle => 'על מפגשים קבוצתיים';

  @override
  String get demoGroupMeetingMessage =>
      'אם אתם חבורה של 3 אנשים ומעלה ורוצים להיפגש, תוכלו ליצור מפגש קבוצתי כאן. המארגן מקבל 25 נקודות כאשר לפחות שני משתתפים אחרים סורקים אותו, וכל משתתף שסורק מקבל 15 נקודות.';

  @override
  String get demoBenefitsCatalogTitle => 'לפני שתממשו';

  @override
  String get demoBenefitsCatalogMessage =>
      'מימוש הטבה מנכה מהנקודות שלכם מיד, וניתן להחזיק כרטיס פעיל אחד בלבד לכל הטבה בו-זמנית.';

  @override
  String get demoDigitalCardTitle => 'מימוש הכרטיס';

  @override
  String get demoDigitalCardMessage =>
      'זהו הברקוד למימוש ההטבה. בהגעה לבית העסק, הציגו אותו למוכר כדי לקבל את ההטבה. שימו לב: סריקת הברקוד ולחיצה על \"מימוש\" גורמות למימוש ההטבה באופן מיידי, ללא קשר לזהות הסורק. לכן, אין לסרוק את הברקוד בעצמכם. יש להציגו לצורך סריקה רק למוכר או לנציג בית העסק שבו ממומשת ההטבה.';

  @override
  String get demoMatchingTitle => 'אחוז ההתאמה';

  @override
  String get demoMatchingMessage =>
      'האחוז הזה מראה עד כמה תחומי העניין, הפקולטה והשפות שלכם תואמים. ככל שהאחוז גבוה יותר, יש לכם יותר במשותף.';

  @override
  String get demoGuidedMatchTabTitle => 'הקישו כאן';

  @override
  String get demoGuidedMatchTabMessage =>
      'הקישו על לשונית ההתאמות כדי לראות סטודנטים שאתם עשויים להתחבר איתם.';

  @override
  String get demoGuidedViewProfileTitle => 'הקישו כאן';

  @override
  String get demoGuidedViewProfileMessage =>
      'הקישו על צפייה בפרופיל כדי לראות את הפרופיל המלא של הסטודנט.';

  @override
  String get demoProgramTitle => 'נקודות בתוכנית';

  @override
  String get demoProgramMessage =>
      'נקודות ניתנות לכל מפגש בנפרד — כל מפגש דורש צ\'ק-אין משלו כדי להיספר.';

  @override
  String get demoAccessibilityTitle => 'קיצור נגישות';

  @override
  String get demoAccessibilityMessage =>
      'אפשר לגרור את הכפתור הזה לכל מקום על המסך. גררו אותו לאזור התחתון כדי להסתיר אותו. ניתן להפעיל אותו שוב מההגדרות.';

  @override
  String get demoChampionsTitle => 'אלופי החודש';

  @override
  String get demoChampionsMessage =>
      'לוח המובילים הזה עוקב אחרי נקודות שנצברו החודש בלבד, ומתאפס בתחילת כל חודש. כרטיס הדירוג שלכם מראה בדיוק איפה אתם עומדים.';

  @override
  String get demoReportUserTitle => 'דיווח על משתמש';

  @override
  String get demoReportUserMessage =>
      'חשוב שתכירו את האפשרות הזו: אם משתמש מתנהג בצורה לא הולמת, גורם לכם להרגיש לא בנוח או שיש בעיה שחשוב שהצוות שלנו יכיר – תוכלו לדווח עליו כאן. הדיווח יישלח לצוות המערכת לצורך בדיקה וטיפול.';

  @override
  String get settingsHelpSectionTitle => 'עזרה ומדריכים';

  @override
  String get settingsReplayIntroAction => 'הצגת מבוא האפליקציה מחדש';

  @override
  String get settingsReplayTutorialsAction => 'הצגת המדריכים מחדש';

  @override
  String get settingsReplayTutorialsToast =>
      'המדריכים אופסו — הם יופיעו שוב תוך כדי השימוש באפליקציה.';

  @override
  String get profileLoadError => 'לא ניתן היה לטעון את הפרופיל שלך.';

  @override
  String get profileAboutTitle => 'עליי';

  @override
  String get profileAboutEmpty => 'עדיין לא הוספת ביוגרפיה.';

  @override
  String get profileInterestsLabel => 'תחומי עניין';

  @override
  String get profileInterestsEmpty => 'עדיין לא הוספת תחומי עניין';

  @override
  String get profileLanguagesTitle => 'שפות';

  @override
  String get profileLanguagesEmpty => 'עדיין לא הוספת שפות';

  @override
  String get profileStudiesTitle => 'לימודים';

  @override
  String get profileFacultyLabel => 'פקולטה';

  @override
  String get profileFieldOfStudyLabel => 'תחום לימוד';

  @override
  String get searchableFieldMultipleHint => 'ניתן לבחור כמה אפשרויות';

  @override
  String get searchableFieldPlaceholder => 'הקישו לבחירה';

  @override
  String get searchableFieldSearchHint => 'חיפוש';

  @override
  String get searchableFieldNoMatches => 'אין תוצאות';

  @override
  String get searchableFieldDone => 'סיום';

  @override
  String get profileGenderLabel => 'מגדר';

  @override
  String get genderMale => 'זכר';

  @override
  String get genderFemale => 'נקבה';

  @override
  String get genderUndisclosed => 'מעדיף/ה לא לציין';

  @override
  String get profilePhotoLabel => 'תמונת פרופיל';

  @override
  String get profilePhotoChange => 'שינוי תמונה';

  @override
  String get profilePhotoAdd => 'הוספת תמונה';

  @override
  String get profilePhotoUploadError => 'לא ניתן להעלות את התמונה. נסו שוב.';

  @override
  String get profileBioHint => 'ספרו לסטודנטים אחרים קצת על עצמכם';

  @override
  String get profileOptionsLoadError => 'לא ניתן לטעון אפשרויות.';

  @override
  String get profileOptionsEmpty => 'אין עדיין אפשרויות זמינות.';

  @override
  String get actionRetry => 'נסה שוב';

  @override
  String get errorSelectFieldOfStudy => 'יש לבחור לפחות תחום לימוד אחד';

  @override
  String get profileDegreeLabel => 'תואר לימוד';

  @override
  String get profileYearLabel => 'שנת לימודים';

  @override
  String profileYearShort(int year) {
    return 'שנה $year';
  }

  @override
  String get profileEditAction => 'ערוך פרופיל';

  @override
  String get profileSettingsTitle => 'הגדרות';

  @override
  String get profileLanguageLabel => 'שפה';

  @override
  String get profilePolicyLabel => 'מדיניות ותנאי שימוש';

  @override
  String get profileLogoutAction => 'התנתק';

  @override
  String get profileDeleteAccountAction => 'מחיקת חשבון';

  @override
  String get profileDeleteAccountConfirmTitle => 'למחוק את החשבון שלך?';

  @override
  String get profileDeleteAccountConfirmMessage =>
      'לאחר בקשת מחיקת החשבון, חשבונך יושבת למשך 30 יום. בתום התקופה, החשבון יימחק לצמיתות. אם תתחבר/י מחדש לאפליקציה במהלך 30 הימים, בקשת המחיקה תבוטל והחשבון שלך יישאר פעיל.';

  @override
  String get profileDeleteAccountConfirmAction => 'בקשת מחיקה';

  @override
  String get profileDeleteAccountInProgress => 'שולח בקשת מחיקה…';

  @override
  String get profileDeleteAccountError =>
      'לא הצלחנו לשלוח את בקשת המחיקה. נסו שוב או פנו לתמיכה.';

  @override
  String get profileLogoutConfirmTitle => 'להתנתק מהחשבון שלך?';

  @override
  String profileAppVersion(String version) {
    return 'C2C גרסת אפליקציה $version';
  }

  @override
  String get profileEditTitle => 'עריכת פרופיל';

  @override
  String get profileEditError => 'לא ניתן היה לשמור את הפרופיל שלך.';

  @override
  String get profileSaveAction => 'שמירת שינויים';

  @override
  String get notificationsTitle => 'התראות';

  @override
  String get notificationsLoadError => 'לא ניתן היה לטעון את ההתראות שלך.';

  @override
  String get notificationsEmpty => 'אין לך עדיין התראות.';

  @override
  String notificationsSelectedCount(Object count) {
    return '$count נבחרו';
  }

  @override
  String get notificationsSelectAll => 'בחר הכל';

  @override
  String get notificationsMarkRead => 'סמן כנקרא';

  @override
  String get notificationsMarkUnread => 'סמן כלא נקרא';

  @override
  String get notificationsDeleteAction => 'מחיקה';

  @override
  String get notificationsClearAll => 'נקה הכל';

  @override
  String get notificationsDeleteConfirmTitle => 'למחוק את ההתראות?';

  @override
  String notificationsDeleteConfirmMessage(Object count) {
    return 'פעולה זו תמחק לצמיתות $count התראות. לא ניתן לבטל פעולה זו.';
  }

  @override
  String get notificationsClearAllConfirmTitle => 'לנקות את כל ההתראות?';

  @override
  String get notificationsClearAllConfirmMessage =>
      'פעולה זו תמחק לצמיתות את כל ההתראות שלך. לא ניתן לבטל פעולה זו.';

  @override
  String get notificationTargetLoadError =>
      'לא ניתן היה לפתוח את זה — ייתכן שזה כבר לא זמין.';

  @override
  String notificationPointsEarned(int points) {
    return 'קיבלת $points נקודות';
  }

  @override
  String notificationPointsEarnedWithTitle(int points, String title) {
    return 'קיבלת $points נקודות – $title';
  }

  @override
  String notificationNewMessage(String name) {
    return 'הודעה חדשה מאת $name';
  }

  @override
  String notificationMeetingProposal(String time) {
    return 'הצעה חדשה: מפגש ב-$time';
  }

  @override
  String get notificationMeetingProposalGeneric => 'הצעת מפגש חדשה';

  @override
  String get notificationGeneric => 'התראה חדשה';

  @override
  String get surveysTitle => 'סקרים';

  @override
  String get homeSurveysSection => 'סקרים זמינים';

  @override
  String get homeSurveysBannerCta => 'מלא סקר קצר וקבל נקודות!';

  @override
  String get surveysTabActive => 'סקרים פעילים';

  @override
  String get surveysTabCompleted => 'סקרים שהושלמו';

  @override
  String get surveysFilterPending => 'ממתינים';

  @override
  String get surveysFilterCompleted => 'הושלמו';

  @override
  String get surveysFilterIncoming => 'בקרוב';

  @override
  String get surveysEmptyPending => 'אין כרגע סקרים שממתינים לך.';

  @override
  String get surveysEmptyCompleted => 'עדיין לא השלמת אף סקר.';

  @override
  String get surveysEmptyIncoming => 'אין סקרים עתידיים מתוכננים.';

  @override
  String get surveysLoadError => 'לא ניתן היה לטעון את הסקרים.';

  @override
  String get surveysEndsToday => 'מסתיים היום';

  @override
  String surveysEndsInDays(int days) {
    return 'מסתיים בעוד $days ימים';
  }

  @override
  String get surveyStartAction => 'התחילו סקר';

  @override
  String surveyPointsLabel(int points) {
    return '$points נק\'';
  }

  @override
  String get surveySubmitAction => 'שליחה';

  @override
  String surveySubmitSuccess(int points) {
    return 'צברת $points נקודות!';
  }

  @override
  String get surveySubmitErrorGeneric =>
      'לא ניתן היה לשלוח את התשובות. נסה שוב.';

  @override
  String get surveySubmitErrorAlreadyAnswered => 'כבר השלמת את הסקר הזה.';

  @override
  String get surveySubmitErrorClosed => 'הסקר הזה סגור.';

  @override
  String get surveySubmitErrorNotYetOpen => 'הסקר הזה עדיין לא פתוח.';

  @override
  String get surveyDetailLoadError => 'לא ניתן היה לטעון את הסקר.';

  @override
  String get surveyTextAnswerHint => 'הקלד/י את תשובתך';

  @override
  String get surveyTextAnswerRequired =>
      'Please answer every question before submitting.';

  @override
  String get tourIntroTitle => 'מצוין, התחברתם בהצלחה!';

  @override
  String get tourIntroDescription =>
      'עכשיו נערוך היכרות קצרה עם האפליקציה ונכיר את הכפתורים והאפשרויות המרכזיות שבה.';

  @override
  String get tourNextAction => 'הבא';

  @override
  String get tourMyEventsTitle => 'האירועים שלי';

  @override
  String get tourMyEventsDescription =>
      'כאן תוכלו לראות את האירועים שנרשמתם אליהם, ואת הפגישות שקבעתם עם סטודנטים אחרים ולעקוב אחר ההשתתפות שלכם.';

  @override
  String get tourPointsTitle => 'הנקודות שלי';

  @override
  String get tourPointsDescription =>
      'זהו מספר הנקודות שצברתם עד עכשיו. תוכלו לצבור נקודות באמצעות השתתפות באירועים, פגישות עם סטודנטים אחרים ופעילויות נוספות באפליקציה, ולהשתמש בהן למימוש הטבות.';

  @override
  String get tourChampionsTitle => 'אלופי החודש';

  @override
  String get tourChampionsDescription =>
      'צברו נקודות, עלו בדירוג והגיעו לפסגה! כאן תוכלו לעקוב אחר המיקום שלכם ולראות מי מוביל בדירוג החודשי. בסוף כל חודש, שלושת הסטודנטים שצברו הכי הרבה נקודות זוכים בנקודות בונוס.';

  @override
  String get tourSurveysTitle => 'סקרים';

  @override
  String get tourSurveysDescription =>
      'שתפו אותנו במה שאתם חושבים וגם צברו נקודות! כאן יופיעו סקרים קצרים שתוכלו לענות עליהם בקלות, ועל כל סקר שתשלימו תקבלו נקודות.';

  @override
  String get tourAccessibilityTitle => 'כפתור נגישות';

  @override
  String get tourAccessibilityDescription =>
      'כאן תוכלו לפתוח את אפשרויות הנגישות ולהתאים את תצוגת האפליקציה לצרכים שלכם. ניתן להזיז את כפתור הנגישות לכל מקום שנוח לכם על המסך, ולהסיר או להחזיר אותו בכל עת דרך הגדרות האפליקציה.';

  @override
  String get tourMatchesNavTitle => 'היכרויות';

  @override
  String get tourMatchesNavDescription =>
      'הכירו את הסטודנטים שסביבכם בקמפוס, גלו מה משותף ביניכם וקבעו להיפגש בקמפוס! נפגשתם? סרקו אחד את השני במהלך הפגישה וצברו נקודות יחד. לחצו כאן כדי להמשיך.';

  @override
  String get tourScanNavTitle => 'סריקה';

  @override
  String get tourBenefitsNavTitle => 'הטבות';

  @override
  String get tourTapToContinue => 'לחצו על הכפתור המסומן כדי להמשיך.';

  @override
  String get tourCompatibilityTitle => 'אחוז התאמה';

  @override
  String get tourCompatibilityDescription =>
      'ליד כל סטודנט מופיע אחוז התאמה שמחושב לפי הדברים המשותפים ביניכם, כמו תחומי לימוד, תחומי עניין ושפות. ככל שהאחוז גבוה יותר, כך יש ביניכם יותר מאפיינים משותפים.';

  @override
  String get tourChatTitle => 'שיחה / Chat';

  @override
  String get tourChatDescription =>
      'כאן תוכלו לשוחח ולהכיר סטודנטים אחרים. דרך כפתור ה־(+) בשיחה תוכלו לקבוע פגישה ביניכם, שתישמר ב׳אירועים שלי׳. בזמן הפגישה תיפתח אפשרות לסרוק אחד את השני כדי לאשר שנפגשתם, ולאחר האישור תקבלו את הנקודות על הפגישה.';

  @override
  String get tourStudentProfileTitle => 'Profile';

  @override
  String get tourStudentProfileDescription =>
      'כאן תוכלו להכיר את הסטודנט קצת יותר ולראות את הפרטים שהוא בחר לשתף בפרופיל שלו, כמו תחום הלימודים, שפות, תחומי עניין ומידע נוסף עליו.';

  @override
  String get tourReportTitle => 'דיווח על משתמש';

  @override
  String get tourReportDescription =>
      'חשוב שתכירו את האפשרות הזו: אם משתמש מתנהג בצורה לא הולמת, גורם לכם להרגיש לא בנוח או שיש בעיה שחשוב שהצוות שלנו יכיר – תוכלו לדווח עליו כאן. הדיווח יישלח לצוות המערכת לצורך בדיקה וטיפול.';

  @override
  String get tourScanCameraTitle => 'סריקת QR באירוע';

  @override
  String get tourScanCameraDescription =>
      'הגעתם לאירוע? סרקו כאן את קוד ה־QR כדי לאשר את השתתפותכם ולקבל נקודות. מצלמה זו משמשת לסריקת אירועים בלבד. לפגישות עם סטודנטים יש סריקה נפרדת, שתיפתח אוטומטית בתוך הפגישה בזמן שנקבע לה. את הפגישות שקבעתם תוכלו למצוא ב׳האירועים שלי׳.';

  @override
  String get tourStudentIdTitle => 'מספר הסטודנט';

  @override
  String get tourStudentIdDescription =>
      'זהו מספר הזיהוי האישי שלכם באפליקציה. אם פספסתם את סריקת ה־QR באירוע או שהייתה בעיה בסריקה, תוכלו למסור את המספר למארח האירוע כדי שיוסיף אתכם ידנית.';

  @override
  String get tourBenefitsPageTitle => 'דף ההטבות';

  @override
  String get tourBenefitsPageDescription =>
      'הגיע הזמן ליהנות מהנקודות שצברתם! כאן תוכלו לראות את ההטבות הזמינות, לקרוא את פרטי ההטבה, לבדוק כמה נקודות נדרשות למימושה ולבחור את ההטבה שתרצו לממש.';

  @override
  String get tourWalletTitle => 'הארנק שלי';

  @override
  String get tourTapWalletDescription => 'לחצו על כפתור הארנק כדי להמשיך.';

  @override
  String get tourWalletDescription =>
      'כל הטבה שמימשתם מחכה לכם כאן! בארנק תוכלו למצוא את ההטבות שבחרתם לממש ולגשת לכרטיס הדיגיטלי של כל אחת מהן. בעת ההגעה לבית העסק, הציגו את הכרטיס הדיגיטלי ותיהנו מההטבה שלכם.';

  @override
  String get tourProfileTitle => 'הפרופיל';

  @override
  String get tourProfileDescription =>
      'זהו הפרופיל האישי שלכם ב-C2C. כאן תוכלו לראות ולעדכן את הפרטים שתרצו שסטודנטים אחרים ידעו עליכם. כמו כן, ניתן להתאים את שפת האפליקציה, כפתור הנגישות, ולצפות בסקרים פתוחים למענה ובתנאי השימוש בהגדרות המופיעות מטה.';

  @override
  String get tourReplayAction => 'הצג שוב את ההדרכה';

  @override
  String get surveyAnswerRequired => 'יש לענות על כל השאלות לפני השליחה.';

  @override
  String get tourProfileButtonTitle => 'פרופיל';

  @override
  String get tourProfileButtonDescription =>
      'כאן תוכלו להכיר את הסטודנט קצת יותר ולראות את הפרטים שהוא בחר לשתף בפרופיל שלו, כמו תחום הלימודים, שפות, תחומי עניין ומידע נוסף עליו.';

  @override
  String get demoChatBlockTitle => 'חסימת משתמש';

  @override
  String get demoChatBlockMessage =>
      'מכאן ניתן לחסום את המשתמש. לאחר החסימה, המשתמש לא יוכל לשלוח לכם הודעות וגם אתם לא תוכלו לשלוח לו הודעות. ניתן לחסום ולהסיר את החסימה בכל עת באמצעות לחיצה על הכפתור.';

  @override
  String get demoChatMeetingTitle => 'קביעת פגישה';

  @override
  String get demoChatMeetingMessage =>
      'מכאן תוכלו לקבוע פגישה עם הסטודנט/ית שאיתו/ה אתם משוחחים. קבעו פגישה, היפגשו בתוך האוניברסיטה וצברו נקודות יחד! פגישה ראשונה עם סטודנט/ית חדש/ה מזכה כל אחד מכם ב־25 נקודות, פגישה שנייה עם אותו/ה סטודנט/ית ב־20 נקודות, ופגישה שלישית ב־10 נקודות. שימו לב: ניתן לקבוע פגישה אחת ביום עם אותו/ה סטודנט/ית, ועד 5 פגישות עם סטודנטים/ות שונים/ות באותו יום.';

  @override
  String get tourBenefitsStatusTitle => 'הסטטוס שלי';

  @override
  String get tourBenefitsStatusDescription =>
      'כאן תוכלו לראות כמה נקודות יש לכם, את ההתקדמות שלכם לעבר ההטבה הבאה וקיצור דרך לארנק הדיגיטלי.';

  @override
  String get tourWalletTapDescription =>
      'הארנק הדיגיטלי שומר את ההטבות שמימשתם. לחצו על ״הארנק שלי״ למעלה או על כפתור הארנק כדי להיכנס אליו.';

  @override
  String get tourMatchesIntroTitle => 'תיאום סטודנטים';

  @override
  String get tourMatchesIntroDescription =>
      'כאן תוכלו למצוא סטודנטים שאפשר להכיר, לראות את אחוז ההתאמה ביניכם, לשוחח איתם ולתאם פגישה אישית דרך האפליקציה.';

  @override
  String get externalLinkOpenFailedCopied =>
      'לא ניתן לפתוח את הקישור — הוא הועתק ללוח במקום.';

  @override
  String get homeEventsNextMonth => 'אירועים בחודש הקרוב';

  @override
  String get homeEmptyEventsNextMonth => 'אין אירועים בחודש הקרוב כרגע.';

  @override
  String get eventFullNotice =>
      'האירוע מלא. אם ייפתחו מקומות נוספים, ההרשמה תיפתח כאן מחדש.';

  @override
  String get eventFullAction => 'האירוע מלא';

  @override
  String get tourEventsNextMonthTitle => 'אירועים בחודש הקרוב';

  @override
  String get tourEventsNextMonthDescription =>
      'בחלק הזה מופיעים רק אירועים שמתקיימים במהלך החודש הקרוב — מבט מהיר על מה שקורה בקרוב.';

  @override
  String get tourUpcomingEventsTitle => 'כל האירועים';

  @override
  String get tourUpcomingEventsDescription =>
      'בחלק הזה מופיעים כל האירועים שפתוחים להרשמה כרגע, בכל מועד שהוא — כולל אירועים שיתקיימו בעוד יותר מחודש. לחצו על אירוע כדי לקרוא את הפרטים ולהירשם.';

  @override
  String get authSpamFolderNote =>
      'אם לא מצאתם את המייל בתיבת הדואר הנכנס, בדקו גם בתיקיית הספאם.';

  @override
  String get errorSelectFaculty => 'יש לבחור פקולטה';

  @override
  String get errorSelectDegree => 'יש לבחור סוג תואר';

  @override
  String get errorSelectGender => 'יש לבחור מין';

  @override
  String get errorSelectYearOfStudy => 'יש לבחור שנת לימודים';

  @override
  String get profileRequiredFieldsMissing =>
      'יש להשלים את כל שדות החובה לפני ההמשך.';

  @override
  String get eventShareAction => 'שיתוף האירוע';

  @override
  String get eventShareCopyLink => 'העתקת הקישור';

  @override
  String get eventShareViaApps => 'שיתוף באמצעות…';

  @override
  String get eventShareLinkCopied => 'הקישור הועתק.';

  @override
  String get eventShareFailed => 'לא הצלחנו לשתף את האירוע. נסו שוב.';

  @override
  String eventShareMessage(String title) {
    return '$title — צפו באירוע באפליקציית C2C:';
  }

  @override
  String get eventNotFoundTitle => 'האירוע אינו זמין';

  @override
  String get eventNotFoundMessage =>
      'האירוע הזה אינו קיים יותר, או שאינו זמין לחשבון שלכם.';

  @override
  String get proposeMeetingRespondError =>
      'לא הצלחנו לעדכן את הפגישה. נסו שוב.';

  @override
  String get proposeMeetingAlreadyResponded => 'בקשת הפגישה הזו כבר נענתה.';

  @override
  String notificationEventReminderTomorrow(String title) {
    return 'מחר: $title';
  }

  @override
  String get notificationEventReminderTomorrowGeneric => 'יש לכם אירוע מחר';

  @override
  String notificationEventReminderToday(String title) {
    return 'היום: $title';
  }

  @override
  String get notificationEventReminderTodayGeneric => 'יש לכם אירוע היום';

  @override
  String get eventReminderPopupTitleTomorrow => 'האירוע שלכם מתקיים מחר';

  @override
  String get eventReminderPopupTitleToday => 'האירוע שלכם מתקיים היום';

  @override
  String get eventReminderPopupLocationLabel => 'מקום';

  @override
  String get eventReminderPopupStartLabel => 'שעת התחלה';

  @override
  String get eventReminderPopupEndLabel => 'שעת סיום';

  @override
  String get eventReminderPopupDismiss => 'הבנתי';

  @override
  String get eventReminderPopupOpenEvent => 'לצפייה באירוע';

  @override
  String get programPendingApprovalStatus =>
      'בקשתך להירשם נשלחה. כאשר תתקבל/י לאירוע נעדכן אותך כאן.';

  @override
  String get programAcceptedStatus => 'התקבלת בהצלחה';

  @override
  String get profileFullNameWarning =>
      'שימו לב: יש למלא את השם המלא שלכם. זהו השם שיופיע למנהלי האירועים, לכן אין להשתמש בכינויים אלא בשם המלא שלכם.';

  @override
  String get registerPendingApproval => 'בקשתך להירשם נשלחה וממתינה לאישור.';

  @override
  String get eventPendingApprovalLabel => 'ממתין לאישור';
}
