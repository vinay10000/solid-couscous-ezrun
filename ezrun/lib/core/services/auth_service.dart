import 'dart:async';

import 'package:flutter_better_auth/flutter_better_auth.dart' hide User;
import 'package:flutter_better_auth/core/models/user/user.dart' as better_auth;
import 'package:flutter_better_auth/plugins/email_otp/email_otp_plugin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/api_constants.dart';

/// Authentication service using Better Auth + Supabase Auth sync
class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final _supabase = Supabase.instance.client;

  final StreamController<better_auth.User?> _authStateController =
      StreamController<better_auth.User?>.broadcast();

  SessionResponse? _currentSession;
  better_auth.User? _currentUser;

  // Temporary storage for Supabase sync after OTP verification
  String? _pendingEmail;
  String? _pendingPassword;
  String? _pendingUsername;

  /// Current Better Auth user
  better_auth.User? get currentUser => _currentUser;

  /// Current session (nullable)
  SessionResponse? get currentSession => _currentSession;

  /// Stream of auth state changes
  Stream<better_auth.User?> get authStateChanges => _authStateController.stream;

  /// Whether a session exists
  bool get isLoggedIn => _currentSession != null;

  Future<void> hydrate() async {
    await _refreshSession();
    // Note: Supabase auth session persists automatically via shared_preferences
    print('🔄 Auth hydration complete:');
    print('   Better Auth: ${_currentUser?.email ?? "Not signed in"}');
    print(
      '   Supabase Auth: ${_supabase.auth.currentUser?.email ?? "Not signed in"}',
    );

    if (_currentUser != null && _supabase.auth.currentUser == null) {
      print(
        '⚠️ WARNING: Better Auth session exists but Supabase session missing!',
      );
      print('   Please sign out and sign in again to sync authentication.');
    }
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    // Sign in with Better Auth
    final result = await FlutterBetterAuth.client.signIn.email(
      email: email,
      password: password,
    );
    _requireData(result, fallback: 'Sign in failed. Please try again.');
    await _refreshSession();

    // Also sign into Supabase Auth (for RLS policies)
    print('🔐 Attempting Supabase Auth sign-in for: $email');
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('✅ Supabase Auth sign-in SUCCESS');
      print('   User ID: ${response.user?.id}');
      print('   Email: ${response.user?.email}');
    } catch (e) {
      print('⚠️ Supabase sign-in failed: $e');
      if (_shouldRouteThroughOtpProvisioning(e)) {
        // Never create a Supabase account during initial sign-in.
        // Provisioning must only happen after OTP verification submit.
        _stageSupabaseSyncForOtp(
          email: email,
          password: password,
          username: _currentUser?.name,
        );
        throw Exception(
          'Please verify your email with OTP to continue sign in.',
        );
      }
      throw Exception('Authentication sync failed. Please try again.');
    }

    // Verify we have a Supabase session
    final supabaseUser = _supabase.auth.currentUser;
    print('📊 Final auth state:');
    print('   Better Auth user: ${_currentUser?.email}');
    print('   Supabase user: ${supabaseUser?.email}');
    print('   Supabase session exists: ${supabaseUser != null}');

    // Sync user profile to public.users table
    if (supabaseUser != null && _currentUser != null) {
      await _syncUserProfile(
        userId: supabaseUser.id,
        email: _currentUser!.email,
        name: _currentUser!.name,
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    // Sign up with Better Auth (handles OTP verification)
    final result = await FlutterBetterAuth.client.signUp.email(
      name: username?.trim().isNotEmpty == true ? username!.trim() : 'Runner',
      email: email,
      password: password,
    );
    _requireData(result, fallback: 'Sign up failed. Please try again.');

    // Store credentials temporarily for Supabase sync after OTP verification
    _stageSupabaseSyncForOtp(
      email: email,
      password: password,
      username: username?.trim() ?? 'Runner',
    );

    // Note: Supabase user will be created AFTER OTP verification
  }

  /// Send email OTP for verification
  Future<void> sendEmailOtp({required String email}) async {
    final result = await FlutterBetterAuth.client.emailOtp.sendVerification(
      email: email,
      type: 'email-verification',
    );
    _requireData(result, fallback: 'Failed to send OTP. Please try again.');
  }

  /// Stage credentials so Supabase provisioning can happen only after OTP verify.
  void stageSupabaseSyncForOtp({
    required String email,
    required String password,
    String? username,
  }) {
    _stageSupabaseSyncForOtp(
      email: email,
      password: password,
      username: username,
    );
  }

  /// Verify email OTP
  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final result = await FlutterBetterAuth.client.emailOtp.verifyEmail(
      email: email,
      otp: otp,
    );
    _requireData(result, fallback: 'Invalid OTP. Please try again.');
    await _refreshSession();

    // NOW create the Supabase Auth user (after OTP verification)
    if (_pendingEmail != null && _pendingPassword != null) {
      print('🔐 Creating Supabase account after OTP verification...');
      try {
        final pendingName = _pendingUsername?.trim();
        final currentName = _currentUser?.name.trim();
        final stagedName = (pendingName != null && pendingName.isNotEmpty)
            ? pendingName
            : (currentName != null && currentName.isNotEmpty)
            ? currentName
            : 'Runner';

        // Try to sign up (creates account)
        final signUpResponse = await _supabase.auth.signUp(
          email: _pendingEmail!,
          password: _pendingPassword!,
          data: {'name': stagedName},
        );
        print('✅ Supabase account created: ${signUpResponse.user?.id}');

        // Immediately sign in
        final signInResponse = await _supabase.auth.signInWithPassword(
          email: _pendingEmail!,
          password: _pendingPassword!,
        );
        print('✅ Signed into Supabase: ${signInResponse.user?.email}');

        // Sync user profile to public.users table
        final userId = signInResponse.user?.id;
        if (userId != null) {
          await _syncUserProfile(
            userId: userId,
            email: _pendingEmail!,
            name: stagedName,
          );
        }

        print('   Session exists: ${_supabase.auth.currentSession != null}');
      } catch (e) {
        print('❌ Supabase sync after OTP failed: $e');
        throw Exception(
          'Account verification succeeded but sync failed. Please sign in again.',
        );
      } finally {
        // Clear pending credentials
        _pendingEmail = null;
        _pendingPassword = null;
        _pendingUsername = null;
      }
    } else if (_supabase.auth.currentUser == null) {
      print('⚠️ Email verified but no Supabase session. Please sign in.');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    final result = await FlutterBetterAuth.client.signOut();
    _requireData(result, fallback: 'Sign out failed. Please try again.');
    _currentSession = null;
    _currentUser = null;
    _authStateController.add(null);

    // Also sign out of Supabase Auth
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Supabase sign-out warning: $e');
    }
  }

  /// Sign in with Google (web auth redirect flow)
  Future<void> signInWithGoogle() async {
    final result = await FlutterBetterAuth.client.signIn.social(
      provider: 'google',
      disableRedirect: true,
      callbackURL: '${ApiConstants.betterAuthCallbackScheme}://auth-callback',
      callbackUrlScheme: ApiConstants.betterAuthCallbackScheme,
    );
    _requireData(result, fallback: 'Google sign-in failed. Please try again.');
    await _refreshSession();
  }

  /// Request a password reset email
  Future<void> requestPasswordReset(String email) async {
    final result = await FlutterBetterAuth.client.forgotPassword(email: email);
    _requireData(result, fallback: 'Password reset request failed.');
  }

  /// Update user profile picture URL
  Future<void> updateProfilePicture(String imageUrl) async {
    if (_currentUser == null) throw Exception('No authenticated user');
    final result = await FlutterBetterAuth.client.updateUser(image: imageUrl);
    _requireData(result, fallback: 'Failed to update profile picture.');
    await _refreshSession();
  }

  /// Update user's display name
  Future<void> updateUsername(String username) async {
    if (_currentUser == null) throw Exception('No authenticated user');

    final trimmed = username.trim();
    if (trimmed.isEmpty) throw Exception('Name cannot be empty');
    if (trimmed.length > 32) {
      throw Exception('Name is too long (max 32 characters)');
    }

    final result = await FlutterBetterAuth.client.updateUser(name: trimmed);
    _requireData(result, fallback: 'Failed to update name.');
    await _refreshSession();
  }

  bool isProfileNameSyncWarning(Object _) => false;

  /// Get user profile picture URL
  String? getProfilePictureUrl() {
    final image = _currentUser?.image?.trim();
    return (image == null || image.isEmpty) ? null : image;
  }

  /// Remove user profile picture
  Future<void> removeProfilePicture() async {
    if (_currentUser == null) throw Exception('No authenticated user');
    final result = await FlutterBetterAuth.client.updateUser(image: '');
    _requireData(result, fallback: 'Failed to remove profile picture.');
    await _refreshSession();
  }

  /// Update password for current user
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await FlutterBetterAuth.client.changePassword(
      newPassword: newPassword,
      currentPassword: currentPassword,
    );
    _requireData(result, fallback: 'Failed to update password.');
  }

  /// Delete current user account
  Future<void> deleteAccount({String? password}) async {
    final result = await FlutterBetterAuth.client.deleteUser(
      password: password,
    );
    _requireData(result, fallback: 'Failed to delete account.');
    _currentSession = null;
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<void> _refreshSession() async {
    final result = await FlutterBetterAuth.client.getSession();
    final session = result.data;
    if (session != null) {
      _currentSession = session;
      _currentUser = session.user;
    } else {
      _currentSession = null;
      _currentUser = null;
    }
    _authStateController.add(_currentUser);
  }

  /// Sync user profile to Supabase public.users table
  Future<void> _syncUserProfile({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      print('📝 Syncing user profile to Supabase users table...');
      await _supabase.from('users').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('✅ User profile synced successfully');
    } catch (e) {
      print('⚠️ Could not sync user profile: $e');
      // Don't throw - this is not critical for auth to work
    }
  }

  T _requireData<T>(Result<T> result, {required String fallback}) {
    final data = result.data;
    if (data != null) return data;
    final message = result.error?.message ?? fallback;
    throw Exception(message);
  }

  bool _shouldRouteThroughOtpProvisioning(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('invalid login credentials') ||
        msg.contains('user not found') ||
        msg.contains('email not confirmed') ||
        msg.contains('invalid_credentials');
  }

  void _stageSupabaseSyncForOtp({
    required String email,
    required String password,
    String? username,
  }) {
    _pendingEmail = email;
    _pendingPassword = password;
    if (username != null && username.trim().isNotEmpty) {
      _pendingUsername = username.trim();
    } else if (_pendingUsername == null || _pendingUsername!.trim().isEmpty) {
      _pendingUsername = 'Runner';
    }
  }
}
