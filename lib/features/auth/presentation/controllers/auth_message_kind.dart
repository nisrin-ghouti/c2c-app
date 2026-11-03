import '../../../../core/error/auth_failure.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Presentation-layer classification of a domain [AuthFailure] into
/// something a screen can localize. Keeping this mapping here (rather than
/// stuffing `AppLocalizations` into the controllers) keeps the
/// domain/controller layers free of any i18n dependency — only the widget
/// tree ever touches [AppLocalizations].
enum AuthErrorKind {
  invalidCredentials,
  emailNotConfirmed,
  userAlreadyExists,
  userNotFound,
  invalidOtp,
  blockedUser,
  generic,
}

AuthErrorKind classifyAuthFailure(AuthFailure failure) {
  return switch (failure) {
    InvalidCredentialsFailure() => AuthErrorKind.invalidCredentials,
    EmailNotConfirmedFailure() => AuthErrorKind.emailNotConfirmed,
    UserAlreadyExistsFailure() => AuthErrorKind.userAlreadyExists,
    UserNotFoundFailure() => AuthErrorKind.userNotFound,
    InvalidOtpFailure() => AuthErrorKind.invalidOtp,
    BlockedUserFailure() => AuthErrorKind.blockedUser,
    UnknownAuthFailure() => AuthErrorKind.generic,
  };
}

extension AuthErrorKindMessage on AuthErrorKind {
  String message(AppLocalizations l10n) {
    return switch (this) {
      AuthErrorKind.invalidCredentials => l10n.errorInvalidCredentials,
      AuthErrorKind.emailNotConfirmed => l10n.errorEmailNotConfirmedSendingCode,
      AuthErrorKind.userAlreadyExists => l10n.errorUserAlreadyExists,
      AuthErrorKind.userNotFound => l10n.errorUserNotFound,
      AuthErrorKind.invalidOtp => l10n.errorOtpIncorrect,
      AuthErrorKind.blockedUser => l10n.errorBlockedUser,
      AuthErrorKind.generic => l10n.errorGeneric,
    };
  }
}

/// Non-error info/success banners (e.g. "we resent the code").
enum AuthInfoKind { otpResent, resetLinkSent, passwordUpdated }

extension AuthInfoKindMessage on AuthInfoKind {
  String message(AppLocalizations l10n) {
    return switch (this) {
      AuthInfoKind.otpResent => l10n.infoResent,
      AuthInfoKind.resetLinkSent => l10n.infoResetLinkSent,
      AuthInfoKind.passwordUpdated => l10n.infoPasswordUpdated,
    };
  }
}
