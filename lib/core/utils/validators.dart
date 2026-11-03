import '../constants/app_config.dart';
import '../l10n/generated/app_localizations.dart';

/// Form-field validators shared by every auth screen. Centralized so the
/// university-domain rule (see [AppConfig]) only has one place to change, and
/// so error copy stays localized consistently.
abstract final class Validators {
  static final _emailFormat = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Format only — **any** domain is valid. Used for sign-in and password
  /// reset: admins create accounts manually with Gmail/Outlook/university
  /// addresses alike, and every one of those must be able to log in.
  static String? email(AppLocalizations l10n, String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return l10n.errorEnterEmail;
    if (!_emailFormat.hasMatch(email)) return l10n.errorEnterUniversityEmail;
    return null;
  }

  /// Format **and** the university domain. Used only for student
  /// self-registration, which the spec restricts to `@mail.tau.ac.il`.
  static String? universityEmail(AppLocalizations l10n, String? value) {
    final formatError = email(l10n, value);
    if (formatError != null) return formatError;
    if (!AppConfig.isAllowedEmail(value!)) {
      return l10n.errorDomainNotAllowed(AppConfig.allowedEmailDomainsLabel);
    }
    return null;
  }

  static String? requiredField(String? value, String message) {
    return (value == null || value.trim().isEmpty) ? message : null;
  }

  static String? password(
    AppLocalizations l10n,
    String? value, {
    int minLength = 8,
  }) {
    final v = value ?? '';
    if (v.isEmpty) return l10n.errorEnterPassword;
    if (v.length < minLength) return l10n.errorPasswordTooShort;
    return null;
  }

  static String? confirmPassword(
    AppLocalizations l10n,
    String? value,
    String original,
  ) {
    if (value != original) return l10n.errorPasswordsDontMatch;
    return null;
  }

  static String? otp(AppLocalizations l10n, String? value) {
    final v = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return l10n.errorInvalidOtp;
    return null;
  }
}
