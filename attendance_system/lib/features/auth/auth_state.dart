/// Auth validation helpers
class AuthState {
  AuthState._();

  /// Validation for email format
  static bool isValidEmail(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  /// Validation for password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validation for password match
  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  /// Get available test credentials for display
  static Map<String, String> getTestCredentials() {
    return {
      'Admin': 'admin@school.com / admin123',
      'Principal': 'principal@school.com / principal123',
      'Teacher': 'teacher@school.com / teacher123',
      'Student': 'student@school.com / student123',
    };
  }
}

