/// Shared validation helpers for auth forms.
abstract final class Validators {
  static final RegExp _email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Azerbaijani mobile: 9 digits after +994 (e.g. 501234567).
  static final RegExp _azMobileBody = RegExp(r'^[1-9]\d{8}$');

  static String? required(String? value, {String message = 'Bu xana məcburidir'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    final err = required(value);
    if (err != null) return err;
    final v = value!.trim();
    if (!_email.hasMatch(v)) return 'Düzgün e-poçt daxil edin';
    return null;
  }

  static String? phoneBodyAz(String? value) {
    final err = required(value);
    if (err != null) return err;
    final digits = value!.replaceAll(RegExp(r'\s'), '');
    if (!_azMobileBody.hasMatch(digits)) {
      return 'Düzgün mobil nömrə daxil edin (9 rəqəm)';
    }
    return null;
  }

  /// Login identifier: e-poçt və ya mobil nömrə.
  static String? phoneOrEmail(String? value) {
    final err = required(value);
    if (err != null) return err;
    final v = value!.trim();
    if (v.contains('@')) return email(v);
    var digits = v.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length == 12 && digits.startsWith('994')) {
      final body = digits.substring(3);
      return phoneBodyAz(body);
    }
    if (digits.length == 9) {
      return phoneBodyAz(digits);
    }
    return 'E-poçt və ya Azərbaycan mobil nömrəsi daxil edin';
  }

  static String? password(String? value, {int minLength = 6}) {
    final err = required(value, message: 'Şifrə daxil edin');
    if (err != null) return err;
    if (value!.length < minLength) {
      return 'Ən azı $minLength simvol';
    }
    return null;
  }
}
