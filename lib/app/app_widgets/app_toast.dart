import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'app_colors.dart';

/// Professional Toast utility with better readability and duplicate prevention
/// Shows toast at top with high contrast colors
class AppToast {
  /// Show success toast
  static void showSuccess(String message, {String? title, Duration? duration}) {
    _showToast(
      title: title ?? 'Success',
      message: message,
      type: ToastType.success,
      duration: duration,
    );
  }

  /// Show error toast
  static void showError(String message, {String? title, Duration? duration}) {
    _showToast(
      title: title ?? 'Error',
      message: message,
      type: ToastType.error,
      duration: duration,
    );
  }

  /// Show info toast
  static void showInfo(String message, {String? title, Duration? duration}) {
    _showToast(
      title: title ?? 'Info',
      message: message,
      type: ToastType.info,
      duration: duration,
    );
  }

  /// Show warning toast
  static void showWarning(String message, {String? title, Duration? duration}) {
    _showToast(
      title: title ?? 'Warning',
      message: message,
      type: ToastType.warning,
      duration: duration,
    );
  }

  /// Show custom toast (main method used throughout app)
  static void showCustomToast(
    String title,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      title: title,
      message: message,
      type: type,
      duration: duration,
    );
  }

  /// Internal method to show toast with duplicate prevention
  static void _showToast({
    required String title,
    required String message,
    required ToastType type,
    Duration? duration,
  }) {
    // Cancel any existing toast to prevent duplicates
    Fluttertoast.cancel();

    final (backgroundColor, textColor) = _getToastColors(type);
    
    // Combine title and message with better formatting
    final fullMessage = title.isNotEmpty 
        ? '$title: $message'
        : message;

    Fluttertoast.showToast(
      msg: fullMessage,
      toastLength: duration != null
          ? (duration.inSeconds > 3 ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT)
          : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP, // Always at top
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 14.sp,
      timeInSecForIosWeb: duration?.inSeconds ?? 3,
      webBgColor: '#${backgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      webShowClose: true,
      webPosition: 'top',
    );
  }

  /// Get colors based on toast type with better contrast for readability
  static (Color, Color) _getToastColors(ToastType type) {
    switch (type) {
      case ToastType.success:
        // Dark green background with white text - high contrast
        return (
          const Color(0xFF2E7D32), // Dark green
          Colors.white, // White text for readability
        );
      case ToastType.error:
        // Dark red background with white text - high contrast
        return (
          const Color(0xFFC62828), // Dark red
          Colors.white, // White text for readability
        );
      case ToastType.warning:
        // Orange background with white text - readable
        return (
          const Color(0xFFF57C00), // Orange
          Colors.white, // White text for readability
        );
      case ToastType.info:
        // App's primary teal with white text - matches theme
        return (
          AppColors.primaryTeal, // App's primary color
          Colors.white, // White text for readability
        );
    }
  }
}

/// Toast type enum
enum ToastType {
  success,
  error,
  warning,
  info,
}
