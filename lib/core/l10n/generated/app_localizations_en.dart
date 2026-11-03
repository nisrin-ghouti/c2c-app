// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'C2C';

  @override
  String get languageSelectionTitle => 'Choose your language';

  @override
  String get languageSelectionSubtitle =>
      'You can change this later from Settings.';

  @override
  String get languageContinue => 'Continue';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get welcomeSubtitle => 'Your campus, connected.';

  @override
  String get tabSignup => 'Sign up';

  @override
  String get tabLogin => 'Log in';

  @override
  String get methodPassword => 'Sign in with password';

  @override
  String get methodOtp => 'Sign in with email code';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get fieldEmail => 'Email';

  @override
  String emailHint(String domain) {
    return 'you@$domain';
  }

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordSignupHint => 'Password (min. 8 characters)';

  @override
  String get fieldConfirmPassword => 'Confirm password';

  @override
  String get buttonLogin => 'Log in';

  @override
  String get buttonSendCode => 'Send me a verification code';

  @override
  String get buttonCreateAccount => 'Create account';

  @override
  String get linkForgotPassword => 'Forgot password';

  @override
  String domainNote(String domain) {
    return 'Registration is only allowed with a $domain email address.';
  }

  @override
  String errorDomainNotAllowed(String domain) {
    return 'Only $domain emails are allowed';
  }

  @override
  String get errorEnterEmail => 'Enter your email';

  @override
  String get errorEnterFirstName => 'Enter your first name';

  @override
  String get errorEnterLastName => 'Enter your last name';

  @override
  String get errorEnterPassword => 'Enter a password';

  @override
  String get errorPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get errorPasswordsDontMatch => 'Passwords do not match';

  @override
  String get errorInvalidCredentials => 'Incorrect email or password';

  @override
  String get errorEmailNotConfirmedSendingCode =>
      'Please verify your email before logging in. Sending a code…';

  @override
  String get errorUserAlreadyExists =>
      'An account with this email already exists — try logging in';

  @override
  String get errorUserNotFound =>
      'No account found with this email — sign up first';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get verifyTitle => 'Verify your email';

  @override
  String get verifySubtitle =>
      'We sent a 6-digit code to your email address. Enter it below to continue.';

  @override
  String get otpHint => '000000';

  @override
  String get errorInvalidOtp => 'Enter the 6-digit code';

  @override
  String get errorOtpIncorrect => 'The code is incorrect or has expired.';

  @override
  String get errorBlockedUser =>
      'This account has been blocked by C2C management due to a violation of the Terms of Use.';

  @override
  String get actionClose => 'Close';

  @override
  String get buttonVerify => 'Verify & continue';

  @override
  String get linkResend => 'Didn\'t get a code? Resend';

  @override
  String linkResendIn(int seconds) {
    return 'Resend available in ${seconds}s';
  }

  @override
  String get infoResent => 'A new code was sent to your email.';

  @override
  String get linkBackToLogin => 'Back to login';

  @override
  String get forgotTitle => 'Password recovery';

  @override
  String get forgotSubtitle => 'We\'ll send a reset link to your email.';

  @override
  String get buttonSendResetLink => 'Send reset link';

  @override
  String get infoResetLinkSent =>
      'We\'ve sent a password reset link to your email.';

  @override
  String get errorEnterUniversityEmail => 'Enter a valid email address';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get fieldNewPasswordHint => 'New password (min. 8 characters)';

  @override
  String get buttonUpdatePassword => 'Update password';

  @override
  String get infoPasswordUpdated =>
      'Password updated. Redirecting you to the app…';

  @override
  String get resetLinkInactive =>
      'This reset link isn\'t active. Please request a new one from \"Forgot password\".';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileSubtitle =>
      'Just a few details before you get started.';

  @override
  String get fieldFacultyOptional => 'Faculty (optional)';

  @override
  String get fieldYearOptional => 'Year (optional)';

  @override
  String get buttonContinue => 'Continue';

  @override
  String get errorSaveProfileFailed =>
      'Could not save your profile. Please try again.';

  @override
  String get policyTitle => 'Policy & Terms of Use';

  @override
  String policyVersionLabel(int version) {
    return 'Version $version';
  }

  @override
  String get policyNoneActive => 'No active policy right now.';

  @override
  String get buttonAgree => 'I agree to the terms';

  @override
  String get buttonAlreadyAgreed => 'You already agreed';

  @override
  String get buttonContinueToApp => 'Continue to the app';

  @override
  String get errorLoadPolicyFailed => 'Could not load the policy.';

  @override
  String get errorAgreePolicyFailed =>
      'Could not save your agreement. Please try again.';

  @override
  String get restrictedAccessTitle => 'Access restricted';

  @override
  String get restrictedAccessMessage =>
      'This app is for students only. Your account doesn\'t have student access.';

  @override
  String homeSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get actionSignOut => 'Sign out';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeMyPoints => 'My points';

  @override
  String get homeHeroTitle => 'What\'s happening today on campus?';

  @override
  String get homeMonthlyChampions => 'Champions of the month';

  @override
  String get coachMarkNavHomeTitle => 'Home';

  @override
  String get coachMarkNavHomeDescription =>
      'Your dashboard — events, notifications, and what\'s new.';

  @override
  String get coachMarkNavMatchesTitle => 'Matches';

  @override
  String get coachMarkNavMatchesDescription =>
      'Discover and connect with fellow students.';

  @override
  String get coachMarkNavScanTitle => 'Scan';

  @override
  String get coachMarkNavScanDescription =>
      'Scan a QR code to check in or earn points.';

  @override
  String get coachMarkNavBenefitsTitle => 'Benefits';

  @override
  String get coachMarkNavBenefitsDescription =>
      'Redeem your points for partner perks.';

  @override
  String get coachMarkNavProfileTitle => 'Profile';

  @override
  String get coachMarkNavProfileDescription =>
      'Edit your profile and manage settings.';

  @override
  String get coachMarkMyEventsTitle => 'My Events';

  @override
  String get coachMarkMyEventsDescription =>
      'See the events and meetings you\'ve registered for.';

  @override
  String get coachMarkUpcomingEventsTitle => 'Upcoming Events';

  @override
  String get coachMarkUpcomingEventsDescription =>
      'Browse campus events happening soon.';

  @override
  String get coachMarkNotificationsTitle => 'Select Multiple';

  @override
  String get coachMarkNotificationsDescription =>
      'Long-press a notification to select multiple items and mark them as read, unread, or delete them together.';

  @override
  String get coachMarkChampionsTitle => 'Monthly Champions';

  @override
  String get coachMarkChampionsDescription =>
      'See this month\'s top point earners.';

  @override
  String get homeMyNotifications => 'My notifications';

  @override
  String get homeUpcomingEvents => 'All events';

  @override
  String get homeMyEventsCalendar => 'My events calendar';

  @override
  String get homeNewStudents => 'New students';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get actionSeeMore => 'See more';

  @override
  String get homeCampusEvents => 'Campus events';

  @override
  String get filterAll => 'All';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filtersClearAll => 'Clear all';

  @override
  String get filtersApply => 'Apply filters';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get eventUpcomingTag => 'Upcoming';

  @override
  String get eventRegisteredLabel => 'Registered';

  @override
  String get eventAttendedLabel => 'Attended';

  @override
  String get eventRegisterAction => 'Register';

  @override
  String eventPointsLabel(int points) {
    return '+$points pts';
  }

  @override
  String get homeEmptyEvents => 'No upcoming events right now.';

  @override
  String get homeEmptySurveys => 'No surveys available right now.';

  @override
  String get homeEmptyStudents => 'No new students right now.';

  @override
  String get homeLoadError => 'Could not load the home page. Please try again.';

  @override
  String get registerSuccess => 'You\'re registered!';

  @override
  String get registerErrorAlready =>
      'You\'re already registered for this event';

  @override
  String get registerErrorFull => 'This event is full';

  @override
  String get registerErrorEnded => 'This event has already ended';

  @override
  String get registerErrorNotPublished =>
      'This event isn\'t open for registration';

  @override
  String get registerErrorNotFound => 'Event not found';

  @override
  String get registerErrorGeneric => 'Couldn\'t register. Please try again.';

  @override
  String get deleteEventTitle => 'Delete event';

  @override
  String get deleteEventMessage =>
      'Are you sure you want to delete this event?';

  @override
  String get deleteEventConfirm => 'Delete';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get deleteEventSuccess => 'Event deleted.';

  @override
  String get deleteEventError =>
      'Couldn\'t delete the event. Please try again.';

  @override
  String get registrantsTitle => 'Registrants';

  @override
  String get registrantsEmpty => 'No one has registered yet.';

  @override
  String get registrantAttended => 'Attended';

  @override
  String get registrantRegisteredOnly => 'Registered';

  @override
  String get navProfile => 'Profile';

  @override
  String get navBenefits => 'Benefits';

  @override
  String get navScanning => 'Scan';

  @override
  String get navMatches => 'Matches';

  @override
  String get navHome => 'Home';

  @override
  String get matchesTitle => 'Matches';

  @override
  String get matchesEmpty => 'No other students yet.';

  @override
  String get matchesLoadError => 'Couldn\'t load matches. Please try again.';

  @override
  String get matchesConnectAction => 'Connect via QR';

  @override
  String get profileAboutLabel => 'About';

  @override
  String get profileLanguagesLabel => 'Languages';

  @override
  String get profileMessageAction => 'Message';

  @override
  String get profileViewAction => 'View profile';

  @override
  String get matchesSearchHint => 'Search by name, hobby, or language...';

  @override
  String get matchesFilterToggle => 'Filter';

  @override
  String get matchesSortToggle => 'Sort';

  @override
  String get matchesSortHighToLow => 'Compatibility: high to low';

  @override
  String get matchesSortLowToHigh => 'Compatibility: low to high';

  @override
  String matchesCompatibilityBadge(int percent) {
    return '$percent% match';
  }

  @override
  String matchesResultsCount(int count) {
    return '$count student matches';
  }

  @override
  String matchesYearInline(int year) {
    return 'Year $year';
  }

  @override
  String get matchesSendHelloAction => 'Send Hello';

  @override
  String get filterFacultyLabel => 'Faculty';

  @override
  String get filterFieldOfStudyLabel => 'Field of study';

  @override
  String get filterDegreeLabel => 'Degree';

  @override
  String get filterYearLabel => 'Year of study';

  @override
  String get filterLanguageLabel => 'Language';

  @override
  String get filterGenderLabel => 'Gender';

  @override
  String get scanningTitle => 'Scanning & Points';

  @override
  String get scanTabLabel => 'Scan / Enter code';

  @override
  String get scanCardTitle => 'Your Student ID';

  @override
  String get scanCardSubtitle =>
      'Show this to an event host if the QR code can\'t be scanned.';

  @override
  String get scanEventQrAction => 'Scan event QR';

  @override
  String get scanEventCameraTitle => 'Scan with your device camera';

  @override
  String get scanEventGenericSubtitle =>
      'Point your camera at the QR code — it\'ll be detected automatically.';

  @override
  String get scanCameraPermissionHint =>
      'If the camera doesn\'t open, allow camera access in your device settings.';

  @override
  String get scanAnotherAction => 'Scan another';

  @override
  String get scanEventQrPickerTitle => 'Which event?';

  @override
  String get scanEventQrEmpty =>
      'Register for an event first to check in with its QR code.';

  @override
  String get scanEnterCodeLabel => 'Enter code manually';

  @override
  String get scanEnterCodeAction => 'Submit';

  @override
  String get scanEnterCodeError => 'Enter a code first';

  @override
  String get pointsHistoryTitle => 'Points history';

  @override
  String get pointsHistoryEmpty => 'No points activity yet.';

  @override
  String get pointsHistoryLoadError => 'Couldn\'t load points history.';

  @override
  String get howToEarnTitle => 'How to earn points';

  @override
  String get howToEarnEvent =>
      'Event participation (scan the event\'s code during the activity): +20 each';

  @override
  String get howToEarnFirstMeeting =>
      'First meeting with a new student: +25 each';

  @override
  String get howToEarnSecondMeeting =>
      'Second meeting with the same student: +20 each';

  @override
  String get howToEarnRepeatMeeting =>
      'Third meeting onward with the same student: +10 each';

  @override
  String get reasonEventAttendance => 'Event participation';

  @override
  String get reasonMeetingFirst => 'First meeting';

  @override
  String get reasonMeetingSecond => 'Second meeting';

  @override
  String get reasonMeetingRepeat => 'Repeat meeting';

  @override
  String get reasonGroupMeeting => 'Group meeting';

  @override
  String get reasonMonthlyPrize => 'Monthly prize';

  @override
  String get reasonBenefitRedeem => 'Benefit redeemed';

  @override
  String get reasonGeneric => 'Points';

  @override
  String get championsTabLabel => 'Monthly champions';

  @override
  String get championsTitle => 'Monthly Champions';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNext => 'Next';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionGotIt => 'Got it';

  @override
  String get championsHeroLabel => 'This month\'s ranking';

  @override
  String get championsHeroTitle => 'This month\'s champions';

  @override
  String get championsMyRankLabel => 'My ranking';

  @override
  String get championsMyPointsLabel => 'My points this month';

  @override
  String championsGapLabel(int gap, String name) {
    return '$gap points to pass $name';
  }

  @override
  String get championsUnranked =>
      'You haven\'t earned any points this month yet.';

  @override
  String get championsListTitle => 'This month\'s points';

  @override
  String get championsHeroMonthPrefix => 'Champions';

  @override
  String get championsUpdateFrequency => 'Updated monthly';

  @override
  String get championsTableRankCol => 'Rank';

  @override
  String get championsTableNameCol => 'Name';

  @override
  String get championsTablePointsCol => 'Points';

  @override
  String get championsEmpty => 'No ranking yet this month.';

  @override
  String get championsLoadError => 'Couldn\'t load the leaderboard.';

  @override
  String get adminAccessDenied => 'You don\'t have access to this page.';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventTypeSingle => 'One-Time';

  @override
  String get eventTypeProgram => 'Program';

  @override
  String get eventFiltersButton => 'Filters';

  @override
  String get eventFiltersTitle => 'Filter events';

  @override
  String get eventFilterTypeLabel => 'Type';

  @override
  String get eventFilterCategoryLabel => 'Category';

  @override
  String get eventFilterOrganizerLabel => 'Organizer';

  @override
  String get eventFiltersApply => 'Apply filters';

  @override
  String get eventFiltersReset => 'Reset';

  @override
  String get eventDescriptionLabel => 'About this event';

  @override
  String get eventCancelAction => 'Cancel registration';

  @override
  String get eventEndedLabel => 'This event has ended';

  @override
  String get cancelEventRegistrationTitle => 'Cancel registration?';

  @override
  String get cancelEventRegistrationMessage =>
      'You can register again later if you change your mind.';

  @override
  String get cancelEventRegistrationConfirm => 'Cancel registration';

  @override
  String get cancelEventRegistrationSuccess => 'Registration cancelled.';

  @override
  String get cancelEventRegistrationError =>
      'Couldn\'t cancel your registration.';

  @override
  String get myEventsTitle => 'My Events';

  @override
  String get myEventsFilterUpcoming => 'Upcoming';

  @override
  String get myEventsFilterAttended => 'Attended';

  @override
  String get myEventsFilterMissed => 'Missed';

  @override
  String get myEventsAttendedMessage =>
      'Great job! We\'re proud that you joined!';

  @override
  String get myEventsMissedMessage =>
      'We missed you! It\'s a shame you couldn\'t join us.';

  @override
  String get myEventsUpcomingMessage => 'We\'re looking forward to seeing you!';

  @override
  String get myEventsEmpty => 'You haven\'t registered for any events yet.';

  @override
  String get myEventsLoadError => 'Couldn\'t load your events.';

  @override
  String get eventEditAction => 'Edit';

  @override
  String get eventFormCreateTitle => 'Create Event';

  @override
  String get eventFormEditTitle => 'Edit Event';

  @override
  String get eventFormTitleLabel => 'Title';

  @override
  String get eventFormDescriptionLabel => 'Description';

  @override
  String get eventFormCategoryLabel => 'Category';

  @override
  String get eventFormLocationLabel => 'Location';

  @override
  String get eventFormStartLabel => 'Starts';

  @override
  String get eventFormEndLabel => 'Ends';

  @override
  String get eventFormPointsLabel => 'Points';

  @override
  String get eventFormCapacityLabel => 'Capacity (optional)';

  @override
  String get eventFormImageUrlLabel => 'Image URL (optional)';

  @override
  String get eventFormOrganizerLabel => 'Organizer name (optional)';

  @override
  String get eventFormVisibilityLabel => 'Who can see this event?';

  @override
  String get eventVisibilityOnlyMe => 'Only Me';

  @override
  String get eventVisibilityEveryone => 'Everyone';

  @override
  String get eventVisibilitySpecificFaculties => 'Specific Faculties';

  @override
  String get eventVisibilitySpecificGroups => 'Specific Groups';

  @override
  String get eventFormFacultiesLabel => 'Select faculties';

  @override
  String get eventFormGroupTagsLabel => 'Group tags (comma separated)';

  @override
  String get eventFormErrorTitleRequired => 'Enter a title';

  @override
  String get eventFormErrorDatesRequired => 'Choose a start and end time';

  @override
  String get eventFormErrorEndBeforeStart =>
      'End time must be after the start time';

  @override
  String get eventFormErrorGeneric =>
      'Couldn\'t save the event. Please check the details and try again.';

  @override
  String get eventFormSubmitCreate => 'Submit for Approval';

  @override
  String get eventFormSubmitUpdate => 'Save Changes';

  @override
  String get eventShowQrAction => 'Show QR';

  @override
  String get eventQrScanningLabel => 'Scanning';

  @override
  String eventQrRefreshesIn(int seconds) {
    return 'Refreshes in ${seconds}s';
  }

  @override
  String get eventQrLoadError => 'Couldn\'t generate a QR code.';

  @override
  String get eventQrHint =>
      'Show this QR code to students during the event. It refreshes every 10 seconds.';

  @override
  String get eventScanningClosedMessage => 'Scanning is closed.';

  @override
  String get eventScanTitle => 'Scan to Check In';

  @override
  String get eventScanGenericHeading => 'Scan any event\'s QR code to check in';

  @override
  String get eventScanToCheckInAction => 'Scan to check in';

  @override
  String eventScanSuccess(int points) {
    return 'You earned $points points!';
  }

  @override
  String get eventScanErrorExpired => 'You scanned after the time limit.';

  @override
  String get eventScanErrorAlreadyScanned =>
      'You have already scanned this event. You cannot scan it again.';

  @override
  String get eventScanErrorNotRegistered =>
      'You need to register for this event before scanning.';

  @override
  String get eventScanErrorInvalid => 'Invalid QR code.';

  @override
  String get eventStatsRegistered => 'Registered';

  @override
  String get eventStatsAttended => 'Attended';

  @override
  String get eventStatsMissed => 'Missed';

  @override
  String programPointsEquation(int points, int count, int total) {
    return '$points Points × $count Sessions = $total Possible Points';
  }

  @override
  String get programSessionsTitle => 'Sessions';

  @override
  String get programSessionsEmpty => 'No sessions yet.';

  @override
  String get programSessionsLoadError => 'Couldn\'t load sessions.';

  @override
  String get programManageSessionsAction => 'Manage Sessions';

  @override
  String get programViewSessionsAction => 'View Sessions';

  @override
  String programAttendanceProgress(int attended, int total) {
    return 'Attended $attended of $total sessions';
  }

  @override
  String get programAttendedAllSessions => 'You attended every session!';

  @override
  String get programSessionsFormTitle => 'Sessions';

  @override
  String get programSessionLabel => 'Session';

  @override
  String get programAddSessionAction => 'Add another session';

  @override
  String get eventFormErrorSessionsRequired => 'Add at least one session';

  @override
  String get eventFormErrorSessionIncomplete =>
      'Fill in the title and both times for every session';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'No conversations yet.';

  @override
  String get chatsSearchHint => 'Search chats';

  @override
  String get chatsSearchEmpty => 'No chats match your search.';

  @override
  String get chatsLoadError => 'Couldn\'t load your chats.';

  @override
  String get chatMessageHint => 'Type a message…';

  @override
  String get chatBlockAction => 'Block';

  @override
  String get chatUnblockAction => 'Unblock';

  @override
  String get chatBlockedBanner =>
      'You\'ve blocked this user. Unblock to send messages.';

  @override
  String get chatBlockedByOtherBanner =>
      'You can\'t send messages in this conversation.';

  @override
  String get chatBlockConfirmTitle => 'Block this user?';

  @override
  String get chatBlockConfirmMessage =>
      'They won\'t be able to message you until you unblock them.';

  @override
  String get chatEmptyThread => 'Say hello 👋';

  @override
  String get chatDateToday => 'Today';

  @override
  String get chatDateYesterday => 'Yesterday';

  @override
  String get proposeMeetingTitle => 'Propose a meeting';

  @override
  String get proposeMeetingPickDateTime => 'Pick date & time';

  @override
  String get proposeMeetingPickEndDateTime => 'Pick end time';

  @override
  String get proposeMeetingNotesLabel => 'Notes (optional)';

  @override
  String get proposeMeetingSubmit => 'Send proposal';

  @override
  String get proposeMeetingErrorDateRequired => 'Choose a date and time';

  @override
  String get proposeMeetingErrorEndBeforeStart =>
      'End time must be after the start time';

  @override
  String get proposeMeetingError => 'Couldn\'t send the proposal';

  @override
  String get proposeMeetingErrorSameStudentToday =>
      'You already have a meeting with this student on that day. You can meet the same student once per day.';

  @override
  String get proposeMeetingErrorDailyLimitSelf =>
      'You already have meetings with 5 different students on that day, which is the daily limit. Try another date.';

  @override
  String get proposeMeetingErrorDailyLimitOther =>
      'This student already has meetings with 5 different students on that day. Try another date.';

  @override
  String get proposeMeetingCardTitle => 'Meeting proposal';

  @override
  String get proposeMeetingAccept => 'Accept';

  @override
  String get proposeMeetingDecline => 'Decline';

  @override
  String get proposeMeetingWaiting => 'Waiting for response…';

  @override
  String get proposeMeetingAccepted => 'Accepted';

  @override
  String get proposeMeetingDeclined => 'Declined';

  @override
  String get reportUserAction => 'Report';

  @override
  String reportUserTitle(String name) {
    return 'Report $name';
  }

  @override
  String get reportUserReasonLabel => 'Reason';

  @override
  String get reportUserDetailsLabel => 'Details';

  @override
  String get reportUserErrorReasonRequired => 'Enter a reason';

  @override
  String get reportUserErrorDetailsRequired => 'Enter some details';

  @override
  String get reportUserImagesLabel => 'Screenshots (optional)';

  @override
  String get reportUserAddImage => 'Add';

  @override
  String get reportUserSubmit => 'Submit report';

  @override
  String get reportUserSuccess => 'Report submitted.';

  @override
  String get reportUserError => 'Couldn\'t submit the report.';

  @override
  String get groupMeetingListEntryPoint => 'Group meetings';

  @override
  String get groupMeetingListTitle => 'My Group Meetings';

  @override
  String get groupMeetingCreateAction => 'New group meeting';

  @override
  String get groupMeetingListLoadError => 'Couldn\'t load your group meetings.';

  @override
  String get groupMeetingListEmpty => 'You have no group meetings yet.';

  @override
  String get groupMeetingStatusApproved => 'Approved';

  @override
  String get groupMeetingStatusRejected => 'Rejected';

  @override
  String get groupMeetingStatusPending => 'Pending approval';

  @override
  String get groupMeetingRoleOrganizer => 'You\'re organizing this meeting';

  @override
  String groupMeetingRoleParticipant(String name) {
    return 'Organized by $name';
  }

  @override
  String get groupMeetingFinishedTag => 'Finished';

  @override
  String get groupMeetingShowQrAction => 'Show QR';

  @override
  String get groupMeetingScanAction => 'Scan';

  @override
  String get groupMeetingEnterCodeTitle => 'Enter a code';

  @override
  String get groupMeetingEnterCodeHint =>
      'Paste the code shared by the organizer';

  @override
  String get groupMeetingEnterCodeAction => 'Enter code';

  @override
  String get groupMeetingCreateTitle => 'New Group Meeting';

  @override
  String get groupMeetingCreateHint =>
      'Your request goes to an admin for approval before a registration link is created.';

  @override
  String get groupMeetingLocationLabel => 'Location';

  @override
  String get groupMeetingLocationHint =>
      'Group meetings must take place on TAU campus.';

  @override
  String get groupMeetingLocationRequired => 'Please choose a campus location.';

  @override
  String groupMeetingMaxParticipantsLabel(int count) {
    return 'Max participants: $count';
  }

  @override
  String get groupMeetingCreateSubmit => 'Submit request';

  @override
  String get groupMeetingCreateSuccess =>
      'Your group meeting request was submitted.';

  @override
  String get groupMeetingCreateError => 'Couldn\'t submit your request.';

  @override
  String get groupMeetingRegistrationTitle => 'Group Meeting';

  @override
  String get groupMeetingRegistrationInvalid =>
      'This link is invalid or has expired.';

  @override
  String groupMeetingRegisteredCount(int count, int max) {
    return '$count of $max registered';
  }

  @override
  String get groupMeetingRegisterAction => 'Register';

  @override
  String get groupMeetingRegisterSuccess => 'You\'re registered!';

  @override
  String get groupMeetingAlreadyRegistered =>
      'You\'re already registered for this meeting.';

  @override
  String get groupMeetingRegisterErrorFull => 'This meeting is full.';

  @override
  String get groupMeetingRegisterErrorAlready => 'You\'re already registered.';

  @override
  String get groupMeetingRegisterErrorOwn =>
      'You\'re the organizer of this meeting.';

  @override
  String get groupMeetingRegisterErrorGeneric =>
      'Couldn\'t register for this meeting.';

  @override
  String get groupMeetingQrHint =>
      'Show this QR code to participants. It refreshes every 10 seconds.';

  @override
  String get groupMeetingFinishAction => 'Finish meeting';

  @override
  String get groupMeetingFinishError => 'Couldn\'t finish the meeting.';

  @override
  String get groupMeetingFinishDialogTitle => 'Meeting finished';

  @override
  String get groupMeetingFinishDialogOk => 'OK';

  @override
  String get groupMeetingFinishOutcomeNone =>
      'Nobody scanned in, so no points were awarded.';

  @override
  String groupMeetingFinishOutcomeOneToOne(int points) {
    return 'Only one person scanned in, so this counted as a 1:1 meeting — you both earned $points points.';
  }

  @override
  String get groupMeetingFinishOutcomeCapped =>
      'Only one person scanned in, so this counted as a 1:1 meeting — but today\'s cap for that pair was already reached, so no points were awarded.';

  @override
  String groupMeetingFinishOutcomeGroup(int organizerPoints, int scanners) {
    return 'You earned $organizerPoints points, and $scanners participants each earned points.';
  }

  @override
  String get groupMeetingScanTitle => 'Scan to Join';

  @override
  String get groupMeetingScanSuccess => 'You\'ve joined the meeting!';

  @override
  String get groupMeetingScanErrorOwnCode =>
      'You can\'t scan your own QR code.';

  @override
  String get benefitsCatalogTabLabel => 'Catalog';

  @override
  String get benefitsWalletTabLabel => 'My Wallet';

  @override
  String benefitsPointsBalance(int points) {
    return 'You have $points points';
  }

  @override
  String get benefitsCatalogLoadError => 'Couldn\'t load the benefits catalog.';

  @override
  String get benefitsCatalogEmpty => 'No benefits available right now.';

  @override
  String get benefitsWalletLoadError => 'Couldn\'t load your wallet.';

  @override
  String get benefitsWalletEmpty => 'You haven\'t redeemed any benefits yet.';

  @override
  String get benefitsWalletTitle => 'My Digital Wallet';

  @override
  String get benefitsWalletSubtitle => 'All your digital cards in one place';

  @override
  String get benefitsWalletPointsLabel => 'Points balance';

  @override
  String get benefitsWalletFilterAll => 'All';

  @override
  String get benefitsWalletFilterNotUsed => 'Not used';

  @override
  String get benefitsWalletFilterUsed => 'Used';

  @override
  String get benefitsWalletFilterButton => 'Filter';

  @override
  String get benefitsWalletFilterByBusiness => 'Filter by business';

  @override
  String get benefitsWalletFilterClear => 'Clear filter';

  @override
  String get benefitsStatusLabel => 'My status';

  @override
  String get benefitsCatalogHeading => 'Convert points to benefits';

  @override
  String get benefitsOpenWalletAction => 'My Digital Wallet';

  @override
  String get benefitsCategoryAll => 'All';

  @override
  String benefitPointCost(int points) {
    return '$points points';
  }

  @override
  String get benefitRedeemAction => 'Redeem';

  @override
  String get benefitNotEnoughPoints => 'Not enough points';

  @override
  String get benefitAlreadyActiveLabel => 'In your wallet';

  @override
  String get benefitAlreadyActiveMessage =>
      'You have a digital card in your wallet for this benefit.';

  @override
  String get benefitRedeemConfirmTitle => 'Redeem benefit';

  @override
  String benefitRedeemConfirmMessage(String title, int points) {
    return 'Redeem \"$title\" for $points points?';
  }

  @override
  String get benefitRedeemErrorInsufficientPoints =>
      'You don\'t have enough points for this benefit.';

  @override
  String get benefitRedeemErrorUnavailable =>
      'This benefit is no longer available.';

  @override
  String get benefitRedeemErrorAlreadyActive =>
      'You already have a digital card in your wallet for this benefit.';

  @override
  String get benefitRedeemErrorNotAStudent =>
      'This account can\'t redeem benefits — only student accounts can.';

  @override
  String get benefitRedeemErrorGeneric => 'Couldn\'t redeem this benefit.';

  @override
  String get benefitCardRedeemedTag => 'Redeemed';

  @override
  String get benefitCardAvailableTag => 'Available';

  @override
  String get benefitCardStatusLabel => 'Status';

  @override
  String get benefitCardOpenAction => 'Digital Card';

  @override
  String get benefitCardShowHint =>
      'Show this QR code to the partner to redeem.';

  @override
  String get benefitCardCodeLabel =>
      'Or give this code if the QR can\'t be scanned';

  @override
  String benefitCardAcquiredOn(String date) {
    return 'Redeemed with points on $date';
  }

  @override
  String benefitCardRedeemedOn(String date) {
    return 'Used at partner on $date';
  }

  @override
  String get supportContactsRowLabel => 'Technical Support';

  @override
  String get supportContactsTitle => 'Technical Support';

  @override
  String get supportContactsError => 'Couldn\'t load support contacts.';

  @override
  String get supportContactsEmpty =>
      'No support contacts have been set up yet.';

  @override
  String get supportContactsCopy => 'Copy phone number';

  @override
  String get supportContactsCopied => 'Phone number copied';

  @override
  String get benefitFormCreateTitle => 'New Benefit';

  @override
  String get benefitFormEditTitle => 'Edit Benefit';

  @override
  String get benefitFormPartnerLabel => 'Partner business name';

  @override
  String get benefitFormImageUrlLabel => 'Image URL';

  @override
  String get benefitFormPointCostLabel => 'Point cost';

  @override
  String get benefitFormErrorPointCostInvalid =>
      'Enter a point cost greater than 0';

  @override
  String get benefitFormCreateAction => 'Create benefit';

  @override
  String get benefitFormSaveAction => 'Save';

  @override
  String get benefitProfileAboutBenefit => 'About this benefit';

  @override
  String get benefitProfileAboutBusiness => 'About the business';

  @override
  String get benefitProfileHowToRedeem => 'How to redeem';

  @override
  String get benefitProfileLinkLabel => 'Link';

  @override
  String get benefitProfileOpenLink => 'Open link';

  @override
  String get benefitProfileLocationLabel => 'Location';

  @override
  String get benefitProfileOpenMaps => 'Open in Maps';

  @override
  String get benefitProfileCategoryLabel => 'Category';

  @override
  String get benefitProfileCostLabel => 'Points cost';

  @override
  String get benefitFormSectionBasics => 'Basic info';

  @override
  String get benefitFormSectionBusiness => 'Business info';

  @override
  String get benefitFormSectionRedemption => 'Redemption details';

  @override
  String get benefitFormSectionLocation => 'Location';

  @override
  String get benefitFormBusinessDescriptionLabel => 'Business description';

  @override
  String get benefitFormHowToRedeemLabel => 'How to redeem';

  @override
  String get benefitFormExternalLinkLabel =>
      'External link (Instagram, website, …)';

  @override
  String get benefitFormLocationLabel => 'Location';

  @override
  String get benefitFormMapsLinkLabel => 'Google Maps link';

  @override
  String get benefitFormImageLabel => 'Benefit image';

  @override
  String get benefitFormEditAction => 'Edit';

  @override
  String get benefitDigitalCardSection => 'Digital card';

  @override
  String get benefitDigitalCardPreviewAction => 'Preview digital card';

  @override
  String get benefitDigitalCardPreviewTitle => 'Digital card preview';

  @override
  String get benefitDigitalCardPreviewNote =>
      'This is exactly how the card will look in a student\'s wallet.';

  @override
  String get benefitCardSampleStudent => 'Student name';

  @override
  String get benefitCardStudentLabel => 'Cardholder';

  @override
  String notificationEventPending(String title) {
    return '\"$title\" is waiting for your approval';
  }

  @override
  String get notificationEventPendingGeneric =>
      'An event is waiting for your approval';

  @override
  String get eventProfileOrganizerLabel => 'Organizer';

  @override
  String get eventProfilePointsLabel => 'Points awarded';

  @override
  String get eventProfileDescriptionLabel => 'Event description';

  @override
  String get eventProfileLocationLabel => 'Location';

  @override
  String get eventProfileScheduleLabel => 'Date & time';

  @override
  String get eventProfileOrganizerDescriptionLabel => 'About the organizer';

  @override
  String get eventProfileExternalLinkLabel => 'External link';

  @override
  String get eventProfileCategoryLabel => 'Category';

  @override
  String get eventProfileSessionsLabel => 'Program sessions';

  @override
  String get eventProfileSessionColumn => 'Session';

  @override
  String get eventProfileWhenColumn => 'When';

  @override
  String get eventProfileWhereColumn => 'Where';

  @override
  String get eventProfileStatusColumn => 'Status';

  @override
  String get eventProfileSessionMissed => 'Missed';

  @override
  String get eventProfileSessionUpcoming => 'Upcoming';

  @override
  String eventProfileTotalPoints(int points) {
    return '$points points for completing the program';
  }

  @override
  String eventProfileSessionCount(int count) {
    return '$count sessions';
  }

  @override
  String eventProfilePerSessionPoints(int points) {
    return '$points points per session';
  }

  @override
  String get eventProfileReviewTitle => 'Review event';

  @override
  String get eventFormImageLabel => 'Event image';

  @override
  String notificationEventPublished(String title) {
    return 'New event: $title';
  }

  @override
  String get notificationEventPublishedGeneric => 'A new event was published';

  @override
  String notificationBenefitPublished(String title) {
    return 'New benefit: $title';
  }

  @override
  String get notificationBenefitPublishedGeneric =>
      'A new benefit is available';

  @override
  String get notificationReportSubmitted => 'A new report was submitted';

  @override
  String notificationEventApproved(String title) {
    return '\"$title\" was approved';
  }

  @override
  String get notificationEventApprovedGeneric => 'Your event was approved';

  @override
  String notificationEventRejected(String title) {
    return '\"$title\" was rejected';
  }

  @override
  String notificationEventRejectedWithReason(String title, String reason) {
    return '\"$title\" was rejected: $reason';
  }

  @override
  String get notificationEventRejectedGeneric => 'Your event was rejected';

  @override
  String get notificationGroupMeetingPending =>
      'A group meeting is waiting for approval';

  @override
  String notificationBenefitRedeemed(String title) {
    return 'Congratulations! The benefit ($title) has been successfully redeemed.';
  }

  @override
  String get notificationBenefitRedeemedGeneric =>
      'Congratulations! Your benefit has been successfully redeemed.';

  @override
  String notificationSurveyPublished(String title) {
    return 'New survey: $title';
  }

  @override
  String get notificationSurveyPublishedGeneric => 'A new survey is available';

  @override
  String get scanStudentIdLabel => 'Student ID (Show it to the Event Host)';

  @override
  String get scanStudentIdCopied => 'Student ID copied';

  @override
  String get attendanceManualTitle => 'Confirm by Student ID';

  @override
  String get attendanceManualHint => 'Enter the student\'s ID';

  @override
  String get attendanceManualAction => 'Confirm attendance';

  @override
  String get attendanceManualLookupError => 'No student found with that ID';

  @override
  String get attendanceManualConfirmTitle => 'Confirm attendance';

  @override
  String attendanceManualConfirmMessage(String name) {
    return 'Mark $name as attended?';
  }

  @override
  String attendanceManualSuccess(String name) {
    return '$name was marked as attended';
  }

  @override
  String get optionNoTranslations => 'No translations — shows in English';

  @override
  String get optionEditTranslations => 'Edit translations';

  @override
  String get optionLabelArabic => 'Arabic label';

  @override
  String get optionLabelHebrew => 'Hebrew label';

  @override
  String get actionSave => 'Save';

  @override
  String get championsRewardsTitle => 'Monthly rewards';

  @override
  String championsRewardFirst(int points) {
    return '🥇 1st place: $points pts';
  }

  @override
  String championsRewardSecond(int points) {
    return '🥈 2nd place: $points pts';
  }

  @override
  String championsRewardThird(int points) {
    return '🥉 3rd place: $points pts';
  }

  @override
  String get legalPrivacyTitle => 'Privacy Policy';

  @override
  String get legalTermsTitle => 'Terms & Conditions';

  @override
  String get legalEditAction => 'Edit';

  @override
  String get legalTitleLabel => 'Title';

  @override
  String get legalBodyLabel => 'Content';

  @override
  String get legalLoadError => 'Couldn\'t load this document.';

  @override
  String get legalSaveError => 'Couldn\'t save. Please try again.';

  @override
  String get legalEditDenied => 'Only the super admin can edit this.';

  @override
  String get legalEmpty => 'This document hasn\'t been written yet.';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get meetingInProgressTitle => 'Meeting in progress';

  @override
  String get meetingWithLabel => 'with';

  @override
  String get meetingYourQrTitle => 'Your QR Code';

  @override
  String get meetingScanOtherTitle => 'Scan the other student\'s QR code';

  @override
  String get meetingQrRotatingHint => 'This code refreshes every 10 seconds';

  @override
  String get meetingSectionDone => 'Done';

  @override
  String get meetingBothActionsHint =>
      'Complete both actions to confirm the meeting and earn points.';

  @override
  String get meetingScanOwnCode => 'That\'s your own code';

  @override
  String get meetingScanExpired =>
      'That code expired — ask them to show it again';

  @override
  String get meetingScanError => 'Couldn\'t scan. Please try again.';

  @override
  String meetingCompletedPoints(int points) {
    return 'Meeting confirmed! You earned $points points.';
  }

  @override
  String get meetingCompletedNoPoints =>
      'Meeting confirmed! (No points — already met today.)';

  @override
  String get meetingOpenAction => 'Open meeting';

  @override
  String get meetingNotYetOpen =>
      'Ready to connect? Check back at your scheduled time.';

  @override
  String get meetingWindowEnded => 'This meeting\'s window has ended';

  @override
  String get myEventsMeetingsTitle => 'Meetings';

  @override
  String get meetingCardCompleted => 'Completed';

  @override
  String get meetingAttendedMessage =>
      'Awesome! We\'re glad you two connected.';

  @override
  String get meetingMissedMessage =>
      'You missed this meeting window. No worries — you can schedule another one anytime.';

  @override
  String meetingCardWith(String name) {
    return 'Meeting with $name';
  }

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get benefitFormSubmitError => 'Couldn\'t save this benefit.';

  @override
  String monthAnnouncementTitle(String month) {
    return '$month Champions';
  }

  @override
  String get monthAnnouncementBody =>
      'Last month\'s Champions have been announced! Here\'s the top 3:';

  @override
  String get monthAnnouncementOk => 'OK';

  @override
  String winnerBonusTitle(int rank) {
    return 'You placed #$rank!';
  }

  @override
  String winnerBonusPoints(int points) {
    return 'You finished last month with $points points.';
  }

  @override
  String winnerBonusAmount(int bonus) {
    return '+$bonus bonus points';
  }

  @override
  String get winnerBonusOk => 'Awesome!';

  @override
  String get accessibilityPanelTitle => 'Accessibility';

  @override
  String get accessibilityFloatingToggle => 'Floating accessibility button';

  @override
  String get accessibilityFloatingRemovedHint =>
      'Accessibility button hidden. Turn it back on in Settings.';

  @override
  String get actionRemove => 'Remove';

  @override
  String get accessibilityTextSizeLabel => 'Text size';

  @override
  String get accessibilityTextSizeNormal => 'Normal';

  @override
  String get accessibilityTextSizeLarge => 'Large';

  @override
  String get accessibilityTextSizeExtraLarge => 'Extra large';

  @override
  String get accessibilityReduceMotionLabel => 'Reduce motion';

  @override
  String get accessibilityHighContrastLabel => 'High contrast';

  @override
  String get tutorialWelcomeTitle => 'Welcome to C2C – Connect to Collect';

  @override
  String get tutorialWelcomeBody =>
      'Connect with students, explore all campus events, earn points, and enjoy exclusive rewards.';

  @override
  String get tutorialMatchesTitle => 'Find your people';

  @override
  String get tutorialMatchesBody =>
      'Browse students who share your faculty, interests, and hobbies, then message them to set up a meetup.';

  @override
  String get tutorialScanTitle => 'Scan to earn';

  @override
  String get tutorialScanBody =>
      'Show or scan a QR code at meetups and events to earn points automatically.';

  @override
  String get tutorialBenefitsTitle => 'Spend your points';

  @override
  String get tutorialBenefitsBody =>
      'Redeem points for real perks from campus partners in the Benefits tab.';

  @override
  String get tutorialChampionsTitle => 'Climb the leaderboard';

  @override
  String get tutorialChampionsBody =>
      'Top 3 students each month win a bonus — check Monthly Champions to see where you stand.';

  @override
  String get tutorialBackAction => 'Back';

  @override
  String get tutorialNextAction => 'Next';

  @override
  String get tutorialGetStartedAction => 'Get Started';

  @override
  String get demoEventCheckInTitle => 'How Event Points Work';

  @override
  String get demoEventCheckInMessage =>
      'Registering for an event doesn\'t automatically earn points. When you arrive, scan the event QR code—or ask the host to enter your Student ID—to receive your points.';

  @override
  String get demoMeetingStep1Title => 'Your QR Code';

  @override
  String get demoMeetingStep1Message =>
      'Show this to the other student — it refreshes every 10 seconds for security.';

  @override
  String get demoMeetingStep2Title => 'Scan the Other Student\'s QR';

  @override
  String get demoMeetingStep2Message =>
      'Scan their code too. Points are only awarded once you\'ve both scanned each other.';

  @override
  String get demoGroupMeetingTitle => 'About Group Meetings';

  @override
  String get demoGroupMeetingMessage =>
      'If you are a group of 3 or more people and want to meet, create a group meeting here. The organizer receives 25 points when at least two other participants scan them, and each scanning participant receives 15 points.';

  @override
  String get demoBenefitsCatalogTitle => 'Before You Redeem';

  @override
  String get demoBenefitsCatalogMessage =>
      'Redeeming a benefit spends your points immediately, and you can only hold one active card per benefit at a time.';

  @override
  String get demoDigitalCardTitle => 'Redeem This Card';

  @override
  String get demoDigitalCardMessage =>
      'This is the barcode for redeeming your benefit. When you get to the business, show it to the seller to receive the benefit. Please note: scanning the barcode and tapping \"Redeem\" redeems the benefit immediately, no matter who scanned it. So don\'t scan it yourself — only show it to the seller or a representative of the business where the benefit is redeemed.';

  @override
  String get demoMatchingTitle => 'Compatibility Match';

  @override
  String get demoMatchingMessage =>
      'This percentage shows how closely your interests, faculty, and languages match. A higher percentage means you have more in common.';

  @override
  String get demoGuidedMatchTabTitle => 'Tap here';

  @override
  String get demoGuidedMatchTabMessage =>
      'Tap the Matches tab to see students you might connect with.';

  @override
  String get demoGuidedViewProfileTitle => 'Tap here';

  @override
  String get demoGuidedViewProfileMessage =>
      'Tap View Profile to check out a student\'s full profile.';

  @override
  String get demoProgramTitle => 'Program Points';

  @override
  String get demoProgramMessage =>
      'Points are awarded per session — each session needs its own check-in to count.';

  @override
  String get demoAccessibilityTitle => 'Accessibility Shortcut';

  @override
  String get demoAccessibilityMessage =>
      'You can drag this button anywhere on the screen. Drag it to the bottom area to hide it. You can enable it again from Settings.';

  @override
  String get demoChampionsTitle => 'Monthly Champions';

  @override
  String get demoChampionsMessage =>
      'This leaderboard tracks points earned this month only, and resets on the 1st. Your rank card shows exactly where you stand.';

  @override
  String get demoReportUserTitle => 'Report a User';

  @override
  String get demoReportUserMessage =>
      'It is important to know about this option: if a user behaves inappropriately, makes you feel uncomfortable, or there is an issue our team should know about, you can report them here. The report will be sent to the system team for review and handling.';

  @override
  String get settingsHelpSectionTitle => 'Help & Tutorials';

  @override
  String get settingsReplayIntroAction => 'Replay App Introduction';

  @override
  String get settingsReplayTutorialsAction => 'Replay Tutorials';

  @override
  String get settingsReplayTutorialsToast =>
      'Tutorials reset — you\'ll see them again as you use the app.';

  @override
  String get profileLoadError => 'Couldn\'t load your profile.';

  @override
  String get profileAboutTitle => 'About';

  @override
  String get profileAboutEmpty => 'You haven\'t added a bio yet.';

  @override
  String get profileInterestsLabel => 'Interests';

  @override
  String get profileInterestsEmpty => 'You haven\'t added any interests yet';

  @override
  String get profileLanguagesTitle => 'Languages';

  @override
  String get profileLanguagesEmpty => 'You haven\'t added any languages yet';

  @override
  String get profileStudiesTitle => 'Studies';

  @override
  String get profileFacultyLabel => 'Faculty';

  @override
  String get profileFieldOfStudyLabel => 'Field of study';

  @override
  String get searchableFieldMultipleHint => 'You can select multiple';

  @override
  String get searchableFieldPlaceholder => 'Tap to select';

  @override
  String get searchableFieldSearchHint => 'Search';

  @override
  String get searchableFieldNoMatches => 'No matches';

  @override
  String get searchableFieldDone => 'Done';

  @override
  String get profileGenderLabel => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderUndisclosed => 'Prefer not to say';

  @override
  String get profilePhotoLabel => 'Profile picture';

  @override
  String get profilePhotoChange => 'Change photo';

  @override
  String get profilePhotoAdd => 'Add photo';

  @override
  String get profilePhotoUploadError =>
      'Couldn\'t upload the photo. Please try again.';

  @override
  String get profileBioHint => 'Tell other students a bit about yourself';

  @override
  String get profileOptionsLoadError => 'Couldn\'t load options.';

  @override
  String get profileOptionsEmpty => 'No options available yet.';

  @override
  String get actionRetry => 'Retry';

  @override
  String get errorSelectFieldOfStudy =>
      'Please select at least one field of study';

  @override
  String get profileDegreeLabel => 'Degree';

  @override
  String get profileYearLabel => 'Year of study';

  @override
  String profileYearShort(int year) {
    return 'Year $year';
  }

  @override
  String get profileEditAction => 'Edit profile';

  @override
  String get profileSettingsTitle => 'Settings';

  @override
  String get profileLanguageLabel => 'Language';

  @override
  String get profilePolicyLabel => 'Policy & terms of use';

  @override
  String get profileLogoutAction => 'Log out';

  @override
  String get profileDeleteAccountAction => 'Delete account';

  @override
  String get profileDeleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get profileDeleteAccountConfirmMessage =>
      'After you request deletion your account is deactivated for 30 days. At the end of that period it is permanently deleted. If you sign back in to the app within those 30 days, the deletion request is cancelled and your account stays active.';

  @override
  String get profileDeleteAccountConfirmAction => 'Request deletion';

  @override
  String get profileDeleteAccountInProgress => 'Sending deletion request…';

  @override
  String get profileDeleteAccountError =>
      'We couldn\'t send the deletion request. Please try again or contact support.';

  @override
  String get profileLogoutConfirmTitle => 'Log out of your account?';

  @override
  String profileAppVersion(String version) {
    return 'C2C app version $version';
  }

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileEditError => 'Couldn\'t save your profile.';

  @override
  String get profileSaveAction => 'Save changes';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsLoadError => 'Couldn\'t load your notifications.';

  @override
  String get notificationsEmpty => 'You have no notifications yet.';

  @override
  String notificationsSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get notificationsSelectAll => 'Select all';

  @override
  String get notificationsMarkRead => 'Mark as read';

  @override
  String get notificationsMarkUnread => 'Mark as unread';

  @override
  String get notificationsDeleteAction => 'Delete';

  @override
  String get notificationsClearAll => 'Clear all';

  @override
  String get notificationsDeleteConfirmTitle => 'Delete notifications?';

  @override
  String notificationsDeleteConfirmMessage(Object count) {
    return 'This will permanently delete $count notification(s). This can\'t be undone.';
  }

  @override
  String get notificationsClearAllConfirmTitle => 'Clear all notifications?';

  @override
  String get notificationsClearAllConfirmMessage =>
      'This will permanently delete all your notifications. This can\'t be undone.';

  @override
  String get notificationTargetLoadError =>
      'Couldn\'t open this — it may no longer be available.';

  @override
  String notificationPointsEarned(int points) {
    return 'Received $points points';
  }

  @override
  String notificationPointsEarnedWithTitle(int points, String title) {
    return 'Received $points points – $title';
  }

  @override
  String notificationNewMessage(String name) {
    return 'New message from $name';
  }

  @override
  String notificationMeetingProposal(String time) {
    return 'New proposal: meeting at $time';
  }

  @override
  String get notificationMeetingProposalGeneric => 'New meeting proposal';

  @override
  String get notificationGeneric => 'New notification';

  @override
  String get surveysTitle => 'Surveys';

  @override
  String get homeSurveysSection => 'Available Surveys';

  @override
  String get homeSurveysBannerCta => 'Fill a quick survey and get points!';

  @override
  String get surveysTabActive => 'Active Surveys';

  @override
  String get surveysTabCompleted => 'Completed Surveys';

  @override
  String get surveysFilterPending => 'Pending';

  @override
  String get surveysFilterCompleted => 'Completed';

  @override
  String get surveysFilterIncoming => 'Incoming';

  @override
  String get surveysEmptyPending => 'No surveys waiting for you right now.';

  @override
  String get surveysEmptyCompleted => 'You haven\'t completed any surveys yet.';

  @override
  String get surveysEmptyIncoming => 'No upcoming surveys scheduled.';

  @override
  String get surveysLoadError => 'Couldn\'t load surveys.';

  @override
  String get surveysEndsToday => 'Ends today';

  @override
  String surveysEndsInDays(int days) {
    return 'Ends in $days days';
  }

  @override
  String get surveyStartAction => 'Start Survey';

  @override
  String surveyPointsLabel(int points) {
    return '$points pts';
  }

  @override
  String get surveySubmitAction => 'Submit';

  @override
  String surveySubmitSuccess(int points) {
    return 'You earned $points points!';
  }

  @override
  String get surveySubmitErrorGeneric =>
      'Couldn\'t submit your answers. Try again.';

  @override
  String get surveySubmitErrorAlreadyAnswered =>
      'You\'ve already completed this survey.';

  @override
  String get surveySubmitErrorClosed => 'This survey is closed.';

  @override
  String get surveySubmitErrorNotYetOpen => 'This survey isn\'t open yet.';

  @override
  String get surveyDetailLoadError => 'Couldn\'t load this survey.';

  @override
  String get surveyTextAnswerHint => 'Type your answer';

  @override
  String get surveyTextAnswerRequired =>
      'Please answer every question before submitting.';

  @override
  String get tourIntroTitle => 'Great, you’re successfully signed in!';

  @override
  String get tourIntroDescription =>
      'Now we’ll briefly introduce you to the app and its main buttons and features.';

  @override
  String get tourNextAction => 'Next';

  @override
  String get tourMyEventsTitle => 'My Events';

  @override
  String get tourMyEventsDescription =>
      'Here you can see the events you registered for, the meetings you scheduled with other students, and track your participation.';

  @override
  String get tourPointsTitle => 'My Points';

  @override
  String get tourPointsDescription =>
      'This is the number of points you have earned so far. You can earn points by attending events, meeting other students, and taking part in other activities in the app, then use them to redeem benefits.';

  @override
  String get tourChampionsTitle => 'Monthly Champions';

  @override
  String get tourChampionsDescription =>
      'Earn points, climb the ranking, and reach the top! Here you can track your position and see who leads the monthly ranking. At the end of each month, the three students with the most points receive bonus points.';

  @override
  String get tourSurveysTitle => 'Surveys';

  @override
  String get tourSurveysDescription =>
      'Share what you think and earn points too! Short surveys will appear here for you to answer easily, and you will receive points for every survey you complete.';

  @override
  String get tourAccessibilityTitle => 'Accessibility Button';

  @override
  String get tourAccessibilityDescription =>
      'Open accessibility options here and adapt the app display to your needs. You can drag the accessibility button anywhere convenient on the screen, and remove or restore it at any time from the app settings.';

  @override
  String get tourMatchesNavTitle => 'Meet & Connect';

  @override
  String get tourMatchesNavDescription =>
      'Meet the students around you on campus, discover what you have in common, and arrange to meet on campus! Met up? Scan each other during the meeting and earn points together. Tap here to continue.';

  @override
  String get tourScanNavTitle => 'Scan';

  @override
  String get tourBenefitsNavTitle => 'Benefits';

  @override
  String get tourTapToContinue => 'Tap the highlighted button to continue.';

  @override
  String get tourCompatibilityTitle => 'Compatibility Percentage';

  @override
  String get tourCompatibilityDescription =>
      'A compatibility percentage appears next to each student and is calculated from things you have in common, such as fields of study, interests, and languages. The higher the percentage, the more characteristics you share.';

  @override
  String get tourChatTitle => 'Chat';

  @override
  String get tourChatDescription =>
      'Here you can chat with and get to know other students. Using the (+) button in the chat, you can schedule a meeting that will be saved in ‘My Events’. During the meeting, an option will open to scan each other to confirm that you met, and after confirmation you will receive the meeting points.';

  @override
  String get tourStudentProfileTitle => 'Profile';

  @override
  String get tourStudentProfileDescription =>
      'Here you can get to know the student a little better and see the details they chose to share on their profile, such as their field of study, languages, interests, and additional information about them.';

  @override
  String get tourReportTitle => 'Report a User';

  @override
  String get tourReportDescription =>
      'It is important to know this option: if a user behaves inappropriately, makes you feel uncomfortable, or there is an issue our team should know about, you can report it here. The report will be sent to the system team for review and handling.';

  @override
  String get tourScanCameraTitle => 'Event QR Scan';

  @override
  String get tourScanCameraDescription =>
      'Arrived at an event? Scan the QR code here to confirm your attendance and receive points. This camera is for event scanning only. Meetings with students use a separate scan that opens automatically inside the meeting at its scheduled time. You can find your scheduled meetings in ‘My Events’.';

  @override
  String get tourStudentIdTitle => 'Student Number';

  @override
  String get tourStudentIdDescription =>
      'This is your personal identification number in the app. If you missed the QR scan at an event or there was a scanning problem, you can give this number to the event host so they can add you manually.';

  @override
  String get tourBenefitsPageTitle => 'Benefits';

  @override
  String get tourBenefitsPageDescription =>
      'It’s time to enjoy the points you’ve earned! Here you can see available benefits, read their details, check how many points are required, and choose the benefit you want to redeem.';

  @override
  String get tourWalletTitle => 'My Wallet';

  @override
  String get tourTapWalletDescription => 'Tap the wallet button to continue.';

  @override
  String get tourWalletDescription =>
      'Every benefit you redeem is waiting for you here. In the wallet you can find the benefits you chose to redeem and open each benefit’s digital card. When you arrive at the business, show the digital card and enjoy your benefit.';

  @override
  String get tourProfileTitle => 'Profile';

  @override
  String get tourProfileDescription =>
      'This is your personal C2C profile. Here you can view and update the details you want other students to know about you. You can also change the app language and accessibility button, and view open surveys and the terms of use in the settings below.';

  @override
  String get tourReplayAction => 'Replay step-by-step guide';

  @override
  String get surveyAnswerRequired =>
      'Please answer all questions before submitting.';

  @override
  String get tourProfileButtonTitle => 'Profile';

  @override
  String get tourProfileButtonDescription =>
      'Here you can get to know the student a little better and see the details they chose to share on their profile, such as their field of study, languages, interests, and additional information about them.';

  @override
  String get demoChatBlockTitle => 'Block a user';

  @override
  String get demoChatBlockMessage =>
      'You can block this user from here. Once blocked, they won\'t be able to send you messages and you won\'t be able to send them messages either. You can block and unblock at any time by tapping the button.';

  @override
  String get demoChatMeetingTitle => 'Schedule a meeting';

  @override
  String get demoChatMeetingMessage =>
      'From here you can arrange a meeting with the student you\'re chatting with. Set up a meeting, meet on campus and earn points together! A first meeting with a new student earns each of you 25 points, a second meeting with the same student 20 points, and a third meeting 10 points. Please note: you can arrange one meeting per day with the same student, and up to 5 meetings with different students on the same day.';

  @override
  String get tourBenefitsStatusTitle => 'My status';

  @override
  String get tourBenefitsStatusDescription =>
      'Here you can see your points balance, progress toward the next benefit, and a shortcut to your digital wallet.';

  @override
  String get tourWalletTapDescription =>
      'Your digital wallet stores the benefits you redeemed. Tap My Wallet above or the wallet button to open it.';

  @override
  String get tourMatchesIntroTitle => 'Student Matching';

  @override
  String get tourMatchesIntroDescription =>
      'Here you can find students to get to know, see your compatibility score, chat with them, and arrange a one-to-one meeting through the app.';

  @override
  String get externalLinkOpenFailedCopied =>
      'Couldn\'t open the link — it was copied to your clipboard instead.';

  @override
  String get homeEventsNextMonth => 'Events in the Next Month';

  @override
  String get homeEmptyEventsNextMonth =>
      'No events in the next month right now.';

  @override
  String get eventFullNotice =>
      'The event is full. If additional spots become available, registration will reopen here.';

  @override
  String get eventFullAction => 'Event full';

  @override
  String get tourEventsNextMonthTitle => 'Events in the Next Month';

  @override
  String get tourEventsNextMonthDescription =>
      'This section shows only events taking place within the coming month — a quick look at what\'s happening soon.';

  @override
  String get tourUpcomingEventsTitle => 'All Events';

  @override
  String get tourUpcomingEventsDescription =>
      'This section shows all events currently open for registration, whenever they take place — including ones more than a month away. Tap an event to read the details and register.';

  @override
  String get authSpamFolderNote =>
      'If you can\'t find the email in your inbox, please check your spam folder.';

  @override
  String get errorSelectFaculty => 'Please select a faculty';

  @override
  String get errorSelectDegree => 'Please select a degree level';

  @override
  String get errorSelectGender => 'Please select a gender';

  @override
  String get errorSelectYearOfStudy => 'Please select your year of study';

  @override
  String get profileRequiredFieldsMissing =>
      'Please complete all required fields before continuing.';

  @override
  String get eventShareAction => 'Share event';

  @override
  String get eventShareCopyLink => 'Copy link';

  @override
  String get eventShareViaApps => 'Share via…';

  @override
  String get eventShareLinkCopied => 'Link copied to clipboard.';

  @override
  String get eventShareFailed => 'Couldn\'t share the event. Please try again.';

  @override
  String eventShareMessage(String title) {
    return '$title — see the event in the C2C app:';
  }

  @override
  String get eventNotFoundTitle => 'Event unavailable';

  @override
  String get eventNotFoundMessage =>
      'This event no longer exists, or it isn\'t available to your account.';

  @override
  String get proposeMeetingRespondError =>
      'Couldn\'t update the meeting. Please try again.';

  @override
  String get proposeMeetingAlreadyResponded =>
      'This meeting request has already been answered.';

  @override
  String notificationEventReminderTomorrow(String title) {
    return 'Tomorrow: $title';
  }

  @override
  String get notificationEventReminderTomorrowGeneric =>
      'You have an event tomorrow';

  @override
  String notificationEventReminderToday(String title) {
    return 'Today: $title';
  }

  @override
  String get notificationEventReminderTodayGeneric => 'You have an event today';

  @override
  String get eventReminderPopupTitleTomorrow => 'Your event is tomorrow';

  @override
  String get eventReminderPopupTitleToday => 'Your event is today';

  @override
  String get eventReminderPopupLocationLabel => 'Location';

  @override
  String get eventReminderPopupStartLabel => 'Starts';

  @override
  String get eventReminderPopupEndLabel => 'Ends';

  @override
  String get eventReminderPopupDismiss => 'Got it';

  @override
  String get eventReminderPopupOpenEvent => 'View event';

  @override
  String get programPendingApprovalStatus =>
      'Your registration request was sent. We will update you here once you are accepted to the event.';

  @override
  String get programAcceptedStatus => 'You have been accepted';

  @override
  String get profileFullNameWarning =>
      'Please note: enter your full name. This is the name event organizers will see, so use your full name rather than a nickname.';

  @override
  String get registerPendingApproval =>
      'Your registration request was sent and is waiting for approval.';

  @override
  String get eventPendingApprovalLabel => 'Awaiting approval';
}
