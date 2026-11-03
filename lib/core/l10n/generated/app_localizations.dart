import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('he'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'C2C'**
  String get appTitle;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageSelectionTitle;

  /// No description provided for @languageSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later from Settings.'**
  String get languageSelectionSubtitle;

  /// No description provided for @languageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languageContinue;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your campus, connected.'**
  String get welcomeSubtitle;

  /// No description provided for @tabSignup.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get tabSignup;

  /// No description provided for @tabLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get tabLogin;

  /// No description provided for @methodPassword.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get methodPassword;

  /// No description provided for @methodOtp.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email code'**
  String get methodOtp;

  /// No description provided for @fieldFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get fieldLastName;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@{domain}'**
  String emailHint(String domain);

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldPasswordSignupHint.
  ///
  /// In en, this message translates to:
  /// **'Password (min. 8 characters)'**
  String get fieldPasswordSignupHint;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get fieldConfirmPassword;

  /// No description provided for @buttonLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get buttonLogin;

  /// No description provided for @buttonSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send me a verification code'**
  String get buttonSendCode;

  /// No description provided for @buttonCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get buttonCreateAccount;

  /// No description provided for @linkForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get linkForgotPassword;

  /// No description provided for @domainNote.
  ///
  /// In en, this message translates to:
  /// **'Registration is only allowed with a {domain} email address.'**
  String domainNote(String domain);

  /// No description provided for @errorDomainNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only {domain} emails are allowed'**
  String errorDomainNotAllowed(String domain);

  /// No description provided for @errorEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get errorEnterEmail;

  /// No description provided for @errorEnterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get errorEnterFirstName;

  /// No description provided for @errorEnterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get errorEnterLastName;

  /// No description provided for @errorEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get errorEnterPassword;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get errorPasswordTooShort;

  /// No description provided for @errorPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorPasswordsDontMatch;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailNotConfirmedSendingCode.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before logging in. Sending a code…'**
  String get errorEmailNotConfirmedSendingCode;

  /// No description provided for @errorUserAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists — try logging in'**
  String get errorUserAlreadyExists;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email — sign up first'**
  String get errorUserNotFound;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyTitle;

  /// No description provided for @verifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to your email address. Enter it below to continue.'**
  String get verifySubtitle;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get otpHint;

  /// No description provided for @errorInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get errorInvalidOtp;

  /// No description provided for @errorOtpIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The code is incorrect or has expired.'**
  String get errorOtpIncorrect;

  /// No description provided for @errorBlockedUser.
  ///
  /// In en, this message translates to:
  /// **'This account has been blocked by C2C management due to a violation of the Terms of Use.'**
  String get errorBlockedUser;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @buttonVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get buttonVerify;

  /// No description provided for @linkResend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get a code? Resend'**
  String get linkResend;

  /// No description provided for @linkResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend available in {seconds}s'**
  String linkResendIn(int seconds);

  /// No description provided for @infoResent.
  ///
  /// In en, this message translates to:
  /// **'A new code was sent to your email.'**
  String get infoResent;

  /// No description provided for @linkBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get linkBackToLogin;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Password recovery'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a reset link to your email.'**
  String get forgotSubtitle;

  /// No description provided for @buttonSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get buttonSendResetLink;

  /// No description provided for @infoResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to your email.'**
  String get infoResetLinkSent;

  /// No description provided for @errorEnterUniversityEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get errorEnterUniversityEmail;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetTitle;

  /// No description provided for @fieldNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password (min. 8 characters)'**
  String get fieldNewPasswordHint;

  /// No description provided for @buttonUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get buttonUpdatePassword;

  /// No description provided for @infoPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Redirecting you to the app…'**
  String get infoPasswordUpdated;

  /// No description provided for @resetLinkInactive.
  ///
  /// In en, this message translates to:
  /// **'This reset link isn\'t active. Please request a new one from \"Forgot password\".'**
  String get resetLinkInactive;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Just a few details before you get started.'**
  String get completeProfileSubtitle;

  /// No description provided for @fieldFacultyOptional.
  ///
  /// In en, this message translates to:
  /// **'Faculty (optional)'**
  String get fieldFacultyOptional;

  /// No description provided for @fieldYearOptional.
  ///
  /// In en, this message translates to:
  /// **'Year (optional)'**
  String get fieldYearOptional;

  /// No description provided for @buttonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get buttonContinue;

  /// No description provided for @errorSaveProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get errorSaveProfileFailed;

  /// No description provided for @policyTitle.
  ///
  /// In en, this message translates to:
  /// **'Policy & Terms of Use'**
  String get policyTitle;

  /// No description provided for @policyVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String policyVersionLabel(int version);

  /// No description provided for @policyNoneActive.
  ///
  /// In en, this message translates to:
  /// **'No active policy right now.'**
  String get policyNoneActive;

  /// No description provided for @buttonAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms'**
  String get buttonAgree;

  /// No description provided for @buttonAlreadyAgreed.
  ///
  /// In en, this message translates to:
  /// **'You already agreed'**
  String get buttonAlreadyAgreed;

  /// No description provided for @buttonContinueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue to the app'**
  String get buttonContinueToApp;

  /// No description provided for @errorLoadPolicyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the policy.'**
  String get errorLoadPolicyFailed;

  /// No description provided for @errorAgreePolicyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your agreement. Please try again.'**
  String get errorAgreePolicyFailed;

  /// No description provided for @restrictedAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Access restricted'**
  String get restrictedAccessTitle;

  /// No description provided for @restrictedAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'This app is for students only. Your account doesn\'t have student access.'**
  String get restrictedAccessMessage;

  /// No description provided for @homeSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String homeSignedInAs(String email);

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeMyPoints.
  ///
  /// In en, this message translates to:
  /// **'My points'**
  String get homeMyPoints;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening today on campus?'**
  String get homeHeroTitle;

  /// No description provided for @homeMonthlyChampions.
  ///
  /// In en, this message translates to:
  /// **'Champions of the month'**
  String get homeMonthlyChampions;

  /// No description provided for @coachMarkNavHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get coachMarkNavHomeTitle;

  /// No description provided for @coachMarkNavHomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard — events, notifications, and what\'s new.'**
  String get coachMarkNavHomeDescription;

  /// No description provided for @coachMarkNavMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get coachMarkNavMatchesTitle;

  /// No description provided for @coachMarkNavMatchesDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover and connect with fellow students.'**
  String get coachMarkNavMatchesDescription;

  /// No description provided for @coachMarkNavScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get coachMarkNavScanTitle;

  /// No description provided for @coachMarkNavScanDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code to check in or earn points.'**
  String get coachMarkNavScanDescription;

  /// No description provided for @coachMarkNavBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get coachMarkNavBenefitsTitle;

  /// No description provided for @coachMarkNavBenefitsDescription.
  ///
  /// In en, this message translates to:
  /// **'Redeem your points for partner perks.'**
  String get coachMarkNavBenefitsDescription;

  /// No description provided for @coachMarkNavProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get coachMarkNavProfileTitle;

  /// No description provided for @coachMarkNavProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile and manage settings.'**
  String get coachMarkNavProfileDescription;

  /// No description provided for @coachMarkMyEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get coachMarkMyEventsTitle;

  /// No description provided for @coachMarkMyEventsDescription.
  ///
  /// In en, this message translates to:
  /// **'See the events and meetings you\'ve registered for.'**
  String get coachMarkMyEventsDescription;

  /// No description provided for @coachMarkUpcomingEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get coachMarkUpcomingEventsTitle;

  /// No description provided for @coachMarkUpcomingEventsDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse campus events happening soon.'**
  String get coachMarkUpcomingEventsDescription;

  /// No description provided for @coachMarkNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Multiple'**
  String get coachMarkNotificationsTitle;

  /// No description provided for @coachMarkNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Long-press a notification to select multiple items and mark them as read, unread, or delete them together.'**
  String get coachMarkNotificationsDescription;

  /// No description provided for @coachMarkChampionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Champions'**
  String get coachMarkChampionsTitle;

  /// No description provided for @coachMarkChampionsDescription.
  ///
  /// In en, this message translates to:
  /// **'See this month\'s top point earners.'**
  String get coachMarkChampionsDescription;

  /// No description provided for @homeMyNotifications.
  ///
  /// In en, this message translates to:
  /// **'My notifications'**
  String get homeMyNotifications;

  /// No description provided for @homeUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'All events'**
  String get homeUpcomingEvents;

  /// No description provided for @homeMyEventsCalendar.
  ///
  /// In en, this message translates to:
  /// **'My events calendar'**
  String get homeMyEventsCalendar;

  /// No description provided for @homeNewStudents.
  ///
  /// In en, this message translates to:
  /// **'New students'**
  String get homeNewStudents;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @actionSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get actionSeeMore;

  /// No description provided for @homeCampusEvents.
  ///
  /// In en, this message translates to:
  /// **'Campus events'**
  String get homeCampusEvents;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @filtersClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filtersClearAll;

  /// No description provided for @filtersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get filtersApply;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @eventUpcomingTag.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventUpcomingTag;

  /// No description provided for @eventRegisteredLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get eventRegisteredLabel;

  /// No description provided for @eventAttendedLabel.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get eventAttendedLabel;

  /// No description provided for @eventRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get eventRegisterAction;

  /// No description provided for @eventPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String eventPointsLabel(int points);

  /// No description provided for @homeEmptyEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events right now.'**
  String get homeEmptyEvents;

  /// No description provided for @homeEmptySurveys.
  ///
  /// In en, this message translates to:
  /// **'No surveys available right now.'**
  String get homeEmptySurveys;

  /// No description provided for @homeEmptyStudents.
  ///
  /// In en, this message translates to:
  /// **'No new students right now.'**
  String get homeEmptyStudents;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the home page. Please try again.'**
  String get homeLoadError;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re registered!'**
  String get registerSuccess;

  /// No description provided for @registerErrorAlready.
  ///
  /// In en, this message translates to:
  /// **'You\'re already registered for this event'**
  String get registerErrorAlready;

  /// No description provided for @registerErrorFull.
  ///
  /// In en, this message translates to:
  /// **'This event is full'**
  String get registerErrorFull;

  /// No description provided for @registerErrorEnded.
  ///
  /// In en, this message translates to:
  /// **'This event has already ended'**
  String get registerErrorEnded;

  /// No description provided for @registerErrorNotPublished.
  ///
  /// In en, this message translates to:
  /// **'This event isn\'t open for registration'**
  String get registerErrorNotPublished;

  /// No description provided for @registerErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get registerErrorNotFound;

  /// No description provided for @registerErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t register. Please try again.'**
  String get registerErrorGeneric;

  /// No description provided for @deleteEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get deleteEventTitle;

  /// No description provided for @deleteEventMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this event?'**
  String get deleteEventMessage;

  /// No description provided for @deleteEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteEventConfirm;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @deleteEventSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event deleted.'**
  String get deleteEventSuccess;

  /// No description provided for @deleteEventError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the event. Please try again.'**
  String get deleteEventError;

  /// No description provided for @registrantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Registrants'**
  String get registrantsTitle;

  /// No description provided for @registrantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one has registered yet.'**
  String get registrantsEmpty;

  /// No description provided for @registrantAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get registrantAttended;

  /// No description provided for @registrantRegisteredOnly.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registrantRegisteredOnly;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navBenefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get navBenefits;

  /// No description provided for @navScanning.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScanning;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @matchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchesTitle;

  /// No description provided for @matchesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No other students yet.'**
  String get matchesEmpty;

  /// No description provided for @matchesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load matches. Please try again.'**
  String get matchesLoadError;

  /// No description provided for @matchesConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect via QR'**
  String get matchesConnectAction;

  /// No description provided for @profileAboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAboutLabel;

  /// No description provided for @profileLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profileLanguagesLabel;

  /// No description provided for @profileMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get profileMessageAction;

  /// No description provided for @profileViewAction.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get profileViewAction;

  /// No description provided for @matchesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, hobby, or language...'**
  String get matchesSearchHint;

  /// No description provided for @matchesFilterToggle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get matchesFilterToggle;

  /// No description provided for @matchesSortToggle.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get matchesSortToggle;

  /// No description provided for @matchesSortHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Compatibility: high to low'**
  String get matchesSortHighToLow;

  /// No description provided for @matchesSortLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Compatibility: low to high'**
  String get matchesSortLowToHigh;

  /// No description provided for @matchesCompatibilityBadge.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String matchesCompatibilityBadge(int percent);

  /// No description provided for @matchesResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} student matches'**
  String matchesResultsCount(int count);

  /// No description provided for @matchesYearInline.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String matchesYearInline(int year);

  /// No description provided for @matchesSendHelloAction.
  ///
  /// In en, this message translates to:
  /// **'Send Hello'**
  String get matchesSendHelloAction;

  /// No description provided for @filterFacultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Faculty'**
  String get filterFacultyLabel;

  /// No description provided for @filterFieldOfStudyLabel.
  ///
  /// In en, this message translates to:
  /// **'Field of study'**
  String get filterFieldOfStudyLabel;

  /// No description provided for @filterDegreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get filterDegreeLabel;

  /// No description provided for @filterYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year of study'**
  String get filterYearLabel;

  /// No description provided for @filterLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get filterLanguageLabel;

  /// No description provided for @filterGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get filterGenderLabel;

  /// No description provided for @scanningTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanning & Points'**
  String get scanningTitle;

  /// No description provided for @scanTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan / Enter code'**
  String get scanTabLabel;

  /// No description provided for @scanCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Student ID'**
  String get scanCardTitle;

  /// No description provided for @scanCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show this to an event host if the QR code can\'t be scanned.'**
  String get scanCardSubtitle;

  /// No description provided for @scanEventQrAction.
  ///
  /// In en, this message translates to:
  /// **'Scan event QR'**
  String get scanEventQrAction;

  /// No description provided for @scanEventCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan with your device camera'**
  String get scanEventCameraTitle;

  /// No description provided for @scanEventGenericSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the QR code — it\'ll be detected automatically.'**
  String get scanEventGenericSubtitle;

  /// No description provided for @scanCameraPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'If the camera doesn\'t open, allow camera access in your device settings.'**
  String get scanCameraPermissionHint;

  /// No description provided for @scanAnotherAction.
  ///
  /// In en, this message translates to:
  /// **'Scan another'**
  String get scanAnotherAction;

  /// No description provided for @scanEventQrPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Which event?'**
  String get scanEventQrPickerTitle;

  /// No description provided for @scanEventQrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Register for an event first to check in with its QR code.'**
  String get scanEventQrEmpty;

  /// No description provided for @scanEnterCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get scanEnterCodeLabel;

  /// No description provided for @scanEnterCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get scanEnterCodeAction;

  /// No description provided for @scanEnterCodeError.
  ///
  /// In en, this message translates to:
  /// **'Enter a code first'**
  String get scanEnterCodeError;

  /// No description provided for @pointsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Points history'**
  String get pointsHistoryTitle;

  /// No description provided for @pointsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No points activity yet.'**
  String get pointsHistoryEmpty;

  /// No description provided for @pointsHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load points history.'**
  String get pointsHistoryLoadError;

  /// No description provided for @howToEarnTitle.
  ///
  /// In en, this message translates to:
  /// **'How to earn points'**
  String get howToEarnTitle;

  /// No description provided for @howToEarnEvent.
  ///
  /// In en, this message translates to:
  /// **'Event participation (scan the event\'s code during the activity): +20 each'**
  String get howToEarnEvent;

  /// No description provided for @howToEarnFirstMeeting.
  ///
  /// In en, this message translates to:
  /// **'First meeting with a new student: +25 each'**
  String get howToEarnFirstMeeting;

  /// No description provided for @howToEarnSecondMeeting.
  ///
  /// In en, this message translates to:
  /// **'Second meeting with the same student: +20 each'**
  String get howToEarnSecondMeeting;

  /// No description provided for @howToEarnRepeatMeeting.
  ///
  /// In en, this message translates to:
  /// **'Third meeting onward with the same student: +10 each'**
  String get howToEarnRepeatMeeting;

  /// No description provided for @reasonEventAttendance.
  ///
  /// In en, this message translates to:
  /// **'Event participation'**
  String get reasonEventAttendance;

  /// No description provided for @reasonMeetingFirst.
  ///
  /// In en, this message translates to:
  /// **'First meeting'**
  String get reasonMeetingFirst;

  /// No description provided for @reasonMeetingSecond.
  ///
  /// In en, this message translates to:
  /// **'Second meeting'**
  String get reasonMeetingSecond;

  /// No description provided for @reasonMeetingRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat meeting'**
  String get reasonMeetingRepeat;

  /// No description provided for @reasonGroupMeeting.
  ///
  /// In en, this message translates to:
  /// **'Group meeting'**
  String get reasonGroupMeeting;

  /// No description provided for @reasonMonthlyPrize.
  ///
  /// In en, this message translates to:
  /// **'Monthly prize'**
  String get reasonMonthlyPrize;

  /// No description provided for @reasonBenefitRedeem.
  ///
  /// In en, this message translates to:
  /// **'Benefit redeemed'**
  String get reasonBenefitRedeem;

  /// No description provided for @reasonGeneric.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get reasonGeneric;

  /// No description provided for @championsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly champions'**
  String get championsTabLabel;

  /// No description provided for @championsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Champions'**
  String get championsTitle;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get actionGotIt;

  /// No description provided for @championsHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'This month\'s ranking'**
  String get championsHeroLabel;

  /// No description provided for @championsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'This month\'s champions'**
  String get championsHeroTitle;

  /// No description provided for @championsMyRankLabel.
  ///
  /// In en, this message translates to:
  /// **'My ranking'**
  String get championsMyRankLabel;

  /// No description provided for @championsMyPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'My points this month'**
  String get championsMyPointsLabel;

  /// No description provided for @championsGapLabel.
  ///
  /// In en, this message translates to:
  /// **'{gap} points to pass {name}'**
  String championsGapLabel(int gap, String name);

  /// No description provided for @championsUnranked.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t earned any points this month yet.'**
  String get championsUnranked;

  /// No description provided for @championsListTitle.
  ///
  /// In en, this message translates to:
  /// **'This month\'s points'**
  String get championsListTitle;

  /// No description provided for @championsHeroMonthPrefix.
  ///
  /// In en, this message translates to:
  /// **'Champions'**
  String get championsHeroMonthPrefix;

  /// No description provided for @championsUpdateFrequency.
  ///
  /// In en, this message translates to:
  /// **'Updated monthly'**
  String get championsUpdateFrequency;

  /// No description provided for @championsTableRankCol.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get championsTableRankCol;

  /// No description provided for @championsTableNameCol.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get championsTableNameCol;

  /// No description provided for @championsTablePointsCol.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get championsTablePointsCol;

  /// No description provided for @championsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ranking yet this month.'**
  String get championsEmpty;

  /// No description provided for @championsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the leaderboard.'**
  String get championsLoadError;

  /// No description provided for @adminAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this page.'**
  String get adminAccessDenied;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @eventTypeSingle.
  ///
  /// In en, this message translates to:
  /// **'One-Time'**
  String get eventTypeSingle;

  /// No description provided for @eventTypeProgram.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get eventTypeProgram;

  /// No description provided for @eventFiltersButton.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get eventFiltersButton;

  /// No description provided for @eventFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter events'**
  String get eventFiltersTitle;

  /// No description provided for @eventFilterTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get eventFilterTypeLabel;

  /// No description provided for @eventFilterCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get eventFilterCategoryLabel;

  /// No description provided for @eventFilterOrganizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get eventFilterOrganizerLabel;

  /// No description provided for @eventFiltersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get eventFiltersApply;

  /// No description provided for @eventFiltersReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get eventFiltersReset;

  /// No description provided for @eventDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'About this event'**
  String get eventDescriptionLabel;

  /// No description provided for @eventCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel registration'**
  String get eventCancelAction;

  /// No description provided for @eventEndedLabel.
  ///
  /// In en, this message translates to:
  /// **'This event has ended'**
  String get eventEndedLabel;

  /// No description provided for @cancelEventRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel registration?'**
  String get cancelEventRegistrationTitle;

  /// No description provided for @cancelEventRegistrationMessage.
  ///
  /// In en, this message translates to:
  /// **'You can register again later if you change your mind.'**
  String get cancelEventRegistrationMessage;

  /// No description provided for @cancelEventRegistrationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel registration'**
  String get cancelEventRegistrationConfirm;

  /// No description provided for @cancelEventRegistrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration cancelled.'**
  String get cancelEventRegistrationSuccess;

  /// No description provided for @cancelEventRegistrationError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel your registration.'**
  String get cancelEventRegistrationError;

  /// No description provided for @myEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEventsTitle;

  /// No description provided for @myEventsFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get myEventsFilterUpcoming;

  /// No description provided for @myEventsFilterAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get myEventsFilterAttended;

  /// No description provided for @myEventsFilterMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get myEventsFilterMissed;

  /// No description provided for @myEventsAttendedMessage.
  ///
  /// In en, this message translates to:
  /// **'Great job! We\'re proud that you joined!'**
  String get myEventsAttendedMessage;

  /// No description provided for @myEventsMissedMessage.
  ///
  /// In en, this message translates to:
  /// **'We missed you! It\'s a shame you couldn\'t join us.'**
  String get myEventsMissedMessage;

  /// No description provided for @myEventsUpcomingMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'re looking forward to seeing you!'**
  String get myEventsUpcomingMessage;

  /// No description provided for @myEventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t registered for any events yet.'**
  String get myEventsEmpty;

  /// No description provided for @myEventsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your events.'**
  String get myEventsLoadError;

  /// No description provided for @eventEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get eventEditAction;

  /// No description provided for @eventFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get eventFormCreateTitle;

  /// No description provided for @eventFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get eventFormEditTitle;

  /// No description provided for @eventFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get eventFormTitleLabel;

  /// No description provided for @eventFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eventFormDescriptionLabel;

  /// No description provided for @eventFormCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get eventFormCategoryLabel;

  /// No description provided for @eventFormLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventFormLocationLabel;

  /// No description provided for @eventFormStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get eventFormStartLabel;

  /// No description provided for @eventFormEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get eventFormEndLabel;

  /// No description provided for @eventFormPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get eventFormPointsLabel;

  /// No description provided for @eventFormCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity (optional)'**
  String get eventFormCapacityLabel;

  /// No description provided for @eventFormImageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL (optional)'**
  String get eventFormImageUrlLabel;

  /// No description provided for @eventFormOrganizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Organizer name (optional)'**
  String get eventFormOrganizerLabel;

  /// No description provided for @eventFormVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Who can see this event?'**
  String get eventFormVisibilityLabel;

  /// No description provided for @eventVisibilityOnlyMe.
  ///
  /// In en, this message translates to:
  /// **'Only Me'**
  String get eventVisibilityOnlyMe;

  /// No description provided for @eventVisibilityEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get eventVisibilityEveryone;

  /// No description provided for @eventVisibilitySpecificFaculties.
  ///
  /// In en, this message translates to:
  /// **'Specific Faculties'**
  String get eventVisibilitySpecificFaculties;

  /// No description provided for @eventVisibilitySpecificGroups.
  ///
  /// In en, this message translates to:
  /// **'Specific Groups'**
  String get eventVisibilitySpecificGroups;

  /// No description provided for @eventFormFacultiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Select faculties'**
  String get eventFormFacultiesLabel;

  /// No description provided for @eventFormGroupTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Group tags (comma separated)'**
  String get eventFormGroupTagsLabel;

  /// No description provided for @eventFormErrorTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get eventFormErrorTitleRequired;

  /// No description provided for @eventFormErrorDatesRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a start and end time'**
  String get eventFormErrorDatesRequired;

  /// No description provided for @eventFormErrorEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after the start time'**
  String get eventFormErrorEndBeforeStart;

  /// No description provided for @eventFormErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the event. Please check the details and try again.'**
  String get eventFormErrorGeneric;

  /// No description provided for @eventFormSubmitCreate.
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get eventFormSubmitCreate;

  /// No description provided for @eventFormSubmitUpdate.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get eventFormSubmitUpdate;

  /// No description provided for @eventShowQrAction.
  ///
  /// In en, this message translates to:
  /// **'Show QR'**
  String get eventShowQrAction;

  /// No description provided for @eventQrScanningLabel.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get eventQrScanningLabel;

  /// No description provided for @eventQrRefreshesIn.
  ///
  /// In en, this message translates to:
  /// **'Refreshes in {seconds}s'**
  String eventQrRefreshesIn(int seconds);

  /// No description provided for @eventQrLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate a QR code.'**
  String get eventQrLoadError;

  /// No description provided for @eventQrHint.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to students during the event. It refreshes every 10 seconds.'**
  String get eventQrHint;

  /// No description provided for @eventScanningClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'Scanning is closed.'**
  String get eventScanningClosedMessage;

  /// No description provided for @eventScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to Check In'**
  String get eventScanTitle;

  /// No description provided for @eventScanGenericHeading.
  ///
  /// In en, this message translates to:
  /// **'Scan any event\'s QR code to check in'**
  String get eventScanGenericHeading;

  /// No description provided for @eventScanToCheckInAction.
  ///
  /// In en, this message translates to:
  /// **'Scan to check in'**
  String get eventScanToCheckInAction;

  /// No description provided for @eventScanSuccess.
  ///
  /// In en, this message translates to:
  /// **'You earned {points} points!'**
  String eventScanSuccess(int points);

  /// No description provided for @eventScanErrorExpired.
  ///
  /// In en, this message translates to:
  /// **'You scanned after the time limit.'**
  String get eventScanErrorExpired;

  /// No description provided for @eventScanErrorAlreadyScanned.
  ///
  /// In en, this message translates to:
  /// **'You have already scanned this event. You cannot scan it again.'**
  String get eventScanErrorAlreadyScanned;

  /// No description provided for @eventScanErrorNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'You need to register for this event before scanning.'**
  String get eventScanErrorNotRegistered;

  /// No description provided for @eventScanErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code.'**
  String get eventScanErrorInvalid;

  /// No description provided for @eventStatsRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get eventStatsRegistered;

  /// No description provided for @eventStatsAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get eventStatsAttended;

  /// No description provided for @eventStatsMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get eventStatsMissed;

  /// No description provided for @programPointsEquation.
  ///
  /// In en, this message translates to:
  /// **'{points} Points × {count} Sessions = {total} Possible Points'**
  String programPointsEquation(int points, int count, int total);

  /// No description provided for @programSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get programSessionsTitle;

  /// No description provided for @programSessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet.'**
  String get programSessionsEmpty;

  /// No description provided for @programSessionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load sessions.'**
  String get programSessionsLoadError;

  /// No description provided for @programManageSessionsAction.
  ///
  /// In en, this message translates to:
  /// **'Manage Sessions'**
  String get programManageSessionsAction;

  /// No description provided for @programViewSessionsAction.
  ///
  /// In en, this message translates to:
  /// **'View Sessions'**
  String get programViewSessionsAction;

  /// No description provided for @programAttendanceProgress.
  ///
  /// In en, this message translates to:
  /// **'Attended {attended} of {total} sessions'**
  String programAttendanceProgress(int attended, int total);

  /// No description provided for @programAttendedAllSessions.
  ///
  /// In en, this message translates to:
  /// **'You attended every session!'**
  String get programAttendedAllSessions;

  /// No description provided for @programSessionsFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get programSessionsFormTitle;

  /// No description provided for @programSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get programSessionLabel;

  /// No description provided for @programAddSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Add another session'**
  String get programAddSessionAction;

  /// No description provided for @eventFormErrorSessionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one session'**
  String get eventFormErrorSessionsRequired;

  /// No description provided for @eventFormErrorSessionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Fill in the title and both times for every session'**
  String get eventFormErrorSessionIncomplete;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @chatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.'**
  String get chatsEmpty;

  /// No description provided for @chatsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get chatsSearchHint;

  /// No description provided for @chatsSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chats match your search.'**
  String get chatsSearchEmpty;

  /// No description provided for @chatsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your chats.'**
  String get chatsLoadError;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatMessageHint;

  /// No description provided for @chatBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatBlockAction;

  /// No description provided for @chatUnblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get chatUnblockAction;

  /// No description provided for @chatBlockedBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'ve blocked this user. Unblock to send messages.'**
  String get chatBlockedBanner;

  /// No description provided for @chatBlockedByOtherBanner.
  ///
  /// In en, this message translates to:
  /// **'You can\'t send messages in this conversation.'**
  String get chatBlockedByOtherBanner;

  /// No description provided for @chatBlockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get chatBlockConfirmTitle;

  /// No description provided for @chatBlockConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to message you until you unblock them.'**
  String get chatBlockConfirmMessage;

  /// No description provided for @chatEmptyThread.
  ///
  /// In en, this message translates to:
  /// **'Say hello 👋'**
  String get chatEmptyThread;

  /// No description provided for @chatDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatDateToday;

  /// No description provided for @chatDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatDateYesterday;

  /// No description provided for @proposeMeetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Propose a meeting'**
  String get proposeMeetingTitle;

  /// No description provided for @proposeMeetingPickDateTime.
  ///
  /// In en, this message translates to:
  /// **'Pick date & time'**
  String get proposeMeetingPickDateTime;

  /// No description provided for @proposeMeetingPickEndDateTime.
  ///
  /// In en, this message translates to:
  /// **'Pick end time'**
  String get proposeMeetingPickEndDateTime;

  /// No description provided for @proposeMeetingNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get proposeMeetingNotesLabel;

  /// No description provided for @proposeMeetingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send proposal'**
  String get proposeMeetingSubmit;

  /// No description provided for @proposeMeetingErrorDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a date and time'**
  String get proposeMeetingErrorDateRequired;

  /// No description provided for @proposeMeetingErrorEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after the start time'**
  String get proposeMeetingErrorEndBeforeStart;

  /// No description provided for @proposeMeetingError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the proposal'**
  String get proposeMeetingError;

  /// No description provided for @proposeMeetingErrorSameStudentToday.
  ///
  /// In en, this message translates to:
  /// **'You already have a meeting with this student on that day. You can meet the same student once per day.'**
  String get proposeMeetingErrorSameStudentToday;

  /// No description provided for @proposeMeetingErrorDailyLimitSelf.
  ///
  /// In en, this message translates to:
  /// **'You already have meetings with 5 different students on that day, which is the daily limit. Try another date.'**
  String get proposeMeetingErrorDailyLimitSelf;

  /// No description provided for @proposeMeetingErrorDailyLimitOther.
  ///
  /// In en, this message translates to:
  /// **'This student already has meetings with 5 different students on that day. Try another date.'**
  String get proposeMeetingErrorDailyLimitOther;

  /// No description provided for @proposeMeetingCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Meeting proposal'**
  String get proposeMeetingCardTitle;

  /// No description provided for @proposeMeetingAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get proposeMeetingAccept;

  /// No description provided for @proposeMeetingDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get proposeMeetingDecline;

  /// No description provided for @proposeMeetingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for response…'**
  String get proposeMeetingWaiting;

  /// No description provided for @proposeMeetingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get proposeMeetingAccepted;

  /// No description provided for @proposeMeetingDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get proposeMeetingDeclined;

  /// No description provided for @reportUserAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportUserAction;

  /// No description provided for @reportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportUserTitle(String name);

  /// No description provided for @reportUserReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportUserReasonLabel;

  /// No description provided for @reportUserDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportUserDetailsLabel;

  /// No description provided for @reportUserErrorReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason'**
  String get reportUserErrorReasonRequired;

  /// No description provided for @reportUserErrorDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter some details'**
  String get reportUserErrorDetailsRequired;

  /// No description provided for @reportUserImagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Screenshots (optional)'**
  String get reportUserImagesLabel;

  /// No description provided for @reportUserAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get reportUserAddImage;

  /// No description provided for @reportUserSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportUserSubmit;

  /// No description provided for @reportUserSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted.'**
  String get reportUserSuccess;

  /// No description provided for @reportUserError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit the report.'**
  String get reportUserError;

  /// No description provided for @groupMeetingListEntryPoint.
  ///
  /// In en, this message translates to:
  /// **'Group meetings'**
  String get groupMeetingListEntryPoint;

  /// No description provided for @groupMeetingListTitle.
  ///
  /// In en, this message translates to:
  /// **'My Group Meetings'**
  String get groupMeetingListTitle;

  /// No description provided for @groupMeetingCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New group meeting'**
  String get groupMeetingCreateAction;

  /// No description provided for @groupMeetingListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your group meetings.'**
  String get groupMeetingListLoadError;

  /// No description provided for @groupMeetingListEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no group meetings yet.'**
  String get groupMeetingListEmpty;

  /// No description provided for @groupMeetingStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get groupMeetingStatusApproved;

  /// No description provided for @groupMeetingStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get groupMeetingStatusRejected;

  /// No description provided for @groupMeetingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get groupMeetingStatusPending;

  /// No description provided for @groupMeetingRoleOrganizer.
  ///
  /// In en, this message translates to:
  /// **'You\'re organizing this meeting'**
  String get groupMeetingRoleOrganizer;

  /// No description provided for @groupMeetingRoleParticipant.
  ///
  /// In en, this message translates to:
  /// **'Organized by {name}'**
  String groupMeetingRoleParticipant(String name);

  /// No description provided for @groupMeetingFinishedTag.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get groupMeetingFinishedTag;

  /// No description provided for @groupMeetingShowQrAction.
  ///
  /// In en, this message translates to:
  /// **'Show QR'**
  String get groupMeetingShowQrAction;

  /// No description provided for @groupMeetingScanAction.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get groupMeetingScanAction;

  /// No description provided for @groupMeetingEnterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a code'**
  String get groupMeetingEnterCodeTitle;

  /// No description provided for @groupMeetingEnterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the code shared by the organizer'**
  String get groupMeetingEnterCodeHint;

  /// No description provided for @groupMeetingEnterCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get groupMeetingEnterCodeAction;

  /// No description provided for @groupMeetingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Group Meeting'**
  String get groupMeetingCreateTitle;

  /// No description provided for @groupMeetingCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Your request goes to an admin for approval before a registration link is created.'**
  String get groupMeetingCreateHint;

  /// No description provided for @groupMeetingLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get groupMeetingLocationLabel;

  /// No description provided for @groupMeetingLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Group meetings must take place on TAU campus.'**
  String get groupMeetingLocationHint;

  /// No description provided for @groupMeetingLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please choose a campus location.'**
  String get groupMeetingLocationRequired;

  /// No description provided for @groupMeetingMaxParticipantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Max participants: {count}'**
  String groupMeetingMaxParticipantsLabel(int count);

  /// No description provided for @groupMeetingCreateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get groupMeetingCreateSubmit;

  /// No description provided for @groupMeetingCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your group meeting request was submitted.'**
  String get groupMeetingCreateSuccess;

  /// No description provided for @groupMeetingCreateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit your request.'**
  String get groupMeetingCreateError;

  /// No description provided for @groupMeetingRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Meeting'**
  String get groupMeetingRegistrationTitle;

  /// No description provided for @groupMeetingRegistrationInvalid.
  ///
  /// In en, this message translates to:
  /// **'This link is invalid or has expired.'**
  String get groupMeetingRegistrationInvalid;

  /// No description provided for @groupMeetingRegisteredCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} registered'**
  String groupMeetingRegisteredCount(int count, int max);

  /// No description provided for @groupMeetingRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get groupMeetingRegisterAction;

  /// No description provided for @groupMeetingRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re registered!'**
  String get groupMeetingRegisterSuccess;

  /// No description provided for @groupMeetingAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'You\'re already registered for this meeting.'**
  String get groupMeetingAlreadyRegistered;

  /// No description provided for @groupMeetingRegisterErrorFull.
  ///
  /// In en, this message translates to:
  /// **'This meeting is full.'**
  String get groupMeetingRegisterErrorFull;

  /// No description provided for @groupMeetingRegisterErrorAlready.
  ///
  /// In en, this message translates to:
  /// **'You\'re already registered.'**
  String get groupMeetingRegisterErrorAlready;

  /// No description provided for @groupMeetingRegisterErrorOwn.
  ///
  /// In en, this message translates to:
  /// **'You\'re the organizer of this meeting.'**
  String get groupMeetingRegisterErrorOwn;

  /// No description provided for @groupMeetingRegisterErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t register for this meeting.'**
  String get groupMeetingRegisterErrorGeneric;

  /// No description provided for @groupMeetingQrHint.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to participants. It refreshes every 10 seconds.'**
  String get groupMeetingQrHint;

  /// No description provided for @groupMeetingFinishAction.
  ///
  /// In en, this message translates to:
  /// **'Finish meeting'**
  String get groupMeetingFinishAction;

  /// No description provided for @groupMeetingFinishError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish the meeting.'**
  String get groupMeetingFinishError;

  /// No description provided for @groupMeetingFinishDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Meeting finished'**
  String get groupMeetingFinishDialogTitle;

  /// No description provided for @groupMeetingFinishDialogOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get groupMeetingFinishDialogOk;

  /// No description provided for @groupMeetingFinishOutcomeNone.
  ///
  /// In en, this message translates to:
  /// **'Nobody scanned in, so no points were awarded.'**
  String get groupMeetingFinishOutcomeNone;

  /// No description provided for @groupMeetingFinishOutcomeOneToOne.
  ///
  /// In en, this message translates to:
  /// **'Only one person scanned in, so this counted as a 1:1 meeting — you both earned {points} points.'**
  String groupMeetingFinishOutcomeOneToOne(int points);

  /// No description provided for @groupMeetingFinishOutcomeCapped.
  ///
  /// In en, this message translates to:
  /// **'Only one person scanned in, so this counted as a 1:1 meeting — but today\'s cap for that pair was already reached, so no points were awarded.'**
  String get groupMeetingFinishOutcomeCapped;

  /// No description provided for @groupMeetingFinishOutcomeGroup.
  ///
  /// In en, this message translates to:
  /// **'You earned {organizerPoints} points, and {scanners} participants each earned points.'**
  String groupMeetingFinishOutcomeGroup(int organizerPoints, int scanners);

  /// No description provided for @groupMeetingScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to Join'**
  String get groupMeetingScanTitle;

  /// No description provided for @groupMeetingScanSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'ve joined the meeting!'**
  String get groupMeetingScanSuccess;

  /// No description provided for @groupMeetingScanErrorOwnCode.
  ///
  /// In en, this message translates to:
  /// **'You can\'t scan your own QR code.'**
  String get groupMeetingScanErrorOwnCode;

  /// No description provided for @benefitsCatalogTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get benefitsCatalogTabLabel;

  /// No description provided for @benefitsWalletTabLabel.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get benefitsWalletTabLabel;

  /// No description provided for @benefitsPointsBalance.
  ///
  /// In en, this message translates to:
  /// **'You have {points} points'**
  String benefitsPointsBalance(int points);

  /// No description provided for @benefitsCatalogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the benefits catalog.'**
  String get benefitsCatalogLoadError;

  /// No description provided for @benefitsCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No benefits available right now.'**
  String get benefitsCatalogEmpty;

  /// No description provided for @benefitsWalletLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your wallet.'**
  String get benefitsWalletLoadError;

  /// No description provided for @benefitsWalletEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t redeemed any benefits yet.'**
  String get benefitsWalletEmpty;

  /// No description provided for @benefitsWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'My Digital Wallet'**
  String get benefitsWalletTitle;

  /// No description provided for @benefitsWalletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All your digital cards in one place'**
  String get benefitsWalletSubtitle;

  /// No description provided for @benefitsWalletPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points balance'**
  String get benefitsWalletPointsLabel;

  /// No description provided for @benefitsWalletFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get benefitsWalletFilterAll;

  /// No description provided for @benefitsWalletFilterNotUsed.
  ///
  /// In en, this message translates to:
  /// **'Not used'**
  String get benefitsWalletFilterNotUsed;

  /// No description provided for @benefitsWalletFilterUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get benefitsWalletFilterUsed;

  /// No description provided for @benefitsWalletFilterButton.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get benefitsWalletFilterButton;

  /// No description provided for @benefitsWalletFilterByBusiness.
  ///
  /// In en, this message translates to:
  /// **'Filter by business'**
  String get benefitsWalletFilterByBusiness;

  /// No description provided for @benefitsWalletFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get benefitsWalletFilterClear;

  /// No description provided for @benefitsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'My status'**
  String get benefitsStatusLabel;

  /// No description provided for @benefitsCatalogHeading.
  ///
  /// In en, this message translates to:
  /// **'Convert points to benefits'**
  String get benefitsCatalogHeading;

  /// No description provided for @benefitsOpenWalletAction.
  ///
  /// In en, this message translates to:
  /// **'My Digital Wallet'**
  String get benefitsOpenWalletAction;

  /// No description provided for @benefitsCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get benefitsCategoryAll;

  /// No description provided for @benefitPointCost.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String benefitPointCost(int points);

  /// No description provided for @benefitRedeemAction.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get benefitRedeemAction;

  /// No description provided for @benefitNotEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'Not enough points'**
  String get benefitNotEnoughPoints;

  /// No description provided for @benefitAlreadyActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'In your wallet'**
  String get benefitAlreadyActiveLabel;

  /// No description provided for @benefitAlreadyActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'You have a digital card in your wallet for this benefit.'**
  String get benefitAlreadyActiveMessage;

  /// No description provided for @benefitRedeemConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Redeem benefit'**
  String get benefitRedeemConfirmTitle;

  /// No description provided for @benefitRedeemConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Redeem \"{title}\" for {points} points?'**
  String benefitRedeemConfirmMessage(String title, int points);

  /// No description provided for @benefitRedeemErrorInsufficientPoints.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough points for this benefit.'**
  String get benefitRedeemErrorInsufficientPoints;

  /// No description provided for @benefitRedeemErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This benefit is no longer available.'**
  String get benefitRedeemErrorUnavailable;

  /// No description provided for @benefitRedeemErrorAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'You already have a digital card in your wallet for this benefit.'**
  String get benefitRedeemErrorAlreadyActive;

  /// No description provided for @benefitRedeemErrorNotAStudent.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t redeem benefits — only student accounts can.'**
  String get benefitRedeemErrorNotAStudent;

  /// No description provided for @benefitRedeemErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t redeem this benefit.'**
  String get benefitRedeemErrorGeneric;

  /// No description provided for @benefitCardRedeemedTag.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get benefitCardRedeemedTag;

  /// No description provided for @benefitCardAvailableTag.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get benefitCardAvailableTag;

  /// No description provided for @benefitCardStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get benefitCardStatusLabel;

  /// No description provided for @benefitCardOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Digital Card'**
  String get benefitCardOpenAction;

  /// No description provided for @benefitCardShowHint.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to the partner to redeem.'**
  String get benefitCardShowHint;

  /// No description provided for @benefitCardCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Or give this code if the QR can\'t be scanned'**
  String get benefitCardCodeLabel;

  /// No description provided for @benefitCardAcquiredOn.
  ///
  /// In en, this message translates to:
  /// **'Redeemed with points on {date}'**
  String benefitCardAcquiredOn(String date);

  /// No description provided for @benefitCardRedeemedOn.
  ///
  /// In en, this message translates to:
  /// **'Used at partner on {date}'**
  String benefitCardRedeemedOn(String date);

  /// No description provided for @supportContactsRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get supportContactsRowLabel;

  /// No description provided for @supportContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get supportContactsTitle;

  /// No description provided for @supportContactsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load support contacts.'**
  String get supportContactsError;

  /// No description provided for @supportContactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No support contacts have been set up yet.'**
  String get supportContactsEmpty;

  /// No description provided for @supportContactsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy phone number'**
  String get supportContactsCopy;

  /// No description provided for @supportContactsCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get supportContactsCopied;

  /// No description provided for @benefitFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Benefit'**
  String get benefitFormCreateTitle;

  /// No description provided for @benefitFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Benefit'**
  String get benefitFormEditTitle;

  /// No description provided for @benefitFormPartnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner business name'**
  String get benefitFormPartnerLabel;

  /// No description provided for @benefitFormImageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get benefitFormImageUrlLabel;

  /// No description provided for @benefitFormPointCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Point cost'**
  String get benefitFormPointCostLabel;

  /// No description provided for @benefitFormErrorPointCostInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a point cost greater than 0'**
  String get benefitFormErrorPointCostInvalid;

  /// No description provided for @benefitFormCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create benefit'**
  String get benefitFormCreateAction;

  /// No description provided for @benefitFormSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get benefitFormSaveAction;

  /// No description provided for @benefitProfileAboutBenefit.
  ///
  /// In en, this message translates to:
  /// **'About this benefit'**
  String get benefitProfileAboutBenefit;

  /// No description provided for @benefitProfileAboutBusiness.
  ///
  /// In en, this message translates to:
  /// **'About the business'**
  String get benefitProfileAboutBusiness;

  /// No description provided for @benefitProfileHowToRedeem.
  ///
  /// In en, this message translates to:
  /// **'How to redeem'**
  String get benefitProfileHowToRedeem;

  /// No description provided for @benefitProfileLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get benefitProfileLinkLabel;

  /// No description provided for @benefitProfileOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get benefitProfileOpenLink;

  /// No description provided for @benefitProfileLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get benefitProfileLocationLabel;

  /// No description provided for @benefitProfileOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get benefitProfileOpenMaps;

  /// No description provided for @benefitProfileCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get benefitProfileCategoryLabel;

  /// No description provided for @benefitProfileCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Points cost'**
  String get benefitProfileCostLabel;

  /// No description provided for @benefitFormSectionBasics.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get benefitFormSectionBasics;

  /// No description provided for @benefitFormSectionBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business info'**
  String get benefitFormSectionBusiness;

  /// No description provided for @benefitFormSectionRedemption.
  ///
  /// In en, this message translates to:
  /// **'Redemption details'**
  String get benefitFormSectionRedemption;

  /// No description provided for @benefitFormSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get benefitFormSectionLocation;

  /// No description provided for @benefitFormBusinessDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Business description'**
  String get benefitFormBusinessDescriptionLabel;

  /// No description provided for @benefitFormHowToRedeemLabel.
  ///
  /// In en, this message translates to:
  /// **'How to redeem'**
  String get benefitFormHowToRedeemLabel;

  /// No description provided for @benefitFormExternalLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'External link (Instagram, website, …)'**
  String get benefitFormExternalLinkLabel;

  /// No description provided for @benefitFormLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get benefitFormLocationLabel;

  /// No description provided for @benefitFormMapsLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Google Maps link'**
  String get benefitFormMapsLinkLabel;

  /// No description provided for @benefitFormImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Benefit image'**
  String get benefitFormImageLabel;

  /// No description provided for @benefitFormEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get benefitFormEditAction;

  /// No description provided for @benefitDigitalCardSection.
  ///
  /// In en, this message translates to:
  /// **'Digital card'**
  String get benefitDigitalCardSection;

  /// No description provided for @benefitDigitalCardPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview digital card'**
  String get benefitDigitalCardPreviewAction;

  /// No description provided for @benefitDigitalCardPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital card preview'**
  String get benefitDigitalCardPreviewTitle;

  /// No description provided for @benefitDigitalCardPreviewNote.
  ///
  /// In en, this message translates to:
  /// **'This is exactly how the card will look in a student\'s wallet.'**
  String get benefitDigitalCardPreviewNote;

  /// No description provided for @benefitCardSampleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student name'**
  String get benefitCardSampleStudent;

  /// No description provided for @benefitCardStudentLabel.
  ///
  /// In en, this message translates to:
  /// **'Cardholder'**
  String get benefitCardStudentLabel;

  /// No description provided for @notificationEventPending.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is waiting for your approval'**
  String notificationEventPending(String title);

  /// No description provided for @notificationEventPendingGeneric.
  ///
  /// In en, this message translates to:
  /// **'An event is waiting for your approval'**
  String get notificationEventPendingGeneric;

  /// No description provided for @eventProfileOrganizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get eventProfileOrganizerLabel;

  /// No description provided for @eventProfilePointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points awarded'**
  String get eventProfilePointsLabel;

  /// No description provided for @eventProfileDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Event description'**
  String get eventProfileDescriptionLabel;

  /// No description provided for @eventProfileLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventProfileLocationLabel;

  /// No description provided for @eventProfileScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get eventProfileScheduleLabel;

  /// No description provided for @eventProfileOrganizerDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'About the organizer'**
  String get eventProfileOrganizerDescriptionLabel;

  /// No description provided for @eventProfileExternalLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'External link'**
  String get eventProfileExternalLinkLabel;

  /// No description provided for @eventProfileCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get eventProfileCategoryLabel;

  /// No description provided for @eventProfileSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Program sessions'**
  String get eventProfileSessionsLabel;

  /// No description provided for @eventProfileSessionColumn.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get eventProfileSessionColumn;

  /// No description provided for @eventProfileWhenColumn.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get eventProfileWhenColumn;

  /// No description provided for @eventProfileWhereColumn.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get eventProfileWhereColumn;

  /// No description provided for @eventProfileStatusColumn.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get eventProfileStatusColumn;

  /// No description provided for @eventProfileSessionMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get eventProfileSessionMissed;

  /// No description provided for @eventProfileSessionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventProfileSessionUpcoming;

  /// No description provided for @eventProfileTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} points for completing the program'**
  String eventProfileTotalPoints(int points);

  /// No description provided for @eventProfileSessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String eventProfileSessionCount(int count);

  /// No description provided for @eventProfilePerSessionPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} points per session'**
  String eventProfilePerSessionPoints(int points);

  /// No description provided for @eventProfileReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review event'**
  String get eventProfileReviewTitle;

  /// No description provided for @eventFormImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Event image'**
  String get eventFormImageLabel;

  /// No description provided for @notificationEventPublished.
  ///
  /// In en, this message translates to:
  /// **'New event: {title}'**
  String notificationEventPublished(String title);

  /// No description provided for @notificationEventPublishedGeneric.
  ///
  /// In en, this message translates to:
  /// **'A new event was published'**
  String get notificationEventPublishedGeneric;

  /// No description provided for @notificationBenefitPublished.
  ///
  /// In en, this message translates to:
  /// **'New benefit: {title}'**
  String notificationBenefitPublished(String title);

  /// No description provided for @notificationBenefitPublishedGeneric.
  ///
  /// In en, this message translates to:
  /// **'A new benefit is available'**
  String get notificationBenefitPublishedGeneric;

  /// No description provided for @notificationReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'A new report was submitted'**
  String get notificationReportSubmitted;

  /// No description provided for @notificationEventApproved.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" was approved'**
  String notificationEventApproved(String title);

  /// No description provided for @notificationEventApprovedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your event was approved'**
  String get notificationEventApprovedGeneric;

  /// No description provided for @notificationEventRejected.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" was rejected'**
  String notificationEventRejected(String title);

  /// No description provided for @notificationEventRejectedWithReason.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" was rejected: {reason}'**
  String notificationEventRejectedWithReason(String title, String reason);

  /// No description provided for @notificationEventRejectedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your event was rejected'**
  String get notificationEventRejectedGeneric;

  /// No description provided for @notificationGroupMeetingPending.
  ///
  /// In en, this message translates to:
  /// **'A group meeting is waiting for approval'**
  String get notificationGroupMeetingPending;

  /// No description provided for @notificationBenefitRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! The benefit ({title}) has been successfully redeemed.'**
  String notificationBenefitRedeemed(String title);

  /// No description provided for @notificationBenefitRedeemedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your benefit has been successfully redeemed.'**
  String get notificationBenefitRedeemedGeneric;

  /// No description provided for @notificationSurveyPublished.
  ///
  /// In en, this message translates to:
  /// **'New survey: {title}'**
  String notificationSurveyPublished(String title);

  /// No description provided for @notificationSurveyPublishedGeneric.
  ///
  /// In en, this message translates to:
  /// **'A new survey is available'**
  String get notificationSurveyPublishedGeneric;

  /// No description provided for @scanStudentIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Student ID (Show it to the Event Host)'**
  String get scanStudentIdLabel;

  /// No description provided for @scanStudentIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Student ID copied'**
  String get scanStudentIdCopied;

  /// No description provided for @attendanceManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm by Student ID'**
  String get attendanceManualTitle;

  /// No description provided for @attendanceManualHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the student\'s ID'**
  String get attendanceManualHint;

  /// No description provided for @attendanceManualAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm attendance'**
  String get attendanceManualAction;

  /// No description provided for @attendanceManualLookupError.
  ///
  /// In en, this message translates to:
  /// **'No student found with that ID'**
  String get attendanceManualLookupError;

  /// No description provided for @attendanceManualConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm attendance'**
  String get attendanceManualConfirmTitle;

  /// No description provided for @attendanceManualConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Mark {name} as attended?'**
  String attendanceManualConfirmMessage(String name);

  /// No description provided for @attendanceManualSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} was marked as attended'**
  String attendanceManualSuccess(String name);

  /// No description provided for @optionNoTranslations.
  ///
  /// In en, this message translates to:
  /// **'No translations — shows in English'**
  String get optionNoTranslations;

  /// No description provided for @optionEditTranslations.
  ///
  /// In en, this message translates to:
  /// **'Edit translations'**
  String get optionEditTranslations;

  /// No description provided for @optionLabelArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic label'**
  String get optionLabelArabic;

  /// No description provided for @optionLabelHebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew label'**
  String get optionLabelHebrew;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @championsRewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly rewards'**
  String get championsRewardsTitle;

  /// No description provided for @championsRewardFirst.
  ///
  /// In en, this message translates to:
  /// **'🥇 1st place: {points} pts'**
  String championsRewardFirst(int points);

  /// No description provided for @championsRewardSecond.
  ///
  /// In en, this message translates to:
  /// **'🥈 2nd place: {points} pts'**
  String championsRewardSecond(int points);

  /// No description provided for @championsRewardThird.
  ///
  /// In en, this message translates to:
  /// **'🥉 3rd place: {points} pts'**
  String championsRewardThird(int points);

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyTitle;

  /// No description provided for @legalTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get legalTermsTitle;

  /// No description provided for @legalEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get legalEditAction;

  /// No description provided for @legalTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get legalTitleLabel;

  /// No description provided for @legalBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get legalBodyLabel;

  /// No description provided for @legalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this document.'**
  String get legalLoadError;

  /// No description provided for @legalSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get legalSaveError;

  /// No description provided for @legalEditDenied.
  ///
  /// In en, this message translates to:
  /// **'Only the super admin can edit this.'**
  String get legalEditDenied;

  /// No description provided for @legalEmpty.
  ///
  /// In en, this message translates to:
  /// **'This document hasn\'t been written yet.'**
  String get legalEmpty;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profilePhotoRemove;

  /// No description provided for @meetingInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Meeting in progress'**
  String get meetingInProgressTitle;

  /// No description provided for @meetingWithLabel.
  ///
  /// In en, this message translates to:
  /// **'with'**
  String get meetingWithLabel;

  /// No description provided for @meetingYourQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Your QR Code'**
  String get meetingYourQrTitle;

  /// No description provided for @meetingScanOtherTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the other student\'s QR code'**
  String get meetingScanOtherTitle;

  /// No description provided for @meetingQrRotatingHint.
  ///
  /// In en, this message translates to:
  /// **'This code refreshes every 10 seconds'**
  String get meetingQrRotatingHint;

  /// No description provided for @meetingSectionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get meetingSectionDone;

  /// No description provided for @meetingBothActionsHint.
  ///
  /// In en, this message translates to:
  /// **'Complete both actions to confirm the meeting and earn points.'**
  String get meetingBothActionsHint;

  /// No description provided for @meetingScanOwnCode.
  ///
  /// In en, this message translates to:
  /// **'That\'s your own code'**
  String get meetingScanOwnCode;

  /// No description provided for @meetingScanExpired.
  ///
  /// In en, this message translates to:
  /// **'That code expired — ask them to show it again'**
  String get meetingScanExpired;

  /// No description provided for @meetingScanError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t scan. Please try again.'**
  String get meetingScanError;

  /// No description provided for @meetingCompletedPoints.
  ///
  /// In en, this message translates to:
  /// **'Meeting confirmed! You earned {points} points.'**
  String meetingCompletedPoints(int points);

  /// No description provided for @meetingCompletedNoPoints.
  ///
  /// In en, this message translates to:
  /// **'Meeting confirmed! (No points — already met today.)'**
  String get meetingCompletedNoPoints;

  /// No description provided for @meetingOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open meeting'**
  String get meetingOpenAction;

  /// No description provided for @meetingNotYetOpen.
  ///
  /// In en, this message translates to:
  /// **'Ready to connect? Check back at your scheduled time.'**
  String get meetingNotYetOpen;

  /// No description provided for @meetingWindowEnded.
  ///
  /// In en, this message translates to:
  /// **'This meeting\'s window has ended'**
  String get meetingWindowEnded;

  /// No description provided for @myEventsMeetingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get myEventsMeetingsTitle;

  /// No description provided for @meetingCardCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get meetingCardCompleted;

  /// No description provided for @meetingAttendedMessage.
  ///
  /// In en, this message translates to:
  /// **'Awesome! We\'re glad you two connected.'**
  String get meetingAttendedMessage;

  /// No description provided for @meetingMissedMessage.
  ///
  /// In en, this message translates to:
  /// **'You missed this meeting window. No worries — you can schedule another one anytime.'**
  String get meetingMissedMessage;

  /// No description provided for @meetingCardWith.
  ///
  /// In en, this message translates to:
  /// **'Meeting with {name}'**
  String meetingCardWith(String name);

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShow;

  /// No description provided for @passwordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHide;

  /// No description provided for @benefitFormSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save this benefit.'**
  String get benefitFormSubmitError;

  /// No description provided for @monthAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'{month} Champions'**
  String monthAnnouncementTitle(String month);

  /// No description provided for @monthAnnouncementBody.
  ///
  /// In en, this message translates to:
  /// **'Last month\'s Champions have been announced! Here\'s the top 3:'**
  String get monthAnnouncementBody;

  /// No description provided for @monthAnnouncementOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get monthAnnouncementOk;

  /// No description provided for @winnerBonusTitle.
  ///
  /// In en, this message translates to:
  /// **'You placed #{rank}!'**
  String winnerBonusTitle(int rank);

  /// No description provided for @winnerBonusPoints.
  ///
  /// In en, this message translates to:
  /// **'You finished last month with {points} points.'**
  String winnerBonusPoints(int points);

  /// No description provided for @winnerBonusAmount.
  ///
  /// In en, this message translates to:
  /// **'+{bonus} bonus points'**
  String winnerBonusAmount(int bonus);

  /// No description provided for @winnerBonusOk.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get winnerBonusOk;

  /// No description provided for @accessibilityPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilityPanelTitle;

  /// No description provided for @accessibilityFloatingToggle.
  ///
  /// In en, this message translates to:
  /// **'Floating accessibility button'**
  String get accessibilityFloatingToggle;

  /// No description provided for @accessibilityFloatingRemovedHint.
  ///
  /// In en, this message translates to:
  /// **'Accessibility button hidden. Turn it back on in Settings.'**
  String get accessibilityFloatingRemovedHint;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @accessibilityTextSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get accessibilityTextSizeLabel;

  /// No description provided for @accessibilityTextSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get accessibilityTextSizeNormal;

  /// No description provided for @accessibilityTextSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get accessibilityTextSizeLarge;

  /// No description provided for @accessibilityTextSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get accessibilityTextSizeExtraLarge;

  /// No description provided for @accessibilityReduceMotionLabel.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get accessibilityReduceMotionLabel;

  /// No description provided for @accessibilityHighContrastLabel.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get accessibilityHighContrastLabel;

  /// No description provided for @tutorialWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to C2C – Connect to Collect'**
  String get tutorialWelcomeTitle;

  /// No description provided for @tutorialWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Connect with students, explore all campus events, earn points, and enjoy exclusive rewards.'**
  String get tutorialWelcomeBody;

  /// No description provided for @tutorialMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your people'**
  String get tutorialMatchesTitle;

  /// No description provided for @tutorialMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Browse students who share your faculty, interests, and hobbies, then message them to set up a meetup.'**
  String get tutorialMatchesBody;

  /// No description provided for @tutorialScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to earn'**
  String get tutorialScanTitle;

  /// No description provided for @tutorialScanBody.
  ///
  /// In en, this message translates to:
  /// **'Show or scan a QR code at meetups and events to earn points automatically.'**
  String get tutorialScanBody;

  /// No description provided for @tutorialBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spend your points'**
  String get tutorialBenefitsTitle;

  /// No description provided for @tutorialBenefitsBody.
  ///
  /// In en, this message translates to:
  /// **'Redeem points for real perks from campus partners in the Benefits tab.'**
  String get tutorialBenefitsBody;

  /// No description provided for @tutorialChampionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Climb the leaderboard'**
  String get tutorialChampionsTitle;

  /// No description provided for @tutorialChampionsBody.
  ///
  /// In en, this message translates to:
  /// **'Top 3 students each month win a bonus — check Monthly Champions to see where you stand.'**
  String get tutorialChampionsBody;

  /// No description provided for @tutorialBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tutorialBackAction;

  /// No description provided for @tutorialNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNextAction;

  /// No description provided for @tutorialGetStartedAction.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get tutorialGetStartedAction;

  /// No description provided for @demoEventCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'How Event Points Work'**
  String get demoEventCheckInTitle;

  /// No description provided for @demoEventCheckInMessage.
  ///
  /// In en, this message translates to:
  /// **'Registering for an event doesn\'t automatically earn points. When you arrive, scan the event QR code—or ask the host to enter your Student ID—to receive your points.'**
  String get demoEventCheckInMessage;

  /// No description provided for @demoMeetingStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Your QR Code'**
  String get demoMeetingStep1Title;

  /// No description provided for @demoMeetingStep1Message.
  ///
  /// In en, this message translates to:
  /// **'Show this to the other student — it refreshes every 10 seconds for security.'**
  String get demoMeetingStep1Message;

  /// No description provided for @demoMeetingStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Scan the Other Student\'s QR'**
  String get demoMeetingStep2Title;

  /// No description provided for @demoMeetingStep2Message.
  ///
  /// In en, this message translates to:
  /// **'Scan their code too. Points are only awarded once you\'ve both scanned each other.'**
  String get demoMeetingStep2Message;

  /// No description provided for @demoGroupMeetingTitle.
  ///
  /// In en, this message translates to:
  /// **'About Group Meetings'**
  String get demoGroupMeetingTitle;

  /// No description provided for @demoGroupMeetingMessage.
  ///
  /// In en, this message translates to:
  /// **'If you are a group of 3 or more people and want to meet, create a group meeting here. The organizer receives 25 points when at least two other participants scan them, and each scanning participant receives 15 points.'**
  String get demoGroupMeetingMessage;

  /// No description provided for @demoBenefitsCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Before You Redeem'**
  String get demoBenefitsCatalogTitle;

  /// No description provided for @demoBenefitsCatalogMessage.
  ///
  /// In en, this message translates to:
  /// **'Redeeming a benefit spends your points immediately, and you can only hold one active card per benefit at a time.'**
  String get demoBenefitsCatalogMessage;

  /// No description provided for @demoDigitalCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Redeem This Card'**
  String get demoDigitalCardTitle;

  /// No description provided for @demoDigitalCardMessage.
  ///
  /// In en, this message translates to:
  /// **'This is the barcode for redeeming your benefit. When you get to the business, show it to the seller to receive the benefit. Please note: scanning the barcode and tapping \"Redeem\" redeems the benefit immediately, no matter who scanned it. So don\'t scan it yourself — only show it to the seller or a representative of the business where the benefit is redeemed.'**
  String get demoDigitalCardMessage;

  /// No description provided for @demoMatchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatibility Match'**
  String get demoMatchingTitle;

  /// No description provided for @demoMatchingMessage.
  ///
  /// In en, this message translates to:
  /// **'This percentage shows how closely your interests, faculty, and languages match. A higher percentage means you have more in common.'**
  String get demoMatchingMessage;

  /// No description provided for @demoGuidedMatchTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap here'**
  String get demoGuidedMatchTabTitle;

  /// No description provided for @demoGuidedMatchTabMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the Matches tab to see students you might connect with.'**
  String get demoGuidedMatchTabMessage;

  /// No description provided for @demoGuidedViewProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap here'**
  String get demoGuidedViewProfileTitle;

  /// No description provided for @demoGuidedViewProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap View Profile to check out a student\'s full profile.'**
  String get demoGuidedViewProfileMessage;

  /// No description provided for @demoProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Program Points'**
  String get demoProgramTitle;

  /// No description provided for @demoProgramMessage.
  ///
  /// In en, this message translates to:
  /// **'Points are awarded per session — each session needs its own check-in to count.'**
  String get demoProgramMessage;

  /// No description provided for @demoAccessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Shortcut'**
  String get demoAccessibilityTitle;

  /// No description provided for @demoAccessibilityMessage.
  ///
  /// In en, this message translates to:
  /// **'You can drag this button anywhere on the screen. Drag it to the bottom area to hide it. You can enable it again from Settings.'**
  String get demoAccessibilityMessage;

  /// No description provided for @demoChampionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Champions'**
  String get demoChampionsTitle;

  /// No description provided for @demoChampionsMessage.
  ///
  /// In en, this message translates to:
  /// **'This leaderboard tracks points earned this month only, and resets on the 1st. Your rank card shows exactly where you stand.'**
  String get demoChampionsMessage;

  /// No description provided for @demoReportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a User'**
  String get demoReportUserTitle;

  /// No description provided for @demoReportUserMessage.
  ///
  /// In en, this message translates to:
  /// **'It is important to know about this option: if a user behaves inappropriately, makes you feel uncomfortable, or there is an issue our team should know about, you can report them here. The report will be sent to the system team for review and handling.'**
  String get demoReportUserMessage;

  /// No description provided for @settingsHelpSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Tutorials'**
  String get settingsHelpSectionTitle;

  /// No description provided for @settingsReplayIntroAction.
  ///
  /// In en, this message translates to:
  /// **'Replay App Introduction'**
  String get settingsReplayIntroAction;

  /// No description provided for @settingsReplayTutorialsAction.
  ///
  /// In en, this message translates to:
  /// **'Replay Tutorials'**
  String get settingsReplayTutorialsAction;

  /// No description provided for @settingsReplayTutorialsToast.
  ///
  /// In en, this message translates to:
  /// **'Tutorials reset — you\'ll see them again as you use the app.'**
  String get settingsReplayTutorialsToast;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile.'**
  String get profileLoadError;

  /// No description provided for @profileAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAboutTitle;

  /// No description provided for @profileAboutEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added a bio yet.'**
  String get profileAboutEmpty;

  /// No description provided for @profileInterestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get profileInterestsLabel;

  /// No description provided for @profileInterestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any interests yet'**
  String get profileInterestsEmpty;

  /// No description provided for @profileLanguagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profileLanguagesTitle;

  /// No description provided for @profileLanguagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any languages yet'**
  String get profileLanguagesEmpty;

  /// No description provided for @profileStudiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Studies'**
  String get profileStudiesTitle;

  /// No description provided for @profileFacultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Faculty'**
  String get profileFacultyLabel;

  /// No description provided for @profileFieldOfStudyLabel.
  ///
  /// In en, this message translates to:
  /// **'Field of study'**
  String get profileFieldOfStudyLabel;

  /// No description provided for @searchableFieldMultipleHint.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple'**
  String get searchableFieldMultipleHint;

  /// No description provided for @searchableFieldPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get searchableFieldPlaceholder;

  /// No description provided for @searchableFieldSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchableFieldSearchHint;

  /// No description provided for @searchableFieldNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchableFieldNoMatches;

  /// No description provided for @searchableFieldDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get searchableFieldDone;

  /// No description provided for @profileGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGenderLabel;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderUndisclosed.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderUndisclosed;

  /// No description provided for @profilePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get profilePhotoLabel;

  /// No description provided for @profilePhotoChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profilePhotoChange;

  /// No description provided for @profilePhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get profilePhotoAdd;

  /// No description provided for @profilePhotoUploadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the photo. Please try again.'**
  String get profilePhotoUploadError;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell other students a bit about yourself'**
  String get profileBioHint;

  /// No description provided for @profileOptionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load options.'**
  String get profileOptionsLoadError;

  /// No description provided for @profileOptionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No options available yet.'**
  String get profileOptionsEmpty;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @errorSelectFieldOfStudy.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one field of study'**
  String get errorSelectFieldOfStudy;

  /// No description provided for @profileDegreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get profileDegreeLabel;

  /// No description provided for @profileYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year of study'**
  String get profileYearLabel;

  /// No description provided for @profileYearShort.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String profileYearShort(int year);

  /// No description provided for @profileEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditAction;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettingsTitle;

  /// No description provided for @profileLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageLabel;

  /// No description provided for @profilePolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Policy & terms of use'**
  String get profilePolicyLabel;

  /// No description provided for @profileLogoutAction.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogoutAction;

  /// No description provided for @profileDeleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccountAction;

  /// No description provided for @profileDeleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get profileDeleteAccountConfirmTitle;

  /// No description provided for @profileDeleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'After you request deletion your account is deactivated for 30 days. At the end of that period it is permanently deleted. If you sign back in to the app within those 30 days, the deletion request is cancelled and your account stays active.'**
  String get profileDeleteAccountConfirmMessage;

  /// No description provided for @profileDeleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Request deletion'**
  String get profileDeleteAccountConfirmAction;

  /// No description provided for @profileDeleteAccountInProgress.
  ///
  /// In en, this message translates to:
  /// **'Sending deletion request…'**
  String get profileDeleteAccountInProgress;

  /// No description provided for @profileDeleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the deletion request. Please try again or contact support.'**
  String get profileDeleteAccountError;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of your account?'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileAppVersion.
  ///
  /// In en, this message translates to:
  /// **'C2C app version {version}'**
  String profileAppVersion(String version);

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// No description provided for @profileEditError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile.'**
  String get profileEditError;

  /// No description provided for @profileSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveAction;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your notifications.'**
  String get notificationsLoadError;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String notificationsSelectedCount(Object count);

  /// No description provided for @notificationsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get notificationsSelectAll;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get notificationsMarkRead;

  /// No description provided for @notificationsMarkUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get notificationsMarkUnread;

  /// No description provided for @notificationsDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notificationsDeleteAction;

  /// No description provided for @notificationsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get notificationsClearAll;

  /// No description provided for @notificationsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete notifications?'**
  String get notificationsDeleteConfirmTitle;

  /// No description provided for @notificationsDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete {count} notification(s). This can\'t be undone.'**
  String notificationsDeleteConfirmMessage(Object count);

  /// No description provided for @notificationsClearAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications?'**
  String get notificationsClearAllConfirmTitle;

  /// No description provided for @notificationsClearAllConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your notifications. This can\'t be undone.'**
  String get notificationsClearAllConfirmMessage;

  /// No description provided for @notificationTargetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this — it may no longer be available.'**
  String get notificationTargetLoadError;

  /// No description provided for @notificationPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'Received {points} points'**
  String notificationPointsEarned(int points);

  /// No description provided for @notificationPointsEarnedWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Received {points} points – {title}'**
  String notificationPointsEarnedWithTitle(int points, String title);

  /// No description provided for @notificationNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message from {name}'**
  String notificationNewMessage(String name);

  /// No description provided for @notificationMeetingProposal.
  ///
  /// In en, this message translates to:
  /// **'New proposal: meeting at {time}'**
  String notificationMeetingProposal(String time);

  /// No description provided for @notificationMeetingProposalGeneric.
  ///
  /// In en, this message translates to:
  /// **'New meeting proposal'**
  String get notificationMeetingProposalGeneric;

  /// No description provided for @notificationGeneric.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get notificationGeneric;

  /// No description provided for @surveysTitle.
  ///
  /// In en, this message translates to:
  /// **'Surveys'**
  String get surveysTitle;

  /// No description provided for @homeSurveysSection.
  ///
  /// In en, this message translates to:
  /// **'Available Surveys'**
  String get homeSurveysSection;

  /// No description provided for @homeSurveysBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Fill a quick survey and get points!'**
  String get homeSurveysBannerCta;

  /// No description provided for @surveysTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active Surveys'**
  String get surveysTabActive;

  /// No description provided for @surveysTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed Surveys'**
  String get surveysTabCompleted;

  /// No description provided for @surveysFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get surveysFilterPending;

  /// No description provided for @surveysFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get surveysFilterCompleted;

  /// No description provided for @surveysFilterIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get surveysFilterIncoming;

  /// No description provided for @surveysEmptyPending.
  ///
  /// In en, this message translates to:
  /// **'No surveys waiting for you right now.'**
  String get surveysEmptyPending;

  /// No description provided for @surveysEmptyCompleted.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t completed any surveys yet.'**
  String get surveysEmptyCompleted;

  /// No description provided for @surveysEmptyIncoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming surveys scheduled.'**
  String get surveysEmptyIncoming;

  /// No description provided for @surveysLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load surveys.'**
  String get surveysLoadError;

  /// No description provided for @surveysEndsToday.
  ///
  /// In en, this message translates to:
  /// **'Ends today'**
  String get surveysEndsToday;

  /// No description provided for @surveysEndsInDays.
  ///
  /// In en, this message translates to:
  /// **'Ends in {days} days'**
  String surveysEndsInDays(int days);

  /// No description provided for @surveyStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start Survey'**
  String get surveyStartAction;

  /// No description provided for @surveyPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String surveyPointsLabel(int points);

  /// No description provided for @surveySubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get surveySubmitAction;

  /// No description provided for @surveySubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'You earned {points} points!'**
  String surveySubmitSuccess(int points);

  /// No description provided for @surveySubmitErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit your answers. Try again.'**
  String get surveySubmitErrorGeneric;

  /// No description provided for @surveySubmitErrorAlreadyAnswered.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already completed this survey.'**
  String get surveySubmitErrorAlreadyAnswered;

  /// No description provided for @surveySubmitErrorClosed.
  ///
  /// In en, this message translates to:
  /// **'This survey is closed.'**
  String get surveySubmitErrorClosed;

  /// No description provided for @surveySubmitErrorNotYetOpen.
  ///
  /// In en, this message translates to:
  /// **'This survey isn\'t open yet.'**
  String get surveySubmitErrorNotYetOpen;

  /// No description provided for @surveyDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this survey.'**
  String get surveyDetailLoadError;

  /// No description provided for @surveyTextAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer'**
  String get surveyTextAnswerHint;

  /// No description provided for @surveyTextAnswerRequired.
  ///
  /// In en, this message translates to:
  /// **'Please answer every question before submitting.'**
  String get surveyTextAnswerRequired;

  /// No description provided for @tourIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Great, you’re successfully signed in!'**
  String get tourIntroTitle;

  /// No description provided for @tourIntroDescription.
  ///
  /// In en, this message translates to:
  /// **'Now we’ll briefly introduce you to the app and its main buttons and features.'**
  String get tourIntroDescription;

  /// No description provided for @tourNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNextAction;

  /// No description provided for @tourMyEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get tourMyEventsTitle;

  /// No description provided for @tourMyEventsDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can see the events you registered for, the meetings you scheduled with other students, and track your participation.'**
  String get tourMyEventsDescription;

  /// No description provided for @tourPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Points'**
  String get tourPointsTitle;

  /// No description provided for @tourPointsDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the number of points you have earned so far. You can earn points by attending events, meeting other students, and taking part in other activities in the app, then use them to redeem benefits.'**
  String get tourPointsDescription;

  /// No description provided for @tourChampionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Champions'**
  String get tourChampionsTitle;

  /// No description provided for @tourChampionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Earn points, climb the ranking, and reach the top! Here you can track your position and see who leads the monthly ranking. At the end of each month, the three students with the most points receive bonus points.'**
  String get tourChampionsDescription;

  /// No description provided for @tourSurveysTitle.
  ///
  /// In en, this message translates to:
  /// **'Surveys'**
  String get tourSurveysTitle;

  /// No description provided for @tourSurveysDescription.
  ///
  /// In en, this message translates to:
  /// **'Share what you think and earn points too! Short surveys will appear here for you to answer easily, and you will receive points for every survey you complete.'**
  String get tourSurveysDescription;

  /// No description provided for @tourAccessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Button'**
  String get tourAccessibilityTitle;

  /// No description provided for @tourAccessibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Open accessibility options here and adapt the app display to your needs. You can drag the accessibility button anywhere convenient on the screen, and remove or restore it at any time from the app settings.'**
  String get tourAccessibilityDescription;

  /// No description provided for @tourMatchesNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet & Connect'**
  String get tourMatchesNavTitle;

  /// No description provided for @tourMatchesNavDescription.
  ///
  /// In en, this message translates to:
  /// **'Meet the students around you on campus, discover what you have in common, and arrange to meet on campus! Met up? Scan each other during the meeting and earn points together. Tap here to continue.'**
  String get tourMatchesNavDescription;

  /// No description provided for @tourScanNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get tourScanNavTitle;

  /// No description provided for @tourBenefitsNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get tourBenefitsNavTitle;

  /// No description provided for @tourTapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap the highlighted button to continue.'**
  String get tourTapToContinue;

  /// No description provided for @tourCompatibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatibility Percentage'**
  String get tourCompatibilityTitle;

  /// No description provided for @tourCompatibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'A compatibility percentage appears next to each student and is calculated from things you have in common, such as fields of study, interests, and languages. The higher the percentage, the more characteristics you share.'**
  String get tourCompatibilityDescription;

  /// No description provided for @tourChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tourChatTitle;

  /// No description provided for @tourChatDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can chat with and get to know other students. Using the (+) button in the chat, you can schedule a meeting that will be saved in ‘My Events’. During the meeting, an option will open to scan each other to confirm that you met, and after confirmation you will receive the meeting points.'**
  String get tourChatDescription;

  /// No description provided for @tourStudentProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tourStudentProfileTitle;

  /// No description provided for @tourStudentProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can get to know the student a little better and see the details they chose to share on their profile, such as their field of study, languages, interests, and additional information about them.'**
  String get tourStudentProfileDescription;

  /// No description provided for @tourReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a User'**
  String get tourReportTitle;

  /// No description provided for @tourReportDescription.
  ///
  /// In en, this message translates to:
  /// **'It is important to know this option: if a user behaves inappropriately, makes you feel uncomfortable, or there is an issue our team should know about, you can report it here. The report will be sent to the system team for review and handling.'**
  String get tourReportDescription;

  /// No description provided for @tourScanCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Event QR Scan'**
  String get tourScanCameraTitle;

  /// No description provided for @tourScanCameraDescription.
  ///
  /// In en, this message translates to:
  /// **'Arrived at an event? Scan the QR code here to confirm your attendance and receive points. This camera is for event scanning only. Meetings with students use a separate scan that opens automatically inside the meeting at its scheduled time. You can find your scheduled meetings in ‘My Events’.'**
  String get tourScanCameraDescription;

  /// No description provided for @tourStudentIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Number'**
  String get tourStudentIdTitle;

  /// No description provided for @tourStudentIdDescription.
  ///
  /// In en, this message translates to:
  /// **'This is your personal identification number in the app. If you missed the QR scan at an event or there was a scanning problem, you can give this number to the event host so they can add you manually.'**
  String get tourStudentIdDescription;

  /// No description provided for @tourBenefitsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get tourBenefitsPageTitle;

  /// No description provided for @tourBenefitsPageDescription.
  ///
  /// In en, this message translates to:
  /// **'It’s time to enjoy the points you’ve earned! Here you can see available benefits, read their details, check how many points are required, and choose the benefit you want to redeem.'**
  String get tourBenefitsPageDescription;

  /// No description provided for @tourWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get tourWalletTitle;

  /// No description provided for @tourTapWalletDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap the wallet button to continue.'**
  String get tourTapWalletDescription;

  /// No description provided for @tourWalletDescription.
  ///
  /// In en, this message translates to:
  /// **'Every benefit you redeem is waiting for you here. In the wallet you can find the benefits you chose to redeem and open each benefit’s digital card. When you arrive at the business, show the digital card and enjoy your benefit.'**
  String get tourWalletDescription;

  /// No description provided for @tourProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tourProfileTitle;

  /// No description provided for @tourProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'This is your personal C2C profile. Here you can view and update the details you want other students to know about you. You can also change the app language and accessibility button, and view open surveys and the terms of use in the settings below.'**
  String get tourProfileDescription;

  /// No description provided for @tourReplayAction.
  ///
  /// In en, this message translates to:
  /// **'Replay step-by-step guide'**
  String get tourReplayAction;

  /// No description provided for @surveyAnswerRequired.
  ///
  /// In en, this message translates to:
  /// **'Please answer all questions before submitting.'**
  String get surveyAnswerRequired;

  /// No description provided for @tourProfileButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tourProfileButtonTitle;

  /// No description provided for @tourProfileButtonDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can get to know the student a little better and see the details they chose to share on their profile, such as their field of study, languages, interests, and additional information about them.'**
  String get tourProfileButtonDescription;

  /// No description provided for @demoChatBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block a user'**
  String get demoChatBlockTitle;

  /// No description provided for @demoChatBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'You can block this user from here. Once blocked, they won\'t be able to send you messages and you won\'t be able to send them messages either. You can block and unblock at any time by tapping the button.'**
  String get demoChatBlockMessage;

  /// No description provided for @demoChatMeetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule a meeting'**
  String get demoChatMeetingTitle;

  /// No description provided for @demoChatMeetingMessage.
  ///
  /// In en, this message translates to:
  /// **'From here you can arrange a meeting with the student you\'re chatting with. Set up a meeting, meet on campus and earn points together! A first meeting with a new student earns each of you 25 points, a second meeting with the same student 20 points, and a third meeting 10 points. Please note: you can arrange one meeting per day with the same student, and up to 5 meetings with different students on the same day.'**
  String get demoChatMeetingMessage;

  /// No description provided for @tourBenefitsStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'My status'**
  String get tourBenefitsStatusTitle;

  /// No description provided for @tourBenefitsStatusDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can see your points balance, progress toward the next benefit, and a shortcut to your digital wallet.'**
  String get tourBenefitsStatusDescription;

  /// No description provided for @tourWalletTapDescription.
  ///
  /// In en, this message translates to:
  /// **'Your digital wallet stores the benefits you redeemed. Tap My Wallet above or the wallet button to open it.'**
  String get tourWalletTapDescription;

  /// No description provided for @tourMatchesIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Matching'**
  String get tourMatchesIntroTitle;

  /// No description provided for @tourMatchesIntroDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can find students to get to know, see your compatibility score, chat with them, and arrange a one-to-one meeting through the app.'**
  String get tourMatchesIntroDescription;

  /// No description provided for @externalLinkOpenFailedCopied.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link — it was copied to your clipboard instead.'**
  String get externalLinkOpenFailedCopied;

  /// No description provided for @homeEventsNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Events in the Next Month'**
  String get homeEventsNextMonth;

  /// No description provided for @homeEmptyEventsNextMonth.
  ///
  /// In en, this message translates to:
  /// **'No events in the next month right now.'**
  String get homeEmptyEventsNextMonth;

  /// No description provided for @eventFullNotice.
  ///
  /// In en, this message translates to:
  /// **'The event is full. If additional spots become available, registration will reopen here.'**
  String get eventFullNotice;

  /// No description provided for @eventFullAction.
  ///
  /// In en, this message translates to:
  /// **'Event full'**
  String get eventFullAction;

  /// No description provided for @tourEventsNextMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Events in the Next Month'**
  String get tourEventsNextMonthTitle;

  /// No description provided for @tourEventsNextMonthDescription.
  ///
  /// In en, this message translates to:
  /// **'This section shows only events taking place within the coming month — a quick look at what\'s happening soon.'**
  String get tourEventsNextMonthDescription;

  /// No description provided for @tourUpcomingEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Events'**
  String get tourUpcomingEventsTitle;

  /// No description provided for @tourUpcomingEventsDescription.
  ///
  /// In en, this message translates to:
  /// **'This section shows all events currently open for registration, whenever they take place — including ones more than a month away. Tap an event to read the details and register.'**
  String get tourUpcomingEventsDescription;

  /// No description provided for @authSpamFolderNote.
  ///
  /// In en, this message translates to:
  /// **'If you can\'t find the email in your inbox, please check your spam folder.'**
  String get authSpamFolderNote;

  /// No description provided for @errorSelectFaculty.
  ///
  /// In en, this message translates to:
  /// **'Please select a faculty'**
  String get errorSelectFaculty;

  /// No description provided for @errorSelectDegree.
  ///
  /// In en, this message translates to:
  /// **'Please select a degree level'**
  String get errorSelectDegree;

  /// No description provided for @errorSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender'**
  String get errorSelectGender;

  /// No description provided for @errorSelectYearOfStudy.
  ///
  /// In en, this message translates to:
  /// **'Please select your year of study'**
  String get errorSelectYearOfStudy;

  /// No description provided for @profileRequiredFieldsMissing.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields before continuing.'**
  String get profileRequiredFieldsMissing;

  /// No description provided for @eventShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share event'**
  String get eventShareAction;

  /// No description provided for @eventShareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get eventShareCopyLink;

  /// No description provided for @eventShareViaApps.
  ///
  /// In en, this message translates to:
  /// **'Share via…'**
  String get eventShareViaApps;

  /// No description provided for @eventShareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard.'**
  String get eventShareLinkCopied;

  /// No description provided for @eventShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the event. Please try again.'**
  String get eventShareFailed;

  /// No description provided for @eventShareMessage.
  ///
  /// In en, this message translates to:
  /// **'{title} — see the event in the C2C app:'**
  String eventShareMessage(String title);

  /// No description provided for @eventNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Event unavailable'**
  String get eventNotFoundTitle;

  /// No description provided for @eventNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This event no longer exists, or it isn\'t available to your account.'**
  String get eventNotFoundMessage;

  /// No description provided for @proposeMeetingRespondError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the meeting. Please try again.'**
  String get proposeMeetingRespondError;

  /// No description provided for @proposeMeetingAlreadyResponded.
  ///
  /// In en, this message translates to:
  /// **'This meeting request has already been answered.'**
  String get proposeMeetingAlreadyResponded;

  /// No description provided for @notificationEventReminderTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: {title}'**
  String notificationEventReminderTomorrow(String title);

  /// No description provided for @notificationEventReminderTomorrowGeneric.
  ///
  /// In en, this message translates to:
  /// **'You have an event tomorrow'**
  String get notificationEventReminderTomorrowGeneric;

  /// No description provided for @notificationEventReminderToday.
  ///
  /// In en, this message translates to:
  /// **'Today: {title}'**
  String notificationEventReminderToday(String title);

  /// No description provided for @notificationEventReminderTodayGeneric.
  ///
  /// In en, this message translates to:
  /// **'You have an event today'**
  String get notificationEventReminderTodayGeneric;

  /// No description provided for @eventReminderPopupTitleTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Your event is tomorrow'**
  String get eventReminderPopupTitleTomorrow;

  /// No description provided for @eventReminderPopupTitleToday.
  ///
  /// In en, this message translates to:
  /// **'Your event is today'**
  String get eventReminderPopupTitleToday;

  /// No description provided for @eventReminderPopupLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventReminderPopupLocationLabel;

  /// No description provided for @eventReminderPopupStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get eventReminderPopupStartLabel;

  /// No description provided for @eventReminderPopupEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get eventReminderPopupEndLabel;

  /// No description provided for @eventReminderPopupDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get eventReminderPopupDismiss;

  /// No description provided for @eventReminderPopupOpenEvent.
  ///
  /// In en, this message translates to:
  /// **'View event'**
  String get eventReminderPopupOpenEvent;

  /// No description provided for @programPendingApprovalStatus.
  ///
  /// In en, this message translates to:
  /// **'Your registration request was sent. We will update you here once you are accepted to the event.'**
  String get programPendingApprovalStatus;

  /// No description provided for @programAcceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'You have been accepted'**
  String get programAcceptedStatus;

  /// No description provided for @profileFullNameWarning.
  ///
  /// In en, this message translates to:
  /// **'Please note: enter your full name. This is the name event organizers will see, so use your full name rather than a nickname.'**
  String get profileFullNameWarning;

  /// No description provided for @registerPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Your registration request was sent and is waiting for approval.'**
  String get registerPendingApproval;

  /// No description provided for @eventPendingApprovalLabel.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get eventPendingApprovalLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
