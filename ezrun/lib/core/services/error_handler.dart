import 'package:flutter/material.dart';
import '../widgets/error_dialog.dart';
import '../widgets/status_dialogs.dart';

/// Error Handler Service
/// Centralized error handling for the entire application
/// Provides methods for displaying error dialogs and handling different error types
class ErrorHandler {
  /// Show error dialog with custom title and message
  static void showErrorDialog(
    BuildContext context, {
    required String message,
    String title = 'Error',
    String? actionButtonLabel,
    VoidCallback? onActionPressed,
    bool isDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (BuildContext context) => ErrorDialog(
        title: title,
        message: message,
        actionButtonLabel: actionButtonLabel,
        onActionPressed: onActionPressed,
        isDismissible: isDismissible,
      ),
    );
  }

  /// Handle exception and display appropriate error dialog
  /// Extracts meaningful error messages from different exception types
  static void handleException(
    BuildContext context,
    dynamic exception, {
    String title = 'Error',
    String? actionButtonLabel,
    VoidCallback? onActionPressed,
    bool isDismissible = true,
  }) {
    final message = _extractErrorMessage(exception);

    showErrorDialog(
      context,
      title: title,
      message: message,
      actionButtonLabel: actionButtonLabel,
      onActionPressed: onActionPressed,
      isDismissible: isDismissible,
    );
  }

  /// Extract meaningful error message from different exception types
  static String _extractErrorMessage(dynamic exception) {
    if (exception == null) {
      return 'An unknown error occurred. Please try again.';
    }

    final errorString = exception.toString();

    // Handle specific exception patterns
    if (errorString.contains('Exception:')) {
      return errorString.replaceFirst('Exception: ', '').trim();
    }

    if (errorString.contains('invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }

    if (errorString.contains('User already exists')) {
      return 'This email is already registered. Please sign in instead.';
    }

    if (errorString.contains('Password should be')) {
      return 'Password must be at least 8 characters long.';
    }

    if (errorString.contains('Email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }

    if (errorString.contains('Network')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorString.contains('Connection refused')) {
      return 'Unable to connect to the server. Please try again later.';
    }

    if (errorString.contains('Timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Return the original error message if no specific pattern matches
    return errorString.length > 200
        ? '${errorString.substring(0, 200)}...'
        : errorString;
  }

  /// Show success message (uses the error dialog but with success styling)
  static void showSuccessDialog(
    BuildContext context, {
    required String message,
    String title = 'Success',
    String? actionButtonLabel,
    VoidCallback? onActionPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => SuccessDialog(
        title: title,
        message: message,
        actionButtonLabel: actionButtonLabel,
        onActionPressed: onActionPressed,
      ),
    );
  }

  /// Show warning dialog
  static void showWarningDialog(
    BuildContext context, {
    required String message,
    String title = 'Warning',
    String? actionButtonLabel,
    VoidCallback? onActionPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => WarningDialog(
        title: title,
        message: message,
        actionButtonLabel: actionButtonLabel,
        onActionPressed: onActionPressed,
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    return result ?? false;
  }
}
