import 'package:get/get.dart';

/// Validation Mixin - Reusable validation methods
mixin ValidationMixin {
  /// Email validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Password validation
  String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Name validation
  String? validateName(String? value, {int minLength = 2}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    return null;
  }

  /// Confirm password validation
  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Required field validation
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }
}

