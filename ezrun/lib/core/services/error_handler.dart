import 'package:flutter/material.dart';
import '../widgets/error_dialog.dart';
import '../widgets/status_dialogs.dart';

/// Error type classification for better error handling
enum AppErrorType {
  authentication,
  network,
  validation,
  server,
  permission,
  notFound,
  unknown,
}

/// Error information container with user-friendly and technical details
class ErrorInfo {
  final String userFriendlyMessage;
  final String technicalDetails;
  final AppErrorType type;
  final String? code;

  const ErrorInfo({
    required this.userFriendlyMessage,
    required this.technicalDetails,
    this.type = AppErrorType.unknown,
    this.code,
  });
}

/// Error Handler Service
/// Centralized error handling for the entire application
/// Provides methods for displaying error dialogs and handling different error types
class ErrorHandler {
  /// Show error dialog with custom title and message
  static void showErrorDialog(
    BuildContext context, {
    required String message,
    String title = 'Error',
    String? technicalDetails,
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
        technicalDetails: technicalDetails,
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
    final errorInfo = _extractErrorInfo(exception);

    showErrorDialog(
      context,
      title: title,
      message: errorInfo.userFriendlyMessage,
      technicalDetails: errorInfo.technicalDetails,
      actionButtonLabel: actionButtonLabel,
      onActionPressed: onActionPressed,
      isDismissible: isDismissible,
    );
  }

  /// Extract error information from different exception types
  static ErrorInfo _extractErrorInfo(dynamic exception) {
    if (exception == null) {
      return const ErrorInfo(
        userFriendlyMessage: 'An unknown error occurred. Please try again.',
        technicalDetails: 'null exception',
        type: AppErrorType.unknown,
      );
    }

    final errorString = exception.toString();
    final errorLower = errorString.toLowerCase();

    // ============================================
    // AUTHENTICATION ERRORS
    // ============================================
    
    if (errorLower.contains('invalid_login_credentials') ||
        errorLower.contains('invalid credentials')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Unable to sign in. Please check your email and password.',
        technicalDetails: errorString,
        type: AppErrorType.authentication,
        code: 'invalid_credentials',
      );
    }

    if (errorLower.contains('user_already_exists') ||
        errorLower.contains('already exists') ||
        errorLower.contains('already registered') ||
        errorLower.contains('duplicate')) {
      return ErrorInfo(
        userFriendlyMessage:
            'This email is already registered. Try signing in instead.',
        technicalDetails: errorString,
        type: AppErrorType.authentication,
        code: 'user_exists',
      );
    }

    if (errorLower.contains('email_not_confirmed') ||
        errorLower.contains('email not confirmed')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Please verify your email address before signing in.',
        technicalDetails: errorString,
        type: AppErrorType.authentication,
        code: 'email_not_verified',
      );
    }

