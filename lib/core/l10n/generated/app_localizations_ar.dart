// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'C2C';

  @override
  String get languageSelectionTitle => 'اختر لغتك';

  @override
  String get languageSelectionSubtitle =>
      'يمكنك تغيير ذلك لاحقًا من الإعدادات.';

  @override
  String get languageContinue => 'متابعة';

  @override
  String get welcomeTitle => 'أهلاً بك';

  @override
  String get welcomeSubtitle => 'حرمك الجامعي، متصل.';

  @override
  String get tabSignup => 'إنشاء حساب';

  @override
  String get tabLogin => 'تسجيل الدخول';

  @override
  String get methodPassword => 'الدخول بكلمة المرور';

  @override
  String get methodOtp => 'الدخول برمز عبر البريد';

  @override
  String get fieldFirstName => 'الاسم الأول';

  @override
  String get fieldLastName => 'اسم العائلة';

  @override
  String get fieldEmail => 'البريد الإلكتروني';

  @override
  String emailHint(String domain) {
    return 'you@$domain';
  }

  @override
  String get fieldPassword => 'كلمة المرور';

  @override
  String get fieldPasswordSignupHint => 'كلمة المرور (8 أحرف على الأقل)';

  @override
  String get fieldConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get buttonLogin => 'تسجيل الدخول';

  @override
  String get buttonSendCode => 'أرسل لي رمز التحقق';

  @override
  String get buttonCreateAccount => 'إنشاء حساب';

  @override
  String get linkForgotPassword => 'نسيت كلمة المرور';

  @override
  String domainNote(String domain) {
    return 'التسجيل مسموح فقط ببريد إلكتروني من $domain.';
  }

  @override
  String errorDomainNotAllowed(String domain) {
    return 'مسموح فقط ببريد $domain';
  }

  @override
  String get errorEnterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get errorEnterFirstName => 'أدخل اسمك الأول';

  @override
  String get errorEnterLastName => 'أدخل اسم عائلتك';

  @override
  String get errorEnterPassword => 'أدخل كلمة المرور';

  @override
  String get errorPasswordTooShort => 'يجب ألا تقل كلمة المرور عن 8 أحرف';

  @override
  String get errorPasswordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get errorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get errorEmailNotConfirmedSendingCode =>
      'يجب تأكيد بريدك الإلكتروني قبل تسجيل الدخول. جارٍ إرسال رمز…';

  @override
  String get errorUserAlreadyExists =>
      'يوجد حساب بهذا البريد الإلكتروني بالفعل — حاول تسجيل الدخول';

  @override
  String get errorUserNotFound =>
      'لا يوجد حساب بهذا البريد الإلكتروني — سجّل أولاً';

  @override
  String get errorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get verifyTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String get verifySubtitle =>
      'أرسلنا رمزًا مكونًا من 6 أرقام إلى بريدك الإلكتروني. أدخله هنا للمتابعة.';

  @override
  String get otpHint => '000000';

  @override
  String get errorInvalidOtp => 'أدخل الرمز المكون من 6 أرقام';

  @override
  String get errorOtpIncorrect => 'الرمز غير صحيح أو انتهت صلاحيته.';

  @override
  String get errorBlockedUser =>
      'تم حظر هذا الحساب من قبل إدارة C2C بسبب مخالفة شروط الاستخدام.';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get buttonVerify => 'تحقق وتابع';

  @override
  String get linkResend => 'لم يصلك رمز؟ أعد الإرسال';

  @override
  String linkResendIn(int seconds) {
    return 'يمكن إعادة الإرسال خلال $seconds ثانية';
  }

  @override
  String get infoResent => 'تم إرسال رمز جديد إلى بريدك الإلكتروني.';

  @override
  String get linkBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get forgotTitle => 'استعادة كلمة المرور';

  @override
  String get forgotSubtitle => 'سنرسل رابط إعادة التعيين إلى بريدك الإلكتروني.';

  @override
  String get buttonSendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get infoResetLinkSent =>
      'أرسلنا لك رابط إعادة تعيين كلمة المرور عبر البريد الإلكتروني.';

  @override
  String get errorEnterUniversityEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get resetTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get fieldNewPasswordHint => 'كلمة مرور جديدة (8 أحرف على الأقل)';

  @override
  String get buttonUpdatePassword => 'تحديث كلمة المرور';

  @override
  String get infoPasswordUpdated =>
      'تم تحديث كلمة المرور. جارٍ تحويلك إلى التطبيق…';

  @override
  String get resetLinkInactive =>
      'رابط إعادة التعيين غير نشط. الرجاء طلب رابط جديد عبر \"نسيت كلمة المرور\".';

  @override
  String get completeProfileTitle => 'أكمل ملفك الشخصي';

  @override
  String get completeProfileSubtitle => 'بضعة تفاصيل قبل أن تبدأ.';

  @override
  String get fieldFacultyOptional => 'الكلية (اختياري)';

  @override
  String get fieldYearOptional => 'السنة (اختياري)';

  @override
  String get buttonContinue => 'متابعة';

  @override
  String get errorSaveProfileFailed => 'تعذر حفظ ملفك الشخصي. حاول مرة أخرى.';

  @override
  String get policyTitle => 'السياسة وشروط الاستخدام';

  @override
  String policyVersionLabel(int version) {
    return 'الإصدار $version';
  }

  @override
  String get policyNoneActive => 'لا توجد سياسة نشطة حاليًا.';

  @override
  String get buttonAgree => 'أوافق على شروط الاستخدام';

  @override
  String get buttonAlreadyAgreed => 'لقد وافقت بالفعل';

  @override
  String get buttonContinueToApp => 'المتابعة إلى التطبيق';

  @override
  String get errorLoadPolicyFailed => 'تعذر تحميل السياسة.';

  @override
  String get errorAgreePolicyFailed => 'تعذر حفظ موافقتك. حاول مرة أخرى.';

  @override
  String get restrictedAccessTitle => 'الوصول مقيَّد';

  @override
  String get restrictedAccessMessage =>
      'هذا التطبيق مخصص للطلاب فقط. حسابك لا يملك صلاحية وصول الطالب.';

  @override
  String homeSignedInAs(String email) {
    return 'تم تسجيل الدخول باسم $email';
  }

  @override
  String get actionSignOut => 'تسجيل الخروج';

  @override
  String homeGreeting(String name) {
    return 'أهلاً، $name';
  }

  @override
  String get homeMyPoints => 'نقاطي';

  @override
  String get homeHeroTitle => 'ماذا يحدث اليوم في الحرم الجامعي؟';

  @override
  String get homeMonthlyChampions => 'أبطال الشهر';

  @override
  String get coachMarkNavHomeTitle => 'الرئيسية';

  @override
  String get coachMarkNavHomeDescription =>
      'لوحتك الرئيسية — الفعاليات والإشعارات وكل ما هو جديد.';

  @override
  String get coachMarkNavMatchesTitle => 'التوافق';

  @override
  String get coachMarkNavMatchesDescription => 'اكتشف وتواصل مع زملائك الطلاب.';

  @override
  String get coachMarkNavScanTitle => 'مسح';

  @override
  String get coachMarkNavScanDescription =>
      'امسح رمز QR لتسجيل الحضور أو كسب نقاط.';

  @override
  String get coachMarkNavBenefitsTitle => 'المزايا';

  @override
  String get coachMarkNavBenefitsDescription => 'استبدل نقاطك بمزايا الشركاء.';

  @override
  String get coachMarkNavProfileTitle => 'الملف الشخصي';

  @override
  String get coachMarkNavProfileDescription =>
      'عدّل ملفك الشخصي وأدر الإعدادات.';

  @override
  String get coachMarkMyEventsTitle => 'فعالياتي';

  @override
  String get coachMarkMyEventsDescription =>
      'شاهد الفعاليات والاجتماعات التي سجّلت فيها.';

  @override
  String get coachMarkUpcomingEventsTitle => 'الفعاليات القادمة';

  @override
  String get coachMarkUpcomingEventsDescription =>
      'تصفّح فعاليات الحرم الجامعي القادمة قريبًا.';

  @override
  String get coachMarkNotificationsTitle => 'تحديد عناصر متعددة';

  @override
  String get coachMarkNotificationsDescription =>
      'اضغط مطولًا على إشعار لتحديد عدة عناصر وتمييزها كمقروءة أو غير مقروءة أو حذفها معًا.';

  @override
  String get coachMarkChampionsTitle => 'أبطال الشهر';

  @override
  String get coachMarkChampionsDescription =>
      'شاهد أصحاب أعلى النقاط هذا الشهر.';

  @override
  String get homeMyNotifications => 'إشعاراتي';

  @override
  String get homeUpcomingEvents => 'كل الفعاليات';

  @override
  String get homeMyEventsCalendar => 'تقويم فعالياتي';

  @override
  String get homeNewStudents => 'طلاب جدد';

  @override
  String get homeSeeAll => 'الكل';

  @override
  String get actionSeeMore => 'عرض المزيد';

  @override
  String get homeCampusEvents => 'فعاليات الحرم الجامعي';

  @override
  String get filterAll => 'الكل';

  @override
  String get filtersTitle => 'الفلاتر';

  @override
  String get filtersClearAll => 'مسح الكل';

  @override
  String get filtersApply => 'تطبيق الفلاتر';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get eventUpcomingTag => 'قريب';

  @override
  String get eventRegisteredLabel => 'مسجَّل في الفعالية';

  @override
  String get eventAttendedLabel => 'حضرت الفعالية';

  @override
  String get eventRegisterAction => 'التسجيل في الفعالية';

  @override
  String eventPointsLabel(int points) {
    return '‎+$points نقطة';
  }

  @override
  String get homeEmptyEvents => 'لا توجد فعاليات قادمة حاليًا.';

  @override
  String get homeEmptySurveys => 'لا توجد استبيانات متاحة حاليًا.';

  @override
  String get homeEmptyStudents => 'لا يوجد طلاب جدد حاليًا.';

  @override
  String get homeLoadError => 'تعذر تحميل الصفحة الرئيسية. حاول مرة أخرى.';

  @override
  String get registerSuccess => 'تم تسجيلك بنجاح!';

  @override
  String get registerErrorAlready => 'أنت مسجَّل بالفعل في هذه الفعالية';

  @override
  String get registerErrorFull => 'هذه الفعالية مكتملة العدد';

  @override
  String get registerErrorEnded => 'انتهت هذه الفعالية بالفعل';

  @override
  String get registerErrorNotPublished => 'التسجيل في هذه الفعالية غير متاح';

  @override
  String get registerErrorNotFound => 'الفعالية غير موجودة';

  @override
  String get registerErrorGeneric => 'تعذر التسجيل. حاول مرة أخرى.';

  @override
  String get deleteEventTitle => 'حذف الفعالية';

  @override
  String get deleteEventMessage => 'هل أنت متأكد أنك تريد حذف هذه الفعالية؟';

  @override
  String get deleteEventConfirm => 'حذف';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get deleteEventSuccess => 'تم حذف الفعالية.';

  @override
  String get deleteEventError => 'تعذر حذف الفعالية. حاول مرة أخرى.';

  @override
  String get registrantsTitle => 'المسجَّلون';

  @override
  String get registrantsEmpty => 'لا يوجد مسجَّلون بعد.';

  @override
  String get registrantAttended => 'حضر';

  @override
  String get registrantRegisteredOnly => 'مسجَّل';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get navBenefits => 'المزايا';

  @override
  String get navScanning => 'مسح';

  @override
  String get navMatches => 'التعارف';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get matchesTitle => 'التعارف';

  @override
  String get matchesEmpty => 'لا يوجد طلاب آخرون بعد.';

  @override
  String get matchesLoadError => 'تعذر تحميل التعارف. حاول مرة أخرى.';

  @override
  String get matchesConnectAction => 'الاتصال عبر QR';

  @override
  String get profileAboutLabel => 'نبذة';

  @override
  String get profileLanguagesLabel => 'اللغات';

  @override
  String get profileMessageAction => 'إرسال رسالة';

  @override
  String get profileViewAction => 'عرض الملف الشخصي';

  @override
  String get matchesSearchHint => 'ابحث بالاسم أو الهواية أو اللغة...';

  @override
  String get matchesFilterToggle => 'تصفية';

  @override
  String get matchesSortToggle => 'ترتيب';

  @override
  String get matchesSortHighToLow => 'التوافق: من الأعلى إلى الأقل';

  @override
  String get matchesSortLowToHigh => 'التوافق: من الأقل إلى الأعلى';

  @override
  String matchesCompatibilityBadge(int percent) {
    return 'توافق $percent%';
  }

  @override
  String matchesResultsCount(int count) {
    return '$count تطابق طلابي';
  }

  @override
  String matchesYearInline(int year) {
    return 'السنة $year';
  }

  @override
  String get matchesSendHelloAction => 'أرسل تحية';

  @override
  String get filterFacultyLabel => 'الكلية';

  @override
  String get filterFieldOfStudyLabel => 'مجال الدراسة';

  @override
  String get filterDegreeLabel => 'الدرجة العلمية';

  @override
  String get filterYearLabel => 'سنة الدراسة';

  @override
  String get filterLanguageLabel => 'اللغة';

  @override
  String get filterGenderLabel => 'الجنس';

  @override
  String get scanningTitle => 'المسح والنقاط';

  @override
  String get scanTabLabel => 'مسح / إدخال رمز';

  @override
  String get scanCardTitle => 'رقمك الجامعي';

  @override
  String get scanCardSubtitle =>
      'أظهر هذا لمضيف الفعالية إذا تعذّر مسح رمز QR.';

  @override
  String get scanEventQrAction => 'مسح رمز QR للفعالية';

  @override
  String get scanEventCameraTitle => 'امسح باستخدام كاميرا جهازك';

  @override
  String get scanEventGenericSubtitle =>
      'وجّه الكاميرا نحو رمز QR — سيتم اكتشافه تلقائيًا.';

  @override
  String get scanCameraPermissionHint =>
      'إذا لم تفتح الكاميرا، فاسمح بالوصول إليها من إعدادات جهازك.';

  @override
  String get scanAnotherAction => 'مسح آخر';

  @override
  String get scanEventQrPickerTitle => 'أي فعالية؟';

  @override
  String get scanEventQrEmpty =>
      'سجّل في فعالية أولاً لتسجيل الحضور برمز QR الخاص بها.';

  @override
  String get scanEnterCodeLabel => 'أدخل الرمز يدويًا';

  @override
  String get scanEnterCodeAction => 'تأكيد';

  @override
  String get scanEnterCodeError => 'أدخل رمزًا أولاً';

  @override
  String get pointsHistoryTitle => 'سجل النقاط';

  @override
  String get pointsHistoryEmpty => 'لا يوجد نشاط نقاط بعد.';

  @override
  String get pointsHistoryLoadError => 'تعذر تحميل سجل النقاط.';

  @override
  String get howToEarnTitle => 'كيف تكسب النقاط';

  @override
  String get howToEarnEvent =>
      'المشاركة في فعالية (مسح رمز الفعالية أثناء النشاط): +20 لكل شخص';

  @override
  String get howToEarnFirstMeeting => 'لقاء أول مع طالب/ة جديد/ة: +25 لكل شخص';

  @override
  String get howToEarnSecondMeeting => 'لقاء ثانٍ مع نفس الطالب/ة: +20 لكل شخص';

  @override
  String get howToEarnRepeatMeeting =>
      'اللقاء الثالث فما فوق مع نفس الطالب/ة: +10 لكل شخص';

  @override
  String get reasonEventAttendance => 'المشاركة في فعالية';

  @override
  String get reasonMeetingFirst => 'لقاء أول';

  @override
  String get reasonMeetingSecond => 'لقاء ثانٍ';

  @override
  String get reasonMeetingRepeat => 'لقاء متكرر';

  @override
  String get reasonGroupMeeting => 'لقاء جماعي';

  @override
  String get reasonMonthlyPrize => 'جائزة شهرية';

  @override
  String get reasonBenefitRedeem => 'استبدال ميزة';

  @override
  String get reasonGeneric => 'نقاط';

  @override
  String get championsTabLabel => 'أبطال الشهر';

  @override
  String get championsTitle => 'أبطال الشهر';

  @override
  String get actionBack => 'رجوع';

  @override
  String get actionNext => 'التالي';

  @override
  String get actionSkip => 'تخطي';

  @override
  String get actionGotIt => 'فهمت';

  @override
  String get championsHeroLabel => 'ترتيب هذا الشهر';

  @override
  String get championsHeroTitle => 'أبطال هذا الشهر';

  @override
  String get championsMyRankLabel => 'ترتيبي';

  @override
  String get championsMyPointsLabel => 'نقاطي هذا الشهر';

  @override
  String championsGapLabel(int gap, String name) {
    return '‎$gap نقطة لتجاوز $name';
  }

  @override
  String get championsUnranked => 'لم تحصل على أي نقاط هذا الشهر بعد.';

  @override
  String get championsListTitle => 'نقاط هذا الشهر';

  @override
  String get championsHeroMonthPrefix => 'أبطال';

  @override
  String get championsUpdateFrequency => 'يُحدَّث شهريًا';

  @override
  String get championsTableRankCol => 'الترتيب';

  @override
  String get championsTableNameCol => 'الاسم';

  @override
  String get championsTablePointsCol => 'النقاط';

  @override
  String get championsEmpty => 'لا يوجد ترتيب بعد لهذا الشهر.';

  @override
  String get championsLoadError => 'تعذر تحميل لوحة الترتيب.';

  @override
  String get adminAccessDenied => 'ليس لديك صلاحية الوصول لهذه الصفحة.';

  @override
  String get eventsTitle => 'الفعاليات';

  @override
  String get eventTypeSingle => 'لمرة واحدة';

  @override
  String get eventTypeProgram => 'برنامج';

  @override
  String get eventFiltersButton => 'الفلاتر';

  @override
  String get eventFiltersTitle => 'تصفية الفعاليات';

  @override
  String get eventFilterTypeLabel => 'النوع';

  @override
  String get eventFilterCategoryLabel => 'الفئة';

  @override
  String get eventFilterOrganizerLabel => 'المنظّم';

  @override
  String get eventFiltersApply => 'تطبيق الفلاتر';

  @override
  String get eventFiltersReset => 'إعادة تعيين';

  @override
  String get eventDescriptionLabel => 'عن الفعالية';

  @override
  String get eventCancelAction => 'إلغاء التسجيل';

  @override
  String get eventEndedLabel => 'انتهت هذه الفعالية';

  @override
  String get cancelEventRegistrationTitle => 'إلغاء التسجيل؟';

  @override
  String get cancelEventRegistrationMessage =>
      'يمكنك التسجيل مرة أخرى لاحقًا إذا غيّرت رأيك.';

  @override
  String get cancelEventRegistrationConfirm => 'إلغاء التسجيل';

  @override
  String get cancelEventRegistrationSuccess => 'تم إلغاء التسجيل.';

  @override
  String get cancelEventRegistrationError => 'تعذر إلغاء تسجيلك.';

  @override
  String get myEventsTitle => 'فعالياتي';

  @override
  String get myEventsFilterUpcoming => 'القادمة';

  @override
  String get myEventsFilterAttended => 'حضرتها';

  @override
  String get myEventsFilterMissed => 'فاتتني';

  @override
  String get myEventsAttendedMessage => 'أحسنت! نحن فخورون بانضمامك!';

  @override
  String get myEventsMissedMessage => 'اشتقنا لك! للأسف لم تتمكن من الانضمام.';

  @override
  String get myEventsUpcomingMessage => 'نتطلع لرؤيتك!';

  @override
  String get myEventsEmpty => 'لم تسجّل في أي فعالية بعد.';

  @override
  String get myEventsLoadError => 'تعذر تحميل فعالياتك.';

  @override
  String get eventEditAction => 'تعديل';

  @override
  String get eventFormCreateTitle => 'إنشاء فعالية';

  @override
  String get eventFormEditTitle => 'تعديل الفعالية';

  @override
  String get eventFormTitleLabel => 'العنوان';

  @override
  String get eventFormDescriptionLabel => 'الوصف';

  @override
  String get eventFormCategoryLabel => 'الفئة';

  @override
  String get eventFormLocationLabel => 'الموقع';

  @override
  String get eventFormStartLabel => 'البداية';

  @override
  String get eventFormEndLabel => 'النهاية';

  @override
  String get eventFormPointsLabel => 'النقاط';

  @override
  String get eventFormCapacityLabel => 'السعة (اختياري)';

  @override
  String get eventFormImageUrlLabel => 'رابط الصورة (اختياري)';

  @override
  String get eventFormOrganizerLabel => 'اسم المنظّم (اختياري)';

  @override
  String get eventFormVisibilityLabel => 'من يمكنه رؤية هذه الفعالية؟';

  @override
  String get eventVisibilityOnlyMe => 'أنا فقط';

  @override
  String get eventVisibilityEveryone => 'الجميع';

  @override
  String get eventVisibilitySpecificFaculties => 'كليات محددة';

  @override
  String get eventVisibilitySpecificGroups => 'مجموعات محددة';

  @override
  String get eventFormFacultiesLabel => 'اختر الكليات';

  @override
  String get eventFormGroupTagsLabel => 'وسوم المجموعة (مفصولة بفواصل)';

  @override
  String get eventFormErrorTitleRequired => 'أدخل عنوانًا';

  @override
  String get eventFormErrorDatesRequired => 'اختر وقت البداية والنهاية';

  @override
  String get eventFormErrorEndBeforeStart =>
      'يجب أن يكون وقت النهاية بعد وقت البداية';

  @override
  String get eventFormErrorGeneric =>
      'تعذر حفظ الفعالية. يرجى التحقق من التفاصيل والمحاولة مرة أخرى.';

  @override
  String get eventFormSubmitCreate => 'إرسال للموافقة';

  @override
  String get eventFormSubmitUpdate => 'حفظ التغييرات';

  @override
  String get eventShowQrAction => 'عرض رمز QR';

  @override
  String get eventQrScanningLabel => 'المسح';

  @override
  String eventQrRefreshesIn(int seconds) {
    return 'يتجدد خلال $seconds ث';
  }

  @override
  String get eventQrLoadError => 'تعذر إنشاء رمز QR.';

  @override
  String get eventQrHint =>
      'اعرض رمز QR هذا للطلاب أثناء الفعالية. يتجدد كل 10 ثوانٍ.';

  @override
  String get eventScanningClosedMessage => 'المسح مغلق.';

  @override
  String get eventScanTitle => 'مسح لتسجيل الحضور';

  @override
  String get eventScanGenericHeading => 'امسح رمز QR لأي فعالية لتسجيل الحضور';

  @override
  String get eventScanToCheckInAction => 'مسح لتسجيل الحضور';

  @override
  String eventScanSuccess(int points) {
    return 'حصلت على $points نقطة!';
  }

  @override
  String get eventScanErrorExpired => 'قمت بالمسح بعد انتهاء الوقت المحدد.';

  @override
  String get eventScanErrorAlreadyScanned =>
      'لقد قمت بمسح هذه الفعالية بالفعل. لا يمكنك المسح مرة أخرى.';

  @override
  String get eventScanErrorNotRegistered =>
      'يجب عليك التسجيل في هذه الفعالية قبل المسح.';

  @override
  String get eventScanErrorInvalid => 'رمز QR غير صالح.';

  @override
  String get eventStatsRegistered => 'المسجّلون';

  @override
  String get eventStatsAttended => 'الحاضرون';

  @override
  String get eventStatsMissed => 'الغائبون';

  @override
  String programPointsEquation(int points, int count, int total) {
    return '$points نقطة × $count جلسات = $total نقطة ممكنة';
  }

  @override
  String get programSessionsTitle => 'الجلسات';

  @override
  String get programSessionsEmpty => 'لا توجد جلسات بعد.';

  @override
  String get programSessionsLoadError => 'تعذر تحميل الجلسات.';

  @override
  String get programManageSessionsAction => 'إدارة الجلسات';

  @override
  String get programViewSessionsAction => 'عرض الجلسات';

  @override
  String programAttendanceProgress(int attended, int total) {
    return 'حضرت $attended من أصل $total جلسات';
  }

  @override
  String get programAttendedAllSessions => 'حضرت جميع الجلسات!';

  @override
  String get programSessionsFormTitle => 'الجلسات';

  @override
  String get programSessionLabel => 'الجلسة';

  @override
  String get programAddSessionAction => 'إضافة جلسة أخرى';

  @override
  String get eventFormErrorSessionsRequired => 'أضف جلسة واحدة على الأقل';

  @override
  String get eventFormErrorSessionIncomplete =>
      'أدخل العنوان والوقتين لكل جلسة';

  @override
  String get chatsTitle => 'المحادثات';

  @override
  String get chatsEmpty => 'لا توجد محادثات بعد.';

  @override
  String get chatsSearchHint => 'بحث في المحادثات';

  @override
  String get chatsSearchEmpty => 'لا توجد محادثات مطابقة لبحثك.';

  @override
  String get chatsLoadError => 'تعذر تحميل محادثاتك.';

  @override
  String get chatMessageHint => 'اكتب رسالة…';

  @override
  String get chatBlockAction => 'حظر';

  @override
  String get chatUnblockAction => 'إلغاء الحظر';

  @override
  String get chatBlockedBanner =>
      'لقد حظرت هذا المستخدم. ألغِ الحظر لإرسال الرسائل.';

  @override
  String get chatBlockedByOtherBanner =>
      'لا يمكنك إرسال رسائل في هذه المحادثة.';

  @override
  String get chatBlockConfirmTitle => 'حظر هذا المستخدم؟';

  @override
  String get chatBlockConfirmMessage => 'لن يتمكنوا من مراسلتك حتى تلغي الحظر.';

  @override
  String get chatEmptyThread => 'قل مرحبًا 👋';

  @override
  String get chatDateToday => 'اليوم';

  @override
  String get chatDateYesterday => 'أمس';

  @override
  String get proposeMeetingTitle => 'اقتراح لقاء';

  @override
  String get proposeMeetingPickDateTime => 'اختر التاريخ والوقت';

  @override
  String get proposeMeetingPickEndDateTime => 'اختر وقت الانتهاء';

  @override
  String get proposeMeetingNotesLabel => 'ملاحظات (اختياري)';

  @override
  String get proposeMeetingSubmit => 'إرسال الاقتراح';

  @override
  String get proposeMeetingErrorDateRequired => 'اختر تاريخًا ووقتًا';

  @override
  String get proposeMeetingErrorEndBeforeStart =>
      'يجب أن يكون وقت الانتهاء بعد وقت البدء';

  @override
  String get proposeMeetingError => 'تعذر إرسال الاقتراح';

  @override
  String get proposeMeetingErrorSameStudentToday =>
      'لديك بالفعل لقاء مع هذا الطالب/ة في ذلك اليوم. يمكن اللقاء مع الطالب/ة نفسه مرة واحدة في اليوم.';

  @override
  String get proposeMeetingErrorDailyLimitSelf =>
      'لديك بالفعل لقاءات مع 5 طلاب مختلفين في ذلك اليوم، وهذا هو الحد اليومي. جرّب تاريخًا آخر.';

  @override
  String get proposeMeetingErrorDailyLimitOther =>
      'لدى هذا الطالب/ة بالفعل لقاءات مع 5 طلاب مختلفين في ذلك اليوم. جرّب تاريخًا آخر.';

  @override
  String get proposeMeetingCardTitle => 'اقتراح لقاء';

  @override
  String get proposeMeetingAccept => 'قبول';

  @override
  String get proposeMeetingDecline => 'رفض';

  @override
  String get proposeMeetingWaiting => 'بانتظار الرد…';

  @override
  String get proposeMeetingAccepted => 'تم القبول';

  @override
  String get proposeMeetingDeclined => 'تم الرفض';

  @override
  String get reportUserAction => 'إبلاغ';

  @override
  String reportUserTitle(String name) {
    return 'الإبلاغ عن $name';
  }

  @override
  String get reportUserReasonLabel => 'السبب';

  @override
  String get reportUserDetailsLabel => 'التفاصيل';

  @override
  String get reportUserErrorReasonRequired => 'أدخل سببًا';

  @override
  String get reportUserErrorDetailsRequired => 'أدخل بعض التفاصيل';

  @override
  String get reportUserImagesLabel => 'لقطات شاشة (اختياري)';

  @override
  String get reportUserAddImage => 'إضافة';

  @override
  String get reportUserSubmit => 'إرسال البلاغ';

  @override
  String get reportUserSuccess => 'تم إرسال البلاغ.';

  @override
  String get reportUserError => 'تعذر إرسال البلاغ.';

  @override
  String get groupMeetingListEntryPoint => 'اللقاءات الجماعية';

  @override
  String get groupMeetingListTitle => 'لقاءاتي الجماعية';

  @override
  String get groupMeetingCreateAction => 'لقاء جماعي جديد';

  @override
  String get groupMeetingListLoadError => 'تعذر تحميل لقاءاتك الجماعية.';

  @override
  String get groupMeetingListEmpty => 'ليس لديك أي لقاءات جماعية بعد.';

  @override
  String get groupMeetingStatusApproved => 'تمت الموافقة';

  @override
  String get groupMeetingStatusRejected => 'مرفوض';

  @override
  String get groupMeetingStatusPending => 'بانتظار الموافقة';

  @override
  String get groupMeetingRoleOrganizer => 'أنت منظّم هذا اللقاء';

  @override
  String groupMeetingRoleParticipant(String name) {
    return 'بتنظيم $name';
  }

  @override
  String get groupMeetingFinishedTag => 'انتهى';

  @override
  String get groupMeetingShowQrAction => 'عرض رمز QR';

  @override
  String get groupMeetingScanAction => 'مسح';

  @override
  String get groupMeetingEnterCodeTitle => 'إدخال رمز';

  @override
  String get groupMeetingEnterCodeHint => 'الصق الرمز الذي شاركه المنظّم';

  @override
  String get groupMeetingEnterCodeAction => 'إدخال الرمز';

  @override
  String get groupMeetingCreateTitle => 'لقاء جماعي جديد';

  @override
  String get groupMeetingCreateHint =>
      'يُرسَل طلبك للموافقة من قِبل المشرف قبل إنشاء رابط التسجيل.';

  @override
  String get groupMeetingLocationLabel => 'الموقع';

  @override
  String get groupMeetingLocationHint =>
      'يجب أن تُعقد الاجتماعات الجماعية داخل حرم الجامعة.';

  @override
  String get groupMeetingLocationRequired =>
      'يرجى اختيار موقع داخل الحرم الجامعي.';

  @override
  String groupMeetingMaxParticipantsLabel(int count) {
    return 'الحد الأقصى للمشاركين: $count';
  }

  @override
  String get groupMeetingCreateSubmit => 'إرسال الطلب';

  @override
  String get groupMeetingCreateSuccess =>
      'تم إرسال طلب اللقاء الجماعي الخاص بك.';

  @override
  String get groupMeetingCreateError => 'تعذر إرسال طلبك.';

  @override
  String get groupMeetingRegistrationTitle => 'لقاء جماعي';

  @override
  String get groupMeetingRegistrationInvalid =>
      'هذا الرابط غير صالح أو انتهت صلاحيته.';

  @override
  String groupMeetingRegisteredCount(int count, int max) {
    return '$count من $max مسجَّلون';
  }

  @override
  String get groupMeetingRegisterAction => 'تسجيل';

  @override
  String get groupMeetingRegisterSuccess => 'تم تسجيلك!';

  @override
  String get groupMeetingAlreadyRegistered =>
      'أنت مسجَّل بالفعل في هذا اللقاء.';

  @override
  String get groupMeetingRegisterErrorFull => 'هذا اللقاء مكتمل العدد.';

  @override
  String get groupMeetingRegisterErrorAlready => 'أنت مسجَّل بالفعل.';

  @override
  String get groupMeetingRegisterErrorOwn => 'أنت منظّم هذا اللقاء.';

  @override
  String get groupMeetingRegisterErrorGeneric => 'تعذر التسجيل في هذا اللقاء.';

  @override
  String get groupMeetingQrHint =>
      'اعرض رمز QR هذا على المشاركين. يتم تحديثه كل 10 ثوانٍ.';

  @override
  String get groupMeetingFinishAction => 'إنهاء اللقاء';

  @override
  String get groupMeetingFinishError => 'تعذر إنهاء اللقاء.';

  @override
  String get groupMeetingFinishDialogTitle => 'انتهى اللقاء';

  @override
  String get groupMeetingFinishDialogOk => 'موافق';

  @override
  String get groupMeetingFinishOutcomeNone =>
      'لم يقم أحد بالمسح، لذا لم تُمنح أي نقاط.';

  @override
  String groupMeetingFinishOutcomeOneToOne(int points) {
    return 'قام شخص واحد فقط بالمسح، لذا اعتُبر هذا لقاءً فرديًا — حصل كلاكما على $points نقطة.';
  }

  @override
  String get groupMeetingFinishOutcomeCapped =>
      'قام شخص واحد فقط بالمسح، لذا اعتُبر هذا لقاءً فرديًا — لكن الحد اليومي لهذا الزوج قد استُنفد بالفعل، فلم تُمنح أي نقاط.';

  @override
  String groupMeetingFinishOutcomeGroup(int organizerPoints, int scanners) {
    return 'حصلت على $organizerPoints نقطة، وحصل $scanners من المشاركين على نقاط كل منهم.';
  }

  @override
  String get groupMeetingScanTitle => 'مسح للانضمام';

  @override
  String get groupMeetingScanSuccess => 'لقد انضممت إلى اللقاء!';

  @override
  String get groupMeetingScanErrorOwnCode => 'لا يمكنك مسح رمز QR الخاص بك.';

  @override
  String get benefitsCatalogTabLabel => 'الكتالوج';

  @override
  String get benefitsWalletTabLabel => 'محفظتي';

  @override
  String benefitsPointsBalance(int points) {
    return 'لديك $points نقطة';
  }

  @override
  String get benefitsCatalogLoadError => 'تعذر تحميل كتالوج المزايا.';

  @override
  String get benefitsCatalogEmpty => 'لا توجد مزايا متاحة حاليًا.';

  @override
  String get benefitsWalletLoadError => 'تعذر تحميل محفظتك.';

  @override
  String get benefitsWalletEmpty => 'لم تستبدل أي مزايا بعد.';

  @override
  String get benefitsWalletTitle => 'محفظتي الرقمية';

  @override
  String get benefitsWalletSubtitle => 'جميع بطاقاتك الرقمية في مكان واحد';

  @override
  String get benefitsWalletPointsLabel => 'رصيد النقاط';

  @override
  String get benefitsWalletFilterAll => 'الكل';

  @override
  String get benefitsWalletFilterNotUsed => 'غير مستخدم';

  @override
  String get benefitsWalletFilterUsed => 'مستخدم';

  @override
  String get benefitsWalletFilterButton => 'تصفية';

  @override
  String get benefitsWalletFilterByBusiness => 'تصفية حسب العمل';

  @override
  String get benefitsWalletFilterClear => 'إزالة التصفية';

  @override
  String get benefitsStatusLabel => 'حالتي';

  @override
  String get benefitsCatalogHeading => 'تحويل النقاط إلى مزايا';

  @override
  String get benefitsOpenWalletAction => 'محفظتي الرقمية';

  @override
  String get benefitsCategoryAll => 'الكل';

  @override
  String benefitPointCost(int points) {
    return '$points نقطة';
  }

  @override
  String get benefitRedeemAction => 'استبدال';

  @override
  String get benefitNotEnoughPoints => 'نقاط غير كافية';

  @override
  String get benefitAlreadyActiveLabel => 'في محفظتك';

  @override
  String get benefitAlreadyActiveMessage =>
      'لديك بطاقة رقمية في محفظتك لهذه الميزة.';

  @override
  String get benefitRedeemConfirmTitle => 'استبدال ميزة';

  @override
  String benefitRedeemConfirmMessage(String title, int points) {
    return 'استبدال \"$title\" مقابل $points نقطة؟';
  }

  @override
  String get benefitRedeemErrorInsufficientPoints =>
      'ليس لديك نقاط كافية لهذه الميزة.';

  @override
  String get benefitRedeemErrorUnavailable => 'هذه الميزة لم تعد متاحة.';

  @override
  String get benefitRedeemErrorAlreadyActive =>
      'لديك بالفعل بطاقة رقمية في محفظتك لهذه الميزة.';

  @override
  String get benefitRedeemErrorNotAStudent =>
      'لا يمكن لهذا الحساب استبدال الميزات — الحسابات الطلابية فقط يمكنها ذلك.';

  @override
  String get benefitRedeemErrorGeneric => 'تعذر استبدال هذه الميزة.';

  @override
  String get benefitCardRedeemedTag => 'تم الاستبدال';

  @override
  String get benefitCardAvailableTag => 'متاح';

  @override
  String get benefitCardStatusLabel => 'الحالة';

  @override
  String get benefitCardOpenAction => 'البطاقة الرقمية';

  @override
  String get benefitCardShowHint =>
      'اعرض رمز QR هذا على الشريك لإتمام الاستبدال.';

  @override
  String get benefitCardCodeLabel => 'أو أعطِ هذا الرمز إذا تعذّر مسح رمز QR';

  @override
  String benefitCardAcquiredOn(String date) {
    return 'تم الاستبدال بالنقاط بتاريخ $date';
  }

  @override
  String benefitCardRedeemedOn(String date) {
    return 'تم الاستخدام لدى الشريك بتاريخ $date';
  }

  @override
  String get supportContactsRowLabel => 'الدعم الفني';

  @override
  String get supportContactsTitle => 'الدعم الفني';

  @override
  String get supportContactsError => 'تعذّر تحميل جهات اتصال الدعم.';

  @override
  String get supportContactsEmpty => 'لم يتم إعداد جهات اتصال الدعم بعد.';

  @override
  String get supportContactsCopy => 'نسخ رقم الهاتف';

  @override
  String get supportContactsCopied => 'تم نسخ رقم الهاتف';

  @override
  String get benefitFormCreateTitle => 'ميزة جديدة';

  @override
  String get benefitFormEditTitle => 'تعديل الميزة';

  @override
  String get benefitFormPartnerLabel => 'اسم العمل الشريك';

  @override
  String get benefitFormImageUrlLabel => 'رابط الصورة';

  @override
  String get benefitFormPointCostLabel => 'تكلفة النقاط';

  @override
  String get benefitFormErrorPointCostInvalid => 'أدخل تكلفة نقاط أكبر من 0';

  @override
  String get benefitFormCreateAction => 'إنشاء ميزة';

  @override
  String get benefitFormSaveAction => 'حفظ';

  @override
  String get benefitProfileAboutBenefit => 'عن هذه الميزة';

  @override
  String get benefitProfileAboutBusiness => 'عن النشاط التجاري';

  @override
  String get benefitProfileHowToRedeem => 'كيفية الاستخدام';

  @override
  String get benefitProfileLinkLabel => 'رابط';

  @override
  String get benefitProfileOpenLink => 'فتح الرابط';

  @override
  String get benefitProfileLocationLabel => 'الموقع';

  @override
  String get benefitProfileOpenMaps => 'فتح في الخرائط';

  @override
  String get benefitProfileCategoryLabel => 'الفئة';

  @override
  String get benefitProfileCostLabel => 'تكلفة النقاط';

  @override
  String get benefitFormSectionBasics => 'المعلومات الأساسية';

  @override
  String get benefitFormSectionBusiness => 'معلومات النشاط التجاري';

  @override
  String get benefitFormSectionRedemption => 'تفاصيل الاستبدال';

  @override
  String get benefitFormSectionLocation => 'الموقع';

  @override
  String get benefitFormBusinessDescriptionLabel => 'وصف النشاط التجاري';

  @override
  String get benefitFormHowToRedeemLabel => 'كيفية الاستخدام';

  @override
  String get benefitFormExternalLinkLabel => 'رابط خارجي (إنستغرام، موقع…)';

  @override
  String get benefitFormLocationLabel => 'الموقع';

  @override
  String get benefitFormMapsLinkLabel => 'رابط خرائط جوجل';

  @override
  String get benefitFormImageLabel => 'صورة الميزة';

  @override
  String get benefitFormEditAction => 'تعديل';

  @override
  String get benefitDigitalCardSection => 'البطاقة الرقمية';

  @override
  String get benefitDigitalCardPreviewAction => 'معاينة البطاقة الرقمية';

  @override
  String get benefitDigitalCardPreviewTitle => 'معاينة البطاقة الرقمية';

  @override
  String get benefitDigitalCardPreviewNote =>
      'هكذا ستظهر البطاقة تمامًا في محفظة الطالب.';

  @override
  String get benefitCardSampleStudent => 'اسم الطالب';

  @override
  String get benefitCardStudentLabel => 'حامل البطاقة';

  @override
  String notificationEventPending(String title) {
    return '\"$title\" بانتظار موافقتك';
  }

  @override
  String get notificationEventPendingGeneric => 'هناك فعالية بانتظار موافقتك';

  @override
  String get eventProfileOrganizerLabel => 'المنظّم';

  @override
  String get eventProfilePointsLabel => 'النقاط الممنوحة';

  @override
  String get eventProfileDescriptionLabel => 'وصف الفعالية';

  @override
  String get eventProfileLocationLabel => 'الموقع';

  @override
  String get eventProfileScheduleLabel => 'التاريخ والوقت';

  @override
  String get eventProfileOrganizerDescriptionLabel => 'عن المنظّم';

  @override
  String get eventProfileExternalLinkLabel => 'رابط خارجي';

  @override
  String get eventProfileCategoryLabel => 'الفئة';

  @override
  String get eventProfileSessionsLabel => 'جلسات البرنامج';

  @override
  String get eventProfileSessionColumn => 'الجلسة';

  @override
  String get eventProfileWhenColumn => 'الموعد';

  @override
  String get eventProfileWhereColumn => 'المكان';

  @override
  String get eventProfileStatusColumn => 'الحالة';

  @override
  String get eventProfileSessionMissed => 'فاتتك';

  @override
  String get eventProfileSessionUpcoming => 'قادم';

  @override
  String eventProfileTotalPoints(int points) {
    return '$points نقطة لإكمال البرنامج';
  }

  @override
  String eventProfileSessionCount(int count) {
    return '$count جلسات';
  }

  @override
  String eventProfilePerSessionPoints(int points) {
    return '$points نقطة لكل جلسة';
  }

  @override
  String get eventProfileReviewTitle => 'مراجعة الفعالية';

  @override
  String get eventFormImageLabel => 'صورة الفعالية';

  @override
  String notificationEventPublished(String title) {
    return 'فعالية جديدة: $title';
  }

  @override
  String get notificationEventPublishedGeneric => 'تم نشر فعالية جديدة';

  @override
  String notificationBenefitPublished(String title) {
    return 'ميزة جديدة: $title';
  }

  @override
  String get notificationBenefitPublishedGeneric => 'تتوفر ميزة جديدة';

  @override
  String get notificationReportSubmitted => 'تم تقديم بلاغ جديد';

  @override
  String notificationEventApproved(String title) {
    return 'تمت الموافقة على \"$title\"';
  }

  @override
  String get notificationEventApprovedGeneric => 'تمت الموافقة على فعاليتك';

  @override
  String notificationEventRejected(String title) {
    return 'تم رفض \"$title\"';
  }

  @override
  String notificationEventRejectedWithReason(String title, String reason) {
    return 'تم رفض \"$title\": $reason';
  }

  @override
  String get notificationEventRejectedGeneric => 'تم رفض فعاليتك';

  @override
  String get notificationGroupMeetingPending =>
      'هناك لقاء جماعي بانتظار الموافقة';

  @override
  String notificationBenefitRedeemed(String title) {
    return 'تهانينا! تم استبدال الميزة ($title) بنجاح.';
  }

  @override
  String get notificationBenefitRedeemedGeneric =>
      'تهانينا! تم استبدال ميزتك بنجاح.';

  @override
  String notificationSurveyPublished(String title) {
    return 'استطلاع جديد: $title';
  }

  @override
  String get notificationSurveyPublishedGeneric => 'يتوفر استطلاع جديد';

  @override
  String get scanStudentIdLabel => 'رقم الطالب (أظهره لمنظّم الفعالية)';

  @override
  String get scanStudentIdCopied => 'تم نسخ رقم الطالب';

  @override
  String get attendanceManualTitle => 'التأكيد برقم الطالب';

  @override
  String get attendanceManualHint => 'أدخل رقم الطالب';

  @override
  String get attendanceManualAction => 'تأكيد الحضور';

  @override
  String get attendanceManualLookupError => 'لا يوجد طالب بهذا الرقم';

  @override
  String get attendanceManualConfirmTitle => 'تأكيد الحضور';

  @override
  String attendanceManualConfirmMessage(String name) {
    return 'هل تريد تسجيل حضور $name؟';
  }

  @override
  String attendanceManualSuccess(String name) {
    return 'تم تسجيل حضور $name';
  }

  @override
  String get optionNoTranslations => 'لا توجد ترجمات — سيظهر بالإنجليزية';

  @override
  String get optionEditTranslations => 'تعديل الترجمات';

  @override
  String get optionLabelArabic => 'التسمية بالعربية';

  @override
  String get optionLabelHebrew => 'التسمية بالعبرية';

  @override
  String get actionSave => 'حفظ';

  @override
  String get championsRewardsTitle => 'جوائز الشهر';

  @override
  String championsRewardFirst(int points) {
    return '🥇 المركز الأول: $points نقطة';
  }

  @override
  String championsRewardSecond(int points) {
    return '🥈 المركز الثاني: $points نقطة';
  }

  @override
  String championsRewardThird(int points) {
    return '🥉 المركز الثالث: $points نقطة';
  }

  @override
  String get legalPrivacyTitle => 'سياسة الخصوصية';

  @override
  String get legalTermsTitle => 'الشروط والأحكام';

  @override
  String get legalEditAction => 'تعديل';

  @override
  String get legalTitleLabel => 'العنوان';

  @override
  String get legalBodyLabel => 'المحتوى';

  @override
  String get legalLoadError => 'تعذر تحميل هذا المستند.';

  @override
  String get legalSaveError => 'تعذر الحفظ. حاول مرة أخرى.';

  @override
  String get legalEditDenied => 'يمكن للمشرف الأعلى فقط تعديل هذا.';

  @override
  String get legalEmpty => 'لم تتم كتابة هذا المستند بعد.';

  @override
  String get profilePhotoRemove => 'إزالة الصورة';

  @override
  String get meetingInProgressTitle => 'الاجتماع جارٍ';

  @override
  String get meetingWithLabel => 'مع';

  @override
  String get meetingYourQrTitle => 'رمز QR الخاص بك';

  @override
  String get meetingScanOtherTitle => 'امسح رمز QR للطالب الآخر';

  @override
  String get meetingQrRotatingHint => 'يتم تحديث هذا الرمز كل 10 ثوانٍ';

  @override
  String get meetingSectionDone => 'تم';

  @override
  String get meetingBothActionsHint =>
      'أكمل الإجراءين لتأكيد الاجتماع وكسب النقاط.';

  @override
  String get meetingScanOwnCode => 'هذا رمزك الخاص';

  @override
  String get meetingScanExpired => 'انتهت صلاحية الرمز — اطلب عرضه مجددًا';

  @override
  String get meetingScanError => 'تعذر المسح. حاول مرة أخرى.';

  @override
  String meetingCompletedPoints(int points) {
    return 'تم تأكيد الاجتماع! حصلت على $points نقطة.';
  }

  @override
  String get meetingCompletedNoPoints =>
      'تم تأكيد الاجتماع! (لا نقاط — التقيتما اليوم بالفعل.)';

  @override
  String get meetingOpenAction => 'فتح الاجتماع';

  @override
  String get meetingNotYetOpen =>
      'هل أنت مستعد للتواصل؟ تحقق مرة أخرى في الموعد المحدد.';

  @override
  String get meetingWindowEnded => 'انتهت فترة هذا الاجتماع';

  @override
  String get myEventsMeetingsTitle => 'الاجتماعات';

  @override
  String get meetingCardCompleted => 'مكتمل';

  @override
  String get meetingAttendedMessage => 'رائع! يسعدنا أنكما تواصلتما.';

  @override
  String get meetingMissedMessage =>
      'لقد فاتك هذا اللقاء. لا بأس — يمكنك جدولة لقاء آخر في أي وقت.';

  @override
  String meetingCardWith(String name) {
    return 'اجتماع مع $name';
  }

  @override
  String get passwordShow => 'إظهار كلمة المرور';

  @override
  String get passwordHide => 'إخفاء كلمة المرور';

  @override
  String get benefitFormSubmitError => 'تعذر حفظ هذه الميزة.';

  @override
  String monthAnnouncementTitle(String month) {
    return 'أبطال $month';
  }

  @override
  String get monthAnnouncementBody =>
      'تم الإعلان عن نتائج الشهر الماضي! إليك أفضل 3:';

  @override
  String get monthAnnouncementOk => 'موافق';

  @override
  String winnerBonusTitle(int rank) {
    return 'لقد حللت في المركز #$rank!';
  }

  @override
  String winnerBonusPoints(int points) {
    return 'أنهيت الشهر الماضي بـ $points نقطة.';
  }

  @override
  String winnerBonusAmount(int bonus) {
    return '+$bonus نقطة مكافأة';
  }

  @override
  String get winnerBonusOk => 'رائع!';

  @override
  String get accessibilityPanelTitle => 'إمكانية الوصول';

  @override
  String get accessibilityFloatingToggle => 'زر إمكانية الوصول العائم';

  @override
  String get accessibilityFloatingRemovedHint =>
      'تم إخفاء زر إمكانية الوصول. يمكنك تفعيله من الإعدادات.';

  @override
  String get actionRemove => 'إزالة';

  @override
  String get accessibilityTextSizeLabel => 'حجم النص';

  @override
  String get accessibilityTextSizeNormal => 'عادي';

  @override
  String get accessibilityTextSizeLarge => 'كبير';

  @override
  String get accessibilityTextSizeExtraLarge => 'كبير جدًا';

  @override
  String get accessibilityReduceMotionLabel => 'تقليل الحركة';

  @override
  String get accessibilityHighContrastLabel => 'تباين عالٍ';

  @override
  String get tutorialWelcomeTitle => 'مرحبًا بك في C2C – Connect to Collect';

  @override
  String get tutorialWelcomeBody =>
      'تواصل مع الطلاب، واستكشف جميع فعاليات الحرم الجامعي، واكسب نقاطًا، واستمتع بمكافآت حصرية.';

  @override
  String get tutorialMatchesTitle => 'اعثر على أصدقائك';

  @override
  String get tutorialMatchesBody =>
      'تصفّح الطلاب الذين يشاركونك الكلية والاهتمامات والهوايات، ثم راسلهم لتنظيم لقاء.';

  @override
  String get tutorialScanTitle => 'امسح لتكسب';

  @override
  String get tutorialScanBody =>
      'اعرض أو امسح رمز QR في اللقاءات والفعاليات لكسب النقاط تلقائيًا.';

  @override
  String get tutorialBenefitsTitle => 'استخدم نقاطك';

  @override
  String get tutorialBenefitsBody =>
      'استبدل النقاط بمزايا حقيقية من شركاء الحرم الجامعي في تبويب المزايا.';

  @override
  String get tutorialChampionsTitle => 'تسلّق لوحة الصدارة';

  @override
  String get tutorialChampionsBody =>
      'يفوز أفضل 3 طلاب كل شهر بمكافأة — تحقق من أبطال الشهر لترى مكانتك.';

  @override
  String get tutorialBackAction => 'رجوع';

  @override
  String get tutorialNextAction => 'التالي';

  @override
  String get tutorialGetStartedAction => 'لنبدأ';

  @override
  String get demoEventCheckInTitle => 'كيف تُحتسب نقاط الفعاليات';

  @override
  String get demoEventCheckInMessage =>
      'التسجيل في فعالية لا يمنحك نقاطًا تلقائيًا. عند وصولك، امسح رمز QR الخاص بالفعالية — أو اطلب من المضيف إدخال رقمك الجامعي — لتحصل على نقاطك.';

  @override
  String get demoMeetingStep1Title => 'رمز QR الخاص بك';

  @override
  String get demoMeetingStep1Message =>
      'أظهر هذا للطالب الآخر — يتجدد كل 10 ثوانٍ لأسباب أمنية.';

  @override
  String get demoMeetingStep2Title => 'امسح رمز QR الخاص بالطالب الآخر';

  @override
  String get demoMeetingStep2Message =>
      'امسح رمزه أيضًا. تُمنح النقاط فقط بعد أن يمسح كل منكما رمز الآخر.';

  @override
  String get demoGroupMeetingTitle => 'عن الاجتماعات الجماعية';

  @override
  String get demoGroupMeetingMessage =>
      'إذا كنتم مجموعة من 3 أشخاص أو أكثر وتريدون الالتقاء، يمكنكم إنشاء لقاء جماعي هنا. يحصل المنظّم على 25 نقطة عندما يقوم مشاركان آخران على الأقل بمسحه، ويحصل كل مشارك يقوم بالمسح على 15 نقطة.';

  @override
  String get demoBenefitsCatalogTitle => 'قبل أن تستبدل';

  @override
  String get demoBenefitsCatalogMessage =>
      'استبدال أي مكافأة يخصم نقاطك فورًا، ولا يمكنك الاحتفاظ إلا ببطاقة واحدة نشطة لكل مكافأة في الوقت نفسه.';

  @override
  String get demoDigitalCardTitle => 'استبدل هذه البطاقة';

  @override
  String get demoDigitalCardMessage =>
      'هذا هو الباركود لاستبدال الميزة. عند وصولك إلى المتجر، اعرضه على البائع للحصول على الميزة. انتبه: مسح الباركود والضغط على \"استبدال\" يؤدّيان إلى استبدال الميزة فورًا، بغضّ النظر عمّن قام بالمسح. لذلك لا تمسحوا الباركود بأنفسكم. اعرضوه للمسح فقط على البائع أو ممثّل المتجر الذي تُستبدل فيه الميزة.';

  @override
  String get demoMatchingTitle => 'نسبة التوافق';

  @override
  String get demoMatchingMessage =>
      'توضح هذه النسبة مدى تقارب اهتماماتك وكليتك ولغاتك مع الطالب الآخر. كلما ارتفعت النسبة، زادت القواسم المشتركة بينكما.';

  @override
  String get demoGuidedMatchTabTitle => 'اضغط هنا';

  @override
  String get demoGuidedMatchTabMessage =>
      'اضغط على تبويب المطابقة لرؤية طلاب يمكنك التواصل معهم.';

  @override
  String get demoGuidedViewProfileTitle => 'اضغط هنا';

  @override
  String get demoGuidedViewProfileMessage =>
      'اضغط على عرض الملف الشخصي للاطلاع على الملف الكامل للطالب.';

  @override
  String get demoProgramTitle => 'نقاط البرنامج';

  @override
  String get demoProgramMessage =>
      'تُمنح النقاط لكل جلسة على حدة — يجب تسجيل الحضور في كل جلسة بشكل مستقل لاحتسابها.';

  @override
  String get demoAccessibilityTitle => 'اختصار إمكانية الوصول';

  @override
  String get demoAccessibilityMessage =>
      'يمكنك سحب هذا الزر إلى أي مكان على الشاشة. اسحبه إلى أسفل الشاشة لإخفائه. يمكنك تفعيله مرة أخرى من الإعدادات.';

  @override
  String get demoChampionsTitle => 'أبطال الشهر';

  @override
  String get demoChampionsMessage =>
      'يعرض هذا الترتيب النقاط المكتسبة هذا الشهر فقط، ويُعاد ضبطه في اليوم الأول من كل شهر. تُظهر لك بطاقة ترتيبك موقعك بدقة.';

  @override
  String get demoReportUserTitle => 'الإبلاغ عن مستخدم';

  @override
  String get demoReportUserMessage =>
      'من المهم أن تعرفوا هذا الخيار: إذا تصرّف مستخدم بشكل غير لائق، أو جعلكم تشعرون بعدم الارتياح، أو كانت هناك مشكلة يجب أن يعرف بها فريقنا، يمكنكم الإبلاغ عنه هنا. سيتم إرسال البلاغ إلى فريق النظام للمراجعة والمعالجة.';

  @override
  String get settingsHelpSectionTitle => 'المساعدة والدروس التعريفية';

  @override
  String get settingsReplayIntroAction => 'إعادة عرض مقدمة التطبيق';

  @override
  String get settingsReplayTutorialsAction => 'إعادة عرض الدروس التوضيحية';

  @override
  String get settingsReplayTutorialsToast =>
      'تمت إعادة ضبط الدروس التوضيحية — ستظهر لك مرة أخرى أثناء استخدام التطبيق.';

  @override
  String get profileLoadError => 'تعذر تحميل ملفك الشخصي.';

  @override
  String get profileAboutTitle => 'نبذة عني';

  @override
  String get profileAboutEmpty => 'لم تقم بإضافة نبذة بعد.';

  @override
  String get profileInterestsLabel => 'الاهتمامات';

  @override
  String get profileInterestsEmpty => 'لم تقم بإضافة أي اهتمامات بعد';

  @override
  String get profileLanguagesTitle => 'اللغات';

  @override
  String get profileLanguagesEmpty => 'لم تقم بإضافة أي لغات بعد';

  @override
  String get profileStudiesTitle => 'الدراسة';

  @override
  String get profileFacultyLabel => 'الكلية';

  @override
  String get profileFieldOfStudyLabel => 'مجال الدراسة';

  @override
  String get searchableFieldMultipleHint => 'يمكنك اختيار أكثر من عنصر';

  @override
  String get searchableFieldPlaceholder => 'اضغط للاختيار';

  @override
  String get searchableFieldSearchHint => 'بحث';

  @override
  String get searchableFieldNoMatches => 'لا توجد نتائج';

  @override
  String get searchableFieldDone => 'تم';

  @override
  String get profileGenderLabel => 'الجنس';

  @override
  String get genderMale => 'ذكر';

  @override
  String get genderFemale => 'أنثى';

  @override
  String get genderUndisclosed => 'أفضّل عدم الإفصاح';

  @override
  String get profilePhotoLabel => 'صورة الملف الشخصي';

  @override
  String get profilePhotoChange => 'تغيير الصورة';

  @override
  String get profilePhotoAdd => 'إضافة صورة';

  @override
  String get profilePhotoUploadError => 'تعذّر رفع الصورة. حاول مرة أخرى.';

  @override
  String get profileBioHint => 'أخبر الطلاب الآخرين قليلاً عن نفسك';

  @override
  String get profileOptionsLoadError => 'تعذّر تحميل الخيارات.';

  @override
  String get profileOptionsEmpty => 'لا توجد خيارات متاحة بعد.';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get errorSelectFieldOfStudy => 'يرجى اختيار مجال دراسة واحد على الأقل';

  @override
  String get profileDegreeLabel => 'الدرجة العلمية';

  @override
  String get profileYearLabel => 'سنة الدراسة';

  @override
  String profileYearShort(int year) {
    return 'السنة $year';
  }

  @override
  String get profileEditAction => 'تعديل الملف الشخصي';

  @override
  String get profileSettingsTitle => 'الإعدادات';

  @override
  String get profileLanguageLabel => 'اللغة';

  @override
  String get profilePolicyLabel => 'السياسة وشروط الاستخدام';

  @override
  String get profileLogoutAction => 'تسجيل الخروج';

  @override
  String get profileDeleteAccountAction => 'حذف الحساب';

  @override
  String get profileDeleteAccountConfirmTitle => 'حذف حسابك؟';

  @override
  String get profileDeleteAccountConfirmMessage =>
      'بعد طلب حذف الحساب، سيتم تعطيل حسابك لمدة 30 يومًا. في نهاية هذه الفترة سيتم حذف الحساب نهائيًا. إذا سجّلت الدخول إلى التطبيق خلال الـ 30 يومًا، فسيتم إلغاء طلب الحذف وسيبقى حسابك نشطًا.';

  @override
  String get profileDeleteAccountConfirmAction => 'طلب الحذف';

  @override
  String get profileDeleteAccountInProgress => 'جارٍ إرسال طلب الحذف…';

  @override
  String get profileDeleteAccountError =>
      'لم نتمكن من إرسال طلب الحذف. يُرجى المحاولة مرة أخرى أو التواصل مع الدعم.';

  @override
  String get profileLogoutConfirmTitle => 'تسجيل الخروج من حسابك؟';

  @override
  String profileAppVersion(String version) {
    return 'C2C إصدار التطبيق $version';
  }

  @override
  String get profileEditTitle => 'تعديل الملف الشخصي';

  @override
  String get profileEditError => 'تعذر حفظ ملفك الشخصي.';

  @override
  String get profileSaveAction => 'حفظ التغييرات';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsLoadError => 'تعذر تحميل إشعاراتك.';

  @override
  String get notificationsEmpty => 'ليس لديك أي إشعارات بعد.';

  @override
  String notificationsSelectedCount(Object count) {
    return 'تم تحديد $count';
  }

  @override
  String get notificationsSelectAll => 'تحديد الكل';

  @override
  String get notificationsMarkRead => 'وضع علامة كمقروء';

  @override
  String get notificationsMarkUnread => 'وضع علامة كغير مقروء';

  @override
  String get notificationsDeleteAction => 'حذف';

  @override
  String get notificationsClearAll => 'مسح الكل';

  @override
  String get notificationsDeleteConfirmTitle => 'حذف الإشعارات؟';

  @override
  String notificationsDeleteConfirmMessage(Object count) {
    return 'سيؤدي هذا إلى حذف $count إشعار نهائيًا. لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get notificationsClearAllConfirmTitle => 'مسح جميع الإشعارات؟';

  @override
  String get notificationsClearAllConfirmMessage =>
      'سيؤدي هذا إلى حذف جميع إشعاراتك نهائيًا. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get notificationTargetLoadError =>
      'تعذر فتح هذا العنصر — قد لا يكون متاحًا بعد الآن.';

  @override
  String notificationPointsEarned(int points) {
    return 'حصلت على $points نقطة';
  }

  @override
  String notificationPointsEarnedWithTitle(int points, String title) {
    return 'حصلت على $points نقطة – $title';
  }

  @override
  String notificationNewMessage(String name) {
    return 'رسالة جديدة من $name';
  }

  @override
  String notificationMeetingProposal(String time) {
    return 'اقتراح جديد: لقاء في $time';
  }

  @override
  String get notificationMeetingProposalGeneric => 'اقتراح لقاء جديد';

  @override
  String get notificationGeneric => 'إشعار جديد';

  @override
  String get surveysTitle => 'الاستبيانات';

  @override
  String get homeSurveysSection => 'استبيانات متاحة';

  @override
  String get homeSurveysBannerCta => 'أكمل استبيانًا قصيرًا واحصل على نقاط!';

  @override
  String get surveysTabActive => 'استبيانات نشطة';

  @override
  String get surveysTabCompleted => 'استبيانات مكتملة';

  @override
  String get surveysFilterPending => 'قيد الانتظار';

  @override
  String get surveysFilterCompleted => 'مكتملة';

  @override
  String get surveysFilterIncoming => 'قادمة';

  @override
  String get surveysEmptyPending => 'لا توجد استبيانات بانتظارك الآن.';

  @override
  String get surveysEmptyCompleted => 'لم تكمل أي استبيان بعد.';

  @override
  String get surveysEmptyIncoming => 'لا توجد استبيانات قادمة مجدولة.';

  @override
  String get surveysLoadError => 'تعذر تحميل الاستبيانات.';

  @override
  String get surveysEndsToday => 'تنتهي اليوم';

  @override
  String surveysEndsInDays(int days) {
    return 'تنتهي خلال $days يوم';
  }

  @override
  String get surveyStartAction => 'ابدأ الاستبيان';

  @override
  String surveyPointsLabel(int points) {
    return '$points نقطة';
  }

  @override
  String get surveySubmitAction => 'إرسال';

  @override
  String surveySubmitSuccess(int points) {
    return 'حصلت على $points نقطة!';
  }

  @override
  String get surveySubmitErrorGeneric => 'تعذر إرسال إجاباتك. حاول مرة أخرى.';

  @override
  String get surveySubmitErrorAlreadyAnswered =>
      'لقد أكملت هذا الاستبيان بالفعل.';

  @override
  String get surveySubmitErrorClosed => 'هذا الاستبيان مغلق.';

  @override
  String get surveySubmitErrorNotYetOpen => 'هذا الاستبيان غير متاح بعد.';

  @override
  String get surveyDetailLoadError => 'تعذر تحميل هذا الاستبيان.';

  @override
  String get surveyTextAnswerHint => 'اكتب إجابتك';

  @override
  String get surveyTextAnswerRequired =>
      'Please answer every question before submitting.';

  @override
  String get tourIntroTitle => 'رائع، تم تسجيل دخولكم بنجاح!';

  @override
  String get tourIntroDescription =>
      'الآن سنعرّفكم باختصار على التطبيق وعلى أهم الأزرار والخيارات الموجودة فيه.';

  @override
  String get tourNextAction => 'التالي';

  @override
  String get tourMyEventsTitle => 'فعالياتي';

  @override
  String get tourMyEventsDescription =>
      'هنا يمكنكم مشاهدة الفعاليات التي سجلتم فيها، والاجتماعات التي حددتموها مع طلاب آخرين، ومتابعة مشاركتكم.';

  @override
  String get tourPointsTitle => 'نقاطي';

  @override
  String get tourPointsDescription =>
      'هذا هو عدد النقاط التي جمعتموها حتى الآن. يمكنكم جمع النقاط من خلال المشاركة في الفعاليات، والاجتماعات مع طلاب آخرين، وأنشطة إضافية في التطبيق، ثم استخدامها للحصول على المزايا.';

  @override
  String get tourChampionsTitle => 'أبطال الشهر';

  @override
  String get tourChampionsDescription =>
      'اجمعوا النقاط، تقدّموا في الترتيب ووصلوا إلى القمة! هنا يمكنكم متابعة ترتيبكم ومعرفة من يتصدر الترتيب الشهري. في نهاية كل شهر، يحصل الطلاب الثلاثة الذين جمعوا أكبر عدد من النقاط على نقاط إضافية.';

  @override
  String get tourSurveysTitle => 'الاستبيانات';

  @override
  String get tourSurveysDescription =>
      'شاركونا آراءكم واجمعوا النقاط أيضًا! ستظهر هنا استبيانات قصيرة يمكنكم الإجابة عنها بسهولة، وستحصلون على نقاط مقابل كل استبيان تكملونه.';

  @override
  String get tourAccessibilityTitle => 'زر إمكانية الوصول';

  @override
  String get tourAccessibilityDescription =>
      'من هنا يمكنكم فتح خيارات إمكانية الوصول وتخصيص عرض التطبيق بما يناسب احتياجاتكم. يمكن تحريك زر إمكانية الوصول إلى أي مكان مريح على الشاشة، كما يمكن إزالته أو إعادته في أي وقت من إعدادات التطبيق.';

  @override
  String get tourMatchesNavTitle => 'تعارف';

  @override
  String get tourMatchesNavDescription =>
      'تعرّفوا على الطلاب من حولكم في الحرم الجامعي، واكتشفوا ما يجمع بينكم وحددوا موعدًا للقاء في الحرم الجامعي! التقيتم؟ امسحوا رموز بعضكم البعض خلال اللقاء واجمعوا النقاط معًا. اضغطوا هنا للمتابعة.';

  @override
  String get tourScanNavTitle => 'المسح';

  @override
  String get tourBenefitsNavTitle => 'المزايا';

  @override
  String get tourTapToContinue => 'اضغطوا على الزر المحدد للمتابعة.';

  @override
  String get tourCompatibilityTitle => 'نسبة التوافق';

  @override
  String get tourCompatibilityDescription =>
      'تظهر بجانب كل طالب نسبة توافق تُحسب وفق الأمور المشتركة بينكم، مثل مجالات الدراسة والاهتمامات واللغات. كلما ارتفعت النسبة، زادت الصفات المشتركة بينكم.';

  @override
  String get tourChatTitle => 'المحادثة / Chat';

  @override
  String get tourChatDescription =>
      'هنا يمكنكم التحدث والتعرّف على طلاب آخرين. من خلال زر (+) في المحادثة يمكنكم تحديد موعد لقاء بينكم، وسيُحفظ في «فعالياتي». أثناء اللقاء ستظهر إمكانية لمسح رمز كل منكما لتأكيد أن اللقاء تم، وبعد التأكيد ستحصلون على نقاط اللقاء.';

  @override
  String get tourStudentProfileTitle => 'الملف الشخصي';

  @override
  String get tourStudentProfileDescription =>
      'هنا يمكنكم التعرّف على الطالب بشكل أفضل والاطّلاع على المعلومات التي اختار مشاركتها في ملفه الشخصي، مثل مجال الدراسة واللغات والاهتمامات ومعلومات إضافية عنه.';

  @override
  String get tourReportTitle => 'الإبلاغ عن مستخدم';

  @override
  String get tourReportDescription =>
      'من المهم أن تعرفوا هذه الإمكانية: إذا تصرف مستخدم بطريقة غير لائقة، أو جعلكم تشعرون بعدم الارتياح، أو كانت هناك مشكلة من المهم أن يعرف بها فريقنا، يمكنكم الإبلاغ عنه من هنا. سيُرسل البلاغ إلى فريق النظام لفحصه ومعالجته.';

  @override
  String get tourScanCameraTitle => 'مسح QR للفعالية';

  @override
  String get tourScanCameraDescription =>
      'وصلتم إلى فعالية؟ امسحوا رمز QR هنا لتأكيد مشاركتكم والحصول على النقاط. هذه الكاميرا مخصصة لمسح رموز الفعاليات فقط. أما اللقاءات مع الطلاب فلها مسح منفصل يُفتح تلقائيًا داخل اللقاء في الموعد المحدد. يمكنكم العثور على اللقاءات التي حددتموها في «فعالياتي».';

  @override
  String get tourStudentIdTitle => 'رقم الطالب';

  @override
  String get tourStudentIdDescription =>
      'هذا هو رقم التعريف الشخصي الخاص بكم في التطبيق. إذا فاتكم مسح رمز QR في فعالية أو حدثت مشكلة في المسح، يمكنكم إعطاء الرقم لمضيف الفعالية ليضيفكم يدويًا.';

  @override
  String get tourBenefitsPageTitle => 'صفحة المزايا';

  @override
  String get tourBenefitsPageDescription =>
      'حان الوقت للاستفادة من النقاط التي جمعتموها! هنا يمكنكم مشاهدة المزايا المتاحة، قراءة تفاصيل كل ميزة، معرفة عدد النقاط المطلوبة للحصول عليها، واختيار الميزة التي ترغبون في استخدامها.';

  @override
  String get tourWalletTitle => 'محفظتي';

  @override
  String get tourTapWalletDescription => 'اضغطوا على زر المحفظة للمتابعة.';

  @override
  String get tourWalletDescription =>
      'كل ميزة قمتم باستبدال نقاطكم بها ستكون بانتظاركم هنا. في المحفظة يمكنكم العثور على المزايا التي اخترتم الحصول عليها والوصول إلى البطاقة الرقمية لكل منها. عند الوصول إلى المحل، اعرضوا البطاقة الرقمية واستمتعوا بالميزة.';

  @override
  String get tourProfileTitle => 'الملف الشخصي';

  @override
  String get tourProfileDescription =>
      'هذا هو ملفكم الشخصي في C2C. هنا يمكنكم مشاهدة وتحديث التفاصيل التي ترغبون أن يعرفها الطلاب الآخرون عنكم. كما يمكنكم تعديل لغة التطبيق وزر إمكانية الوصول، ومشاهدة الاستبيانات المفتوحة وشروط الاستخدام ضمن الإعدادات في الأسفل.';

  @override
  String get tourReplayAction => 'عرض الإرشادات مرة أخرى';

  @override
  String get surveyAnswerRequired =>
      'يرجى الإجابة على جميع الأسئلة قبل الإرسال.';

  @override
  String get tourProfileButtonTitle => 'الملف الشخصي';

  @override
  String get tourProfileButtonDescription =>
      'هنا يمكنكم التعرّف على الطالب بشكل أفضل والاطّلاع على المعلومات التي اختار مشاركتها في ملفه الشخصي، مثل مجال الدراسة، اللغات، الاهتمامات ومعلومات إضافية عنه.';

  @override
  String get demoChatBlockTitle => 'حظر مستخدم';

  @override
  String get demoChatBlockMessage =>
      'من هنا يمكنكم حظر المستخدم. بعد الحظر، لن يتمكّن من إرسال رسائل إليكم ولن تتمكّنوا من إرسال رسائل إليه. يمكنكم الحظر وإلغاء الحظر في أي وقت بالضغط على الزر.';

  @override
  String get demoChatMeetingTitle => 'تحديد لقاء';

  @override
  String get demoChatMeetingMessage =>
      'من هنا يمكنكم تحديد موعد لقاء مع الطالب/ة الذي تتحدّثون معه. حدّدوا موعدًا، والتقوا داخل الجامعة، واجمعوا النقاط معًا! اللقاء الأول مع طالب/ة جديد/ة يمنح كلًّا منكم 25 نقطة، واللقاء الثاني مع الطالب/ة نفسه 20 نقطة، واللقاء الثالث 10 نقاط. انتبهوا: يمكن تحديد لقاء واحد في اليوم مع الطالب/ة نفسه، وحتى 5 لقاءات مع طلاب مختلفين في اليوم نفسه.';

  @override
  String get tourBenefitsStatusTitle => 'حالتي';

  @override
  String get tourBenefitsStatusDescription =>
      'هنا يمكنكم رؤية رصيد النقاط، التقدم نحو الميزة التالية، واختصارًا إلى المحفظة الرقمية.';

  @override
  String get tourWalletTapDescription =>
      'تحتفظ المحفظة الرقمية بالميزات التي قمتم باستبدالها. اضغطوا على «محفظتي» في الأعلى أو على زر المحفظة لفتحها.';

  @override
  String get tourMatchesIntroTitle => 'التعرّف على طلاب';

  @override
  String get tourMatchesIntroDescription =>
      'هنا يمكنكم العثور على طلاب للتعرّف عليهم، ورؤية نسبة التوافق بينكم، والتحدث معهم وتنسيق لقاء فردي عبر التطبيق.';

  @override
  String get externalLinkOpenFailedCopied =>
      'لا يمكن فتح الرابط — تم نسخه إلى الحافظة بدلاً من ذلك.';

  @override
  String get homeEventsNextMonth => 'أحداث الشهر القادم';

  @override
  String get homeEmptyEventsNextMonth =>
      'لا توجد أحداث في الشهر القادم حالياً.';

  @override
  String get eventFullNotice =>
      'الفعالية مكتملة العدد. إذا توفرت أماكن إضافية، سيُعاد فتح التسجيل هنا.';

  @override
  String get eventFullAction => 'مكتملة العدد';

  @override
  String get tourEventsNextMonthTitle => 'أحداث الشهر القادم';

  @override
  String get tourEventsNextMonthDescription =>
      'يعرض هذا القسم الفعاليات التي تقام خلال الشهر القادم فقط — نظرة سريعة على ما سيحدث قريباً.';

  @override
  String get tourUpcomingEventsTitle => 'كل الفعاليات';

  @override
  String get tourUpcomingEventsDescription =>
      'يعرض هذا القسم جميع الفعاليات المفتوحة للتسجيل حالياً، مهما كان موعدها — بما في ذلك فعاليات تقام بعد أكثر من شهر. اضغطوا على فعالية لقراءة التفاصيل والتسجيل.';

  @override
  String get authSpamFolderNote =>
      'إذا لم تجد البريد الإلكتروني في صندوق الوارد، يُرجى التحقق من مجلد الرسائل غير المرغوب فيها.';

  @override
  String get errorSelectFaculty => 'يُرجى اختيار الكلية';

  @override
  String get errorSelectDegree => 'يُرجى اختيار نوع الدرجة';

  @override
  String get errorSelectGender => 'يُرجى اختيار الجنس';

  @override
  String get errorSelectYearOfStudy => 'يُرجى اختيار سنة الدراسة';

  @override
  String get profileRequiredFieldsMissing =>
      'يُرجى إكمال جميع الحقول المطلوبة قبل المتابعة.';

  @override
  String get eventShareAction => 'مشاركة الحدث';

  @override
  String get eventShareCopyLink => 'نسخ الرابط';

  @override
  String get eventShareViaApps => 'المشاركة عبر…';

  @override
  String get eventShareLinkCopied => 'تم نسخ الرابط.';

  @override
  String get eventShareFailed =>
      'لم نتمكن من مشاركة الحدث. يُرجى المحاولة مرة أخرى.';

  @override
  String eventShareMessage(String title) {
    return '$title — شاهد الحدث في تطبيق C2C:';
  }

  @override
  String get eventNotFoundTitle => 'الحدث غير متاح';

  @override
  String get eventNotFoundMessage =>
      'هذا الحدث لم يعد موجودًا، أو أنه غير متاح لحسابك.';

  @override
  String get proposeMeetingRespondError =>
      'لم نتمكن من تحديث الموعد. يُرجى المحاولة مرة أخرى.';

  @override
  String get proposeMeetingAlreadyResponded =>
      'تم الرد على طلب الموعد هذا بالفعل.';

  @override
  String notificationEventReminderTomorrow(String title) {
    return 'غدًا: $title';
  }

  @override
  String get notificationEventReminderTomorrowGeneric => 'لديك حدث غدًا';

  @override
  String notificationEventReminderToday(String title) {
    return 'اليوم: $title';
  }

  @override
  String get notificationEventReminderTodayGeneric => 'لديك حدث اليوم';

  @override
  String get eventReminderPopupTitleTomorrow => 'حدثك غدًا';

  @override
  String get eventReminderPopupTitleToday => 'حدثك اليوم';

  @override
  String get eventReminderPopupLocationLabel => 'المكان';

  @override
  String get eventReminderPopupStartLabel => 'يبدأ';

  @override
  String get eventReminderPopupEndLabel => 'ينتهي';

  @override
  String get eventReminderPopupDismiss => 'حسنًا';

  @override
  String get eventReminderPopupOpenEvent => 'عرض الحدث';

  @override
  String get programPendingApprovalStatus =>
      'تم إرسال طلب تسجيلك. سنُعلمك هنا عند قبولك في الفعالية.';

  @override
  String get programAcceptedStatus => 'تم قبولك بنجاح';

  @override
  String get profileFullNameWarning =>
      'يُرجى الانتباه: يجب إدخال اسمك الكامل. هذا هو الاسم الذي سيظهر لمنظمي الفعاليات، لذا لا تستخدم الألقاب بل اسمك الكامل.';

  @override
  String get registerPendingApproval =>
      'تم إرسال طلب تسجيلك وهو بانتظار الموافقة.';

  @override
  String get eventPendingApprovalLabel => 'بانتظار الموافقة';
}
