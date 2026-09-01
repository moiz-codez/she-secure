final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _uppercasePattern = RegExp('[A-Z]');
final _specialCharPattern = RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=~`\[\];'/]''');

/// Fast, friendly client-side check before the network round-trip —
/// Firebase Auth also rejects a malformed email server-side regardless.
String? validateEmail(String email) {
  if (!_emailPattern.hasMatch(email.trim())) return 'Enter a valid email address.';
  return null;
}

/// At least 8 characters, one uppercase letter, one special character.
String? validatePassword(String password) {
  if (password.length < 8) return 'Password needs at least 8 characters.';
  if (!_uppercasePattern.hasMatch(password)) return 'Password needs an uppercase letter.';
  if (!_specialCharPattern.hasMatch(password)) return 'Password needs a special character.';
  return null;
}