    if (errorLower.contains('please verify your email with otp')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Please verify your email with the OTP sent to continue.',
        technicalDetails: errorString,
        type: AppErrorType.authentication,
        code: 'otp_required',
      );
    }

    if (errorLower.contains('authentication sync failed')) {
      return ErrorInfo(
        userFriendlyMessage: 'Sign in failed. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.authentication,
        code: 'auth_sync_failed',
      );
    }

    if (errorLower.contains('not authenticated') ||
        errorLower.contains('no authenticated user')) {
      return ErrorInfo(
        userFriendlyMessage: 'Please sign in to continue.',
        technicalDetails: errorString,
        type: AppErrorType.authentication,
        code: 'not_authenticated',
      );
    }

    if (errorLower.contains('sign up failed') ||
        errorLower.contains('signup failed')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not create account. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.authentication,
        code: 'signup_failed',
      );
    }

    // ============================================
    // OTP & VERIFICATION ERRORS
    // ============================================

    if (errorLower.contains('invalid otp')) {
      return ErrorInfo(
        userFriendlyMessage:
            'The code you entered is incorrect. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'invalid_otp',
      );
    }

    if (errorLower.contains('failed to send otp') ||
        errorLower.contains('could not send otp')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Could not send verification code. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'otp_send_failed',
      );
    }

    if (errorLower.contains('otp expired')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Your verification code has expired. Please request a new one.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'otp_expired',
      );
    }

    // ============================================
    // NETWORK & SERVER ERRORS
    // ============================================

    if (errorLower.contains('network') ||
        errorLower.contains('socketexception') ||
        errorLower.contains('no internet')) {
      return ErrorInfo(
        userFriendlyMessage:
            'No internet connection. Please check your network settings.',
        technicalDetails: errorString,
        type: AppErrorType.network,
        code: 'network_error',
      );
    }

    if (errorLower.contains('connection refused') ||
        errorLower.contains('connection failed')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Unable to connect to server. Please try again later.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'connection_refused',
      );
    }

    if (errorLower.contains('timeout') ||
        errorLower.contains('timed out')) {
      return ErrorInfo(
        userFriendlyMessage: 'Request took too long. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.network,
        code: 'timeout',
      );
    }

    if (errorLower.contains('backend unavailable') ||
        errorLower.contains('service unavailable')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Service temporarily unavailable. Please try again later.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'service_unavailable',
      );
    }

    if (errorLower.contains('pgrst202') ||
        errorLower.contains('schema cache')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Server is updating. Please try again in a moment.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'server_updating',
      );
    }

    // ============================================
    // VALIDATION ERRORS
    // ============================================

    if (errorLower.contains('password should be') ||
        errorLower.contains('weak password')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Password must be at least 8 characters with letters and numbers.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'weak_password',
      );
    }

    if (errorLower.contains('invalid email') ||
        errorLower.contains('invalid_email')) {
      return ErrorInfo(
        userFriendlyMessage: 'Please enter a valid email address.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'invalid_email',
      );
    }

    if (errorLower.contains('name cannot be empty')) {
      return ErrorInfo(
        userFriendlyMessage: 'Please enter your name.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'empty_name',
      );
    }

    if (errorLower.contains('name is too long')) {
      return ErrorInfo(
        userFriendlyMessage: 'Name must be 32 characters or less.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'name_too_long',
      );
    }

    if (errorLower.contains('fill both fields') ||
        errorLower.contains('fill in all')) {
      return ErrorInfo(
        userFriendlyMessage: 'Please fill in all required fields.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'missing_fields',
      );
    }

    if (errorLower.contains('password too short')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Password is too short. Use at least 8 characters.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'short_password',
      );
    }

    // ============================================
    // IMAGE & UPLOAD ERRORS
    // ============================================

    if (errorLower.contains('image size must be less than') ||
        errorLower.contains('image is too large')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Photo is too large. Please choose a smaller image (max 5MB).',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'image_too_large',
      );
    }

    if (errorLower.contains('only jpg') ||
        errorLower.contains('unsupported image format') ||
        errorLower.contains('only png') ||
        errorLower.contains('only gif')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Unsupported image format. Please use JPG, PNG, or GIF.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'invalid_image_format',
      );
    }

    if (errorLower.contains('upload failed')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not upload image. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'upload_failed',
      );
    }

    if (errorLower.contains('delete failed') ||
        errorLower.contains('could not delete')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not delete. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'delete_failed',
      );
    }

    if (errorLower.contains('invalid imagekit url')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Image URL is invalid. Please try a different image.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'invalid_image_url',
      );
    }

    // ============================================
    // TERRITORY & MAP ERRORS
    // ============================================

    if (errorLower.contains('not enough points to form a polygon')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Territory is too small. Keep running to expand your area.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'territory_too_small',
      );
    }

    if (errorLower.contains('territory too small') ||
        errorLower.contains('minimum area')) {
      return ErrorInfo(
        userFriendlyMessage:
            'Territory must be at least 200 square meters.',
        technicalDetails: errorString,
        type: AppErrorType.validation,
        code: 'territory_area_small',
      );
    }

    if (errorLower.contains('territories rpc is outdated') ||
        errorLower.contains('apply the supabase migration')) {
      return ErrorInfo(
        userFriendlyMessage:
            'App needs an update. Please contact support.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'migration_required',
      );
    }

    // ============================================
    // PROFILE & ACCOUNT ERRORS
    // ============================================

    if (errorLower.contains('failed to delete account')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not delete account. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'account_delete_failed',
      );
    }

    if (errorLower.contains('export failed') ||
        errorLower.contains('could not export')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not export your data. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'export_failed',
      );
    }

    if (errorLower.contains('no runs to export')) {
      return ErrorInfo(
        userFriendlyMessage: 'No running data available to export.',
        technicalDetails: errorString,
        type: AppErrorType.notFound,
        code: 'no_data',
      );
    }

    // ============================================
    // POST & FEED ERRORS
    // ============================================

    if (errorLower.contains('failed to create post')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not create post. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'post_create_failed',
      );
    }

    if (errorLower.contains('failed to like')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not like post. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'like_failed',
      );
    }

    if (errorLower.contains('failed to add comment') ||
        errorLower.contains('could not add comment')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not add comment. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'comment_failed',
      );
    }

    // ============================================
    // RUN & ACTIVITY ERRORS
    // ============================================

    if (errorLower.contains('failed to save run') ||
        errorLower.contains('could not save run')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not save your run. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'run_save_failed',
      );
    }

    if (errorLower.contains('failed to delete run')) {
      return ErrorInfo(
        userFriendlyMessage: 'Could not delete run. Please try again.',
        technicalDetails: errorString,
        type: AppErrorType.server,
        code: 'run_delete_failed',
      );
    }

    // ============================================
    // GENERIC FALLBACK
    // ============================================

    // Clean up "Exception: " prefix if present
    String cleanMessage = errorString;
    if (cleanMessage.startsWith('Exception: ')) {
      cleanMessage = cleanMessage.replaceFirst('Exception: ', '');
    }

    // If the message is reasonable length, use it as-is (already user-friendly)
    if (cleanMessage.length <= 150 && !cleanMessage.contains('Stack') && !cleanMessage.contains('dart:')) {
      return ErrorInfo(
        userFriendlyMessage: cleanMessage,
        technicalDetails: errorString,
        type: AppErrorType.unknown,
      );
    }

    // For very long or technical messages, use generic fallback
    return ErrorInfo(
      userFriendlyMessage: 'Something went wrong. Please try again later.',
      technicalDetails: errorString.length > 500
          ? '${errorString.substring(0, 500)}...'
          : errorString,
      type: AppErrorType.unknown,
    );
  }

  /// Extract just the user-friendly message (for SnackBar usage)
  static String getUserFriendlyMessage(dynamic exception) {
    return _extractErrorInfo(exception).userFriendlyMessage;
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
