abstract final class InputValidation {
  static bool username(String value) =>
      RegExp(r'^[A-Za-z0-9_]{4,20}$').hasMatch(value.trim());

  static bool password(String value) =>
      value.length >= 8 &&
      !RegExp(r'\s').hasMatch(value) &&
      RegExp(r'[A-Za-z]').hasMatch(value) &&
      RegExp(r'[0-9]').hasMatch(value) &&
      RegExp(r'[^A-Za-z0-9\s]').hasMatch(value);
}
