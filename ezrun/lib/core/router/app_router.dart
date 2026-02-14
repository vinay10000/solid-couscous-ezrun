import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'go_router_refresh_stream.dart';
import 'router_helpers.dart';
import '../services/auth_service.dart';

// Placeholder screens - will be replaced as we implement each feature
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/email_otp_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_success_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/map/presentation/screens/main_shell_screen.dart';
import '../../features/map/presentation/screens/map_dashboard_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_image_viewer_screen.dart';
import '../../features/profile/presentation/screens/follow_list_screen.dart';
import '../../features/profile/presentation/screens/level_benefits_screen.dart';
import '../../features/profile/data/repositories/profile_social_repository.dart';
import '../../features/feed/presentation/screens/post_comments_screen.dart';
import '../../features/profile/presentation/screens/public_profile_screen.dart';
import '../../features/achievements/presentation/screens/achievements_list_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/run/presentation/screens/live_run_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/account_settings_screen.dart';
import '../../features/profile/presentation/screens/notifications_settings_screen.dart';
import '../../features/profile/presentation/screens/display_settings_screen.dart';
import '../../features/profile/presentation/screens/data_privacy_settings_screen.dart';
import '../../features/profile/presentation/screens/blocked_users_screen.dart';
import '../../features/widgets/presentation/screens/widget_config_screen.dart';

/// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(AuthService().authStateChanges);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: refresh,

    // Redirect based on auth state
    redirect: (context, state) async {
      final isLoggedIn = AuthService().isLoggedIn;

      // Get onboarding completion status
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      // IMPORTANT: Use `uri.path` (not matchedLocation) to avoid edge cases
      // where redirects run before the route is fully matched (especially with
      // query params like `/verify-email?email=...`).
      final path = state.uri.path;

      final isOnboardingRoute = path == '/onboarding';
      final isAuthRoute = path == '/sign-in' || path == '/forgot-password';
      final isOtpRoute = path == '/email-otp';

      // Not logged in, not on auth route, and haven't completed onboarding -> show onboarding
      if (!isLoggedIn &&
          !isAuthRoute &&
          !isOtpRoute &&
          !onboardingCompleted &&
          !isOnboardingRoute) {
        return '/onboarding';
      }

      // Not logged in, already on onboarding, and now onboarding is completed -> go to sign-in
      if (!isLoggedIn && isOnboardingRoute && onboardingCompleted) {
        return '/sign-in';
      }

      // Not logged in, not on auth/onboarding route, and onboarding completed -> go to sign-in
      if (!isLoggedIn &&
          !isAuthRoute &&
          !isOtpRoute &&
          !isOnboardingRoute &&
          onboardingCompleted) {
        return '/sign-in';
      }

      // Logged in and on auth route -> go to home
      if (isLoggedIn && (isAuthRoute || isOtpRoute || isOnboardingRoute)) {
        return '/';
      }

      return null;
    },

    routes: [
      // ==========================================
      // ONBOARDING ROUTE
      // ==========================================
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),

      // ==========================================
      // AUTH ROUTES
      // ==========================================
      GoRoute(
        path: '/sign-in',
        name: 'signIn',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignInScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),

      GoRoute(
        path: '/email-otp',
        name: 'emailOtp',
        pageBuilder: (context, state) {
          final args = state.extra;
          if (args is EmailOtpArgs) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: EmailOtpScreen(args: args),
              transitionsBuilder: fadeTransition,
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: const EmailOtpScreen(args: EmailOtpArgs(email: '')),
            transitionsBuilder: fadeTransition,
          );
        },
      ),

      GoRoute(
        path: '/email-otp-success',
        name: 'emailOtpSuccess',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: OtpVerificationSuccessScreen(
            email: state.uri.queryParameters['email'] ?? '',
          ),
          transitionsBuilder: fadeTransition,
        ),
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),

      // ==========================================
      // MAIN APP ROUTES (with bottom nav shell)
      // ==========================================
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          // Home / Map
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MapDashboardScreen(),
              transitionsBuilder: fadeTransition,
            ),
          ),

          // Leaderboard
          GoRoute(
            path: '/leaderboard',
            name: 'leaderboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const LeaderboardScreen(),
              transitionsBuilder: fadeTransition,
            ),
          ),

          // Training
          GoRoute(
            path: '/training',
            name: 'training',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const PlaceholderScreen(title: 'Training'),
              transitionsBuilder: fadeTransition,
            ),
          ),

          // Feed
          GoRoute(
            path: '/feed',
            name: 'feed',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const FeedScreen(),
              transitionsBuilder: fadeTransition,
            ),
          ),

          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionsBuilder: fadeTransition,
            ),
          ),
        ],
      ),

      // ==========================================
      // STANDALONE ROUTES
      // ==========================================

      // Live Run
      GoRoute(
        path: '/run',
        name: 'run',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LiveRunScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),

      // Run Summary
      GoRoute(
        path: '/run-summary/:runId',
        name: 'runSummary',
        pageBuilder: (context, state) {
          final runId = state.pathParameters['runId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlaceholderScreen(title: 'Run Summary: $runId'),
            transitionsBuilder: fadeTransition,
          );
        },
      ),

      // Club Detail
      GoRoute(
        path: '/club/:clubId',
        name: 'clubDetail',
        pageBuilder: (context, state) {
          final clubId = state.pathParameters['clubId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlaceholderScreen(title: 'Club: $clubId'),
            transitionsBuilder: slideTransition,
          );
        },
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: slideTransition,
        ),
        routes: [
          GoRoute(
            path: 'account',
            name: 'accountSettings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AccountSettingsScreen(),
              transitionsBuilder: slideTransition,
            ),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notificationSettings', // Distinct from 'notifications' route
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NotificationsSettingsScreen(),
              transitionsBuilder: slideTransition,
            ),
          ),
          GoRoute(
            path: 'display',
            name: 'displaySettings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DisplaySettingsScreen(),
              transitionsBuilder: slideTransition,
            ),
          ),
          GoRoute(
            path: 'data-privacy',
            name: 'dataPrivacySettings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DataPrivacySettingsScreen(),
              transitionsBuilder: slideTransition,
            ),
          ),
          GoRoute(
            path: 'blocked',
            name: 'blockedUsers',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const BlockedUsersScreen(),
              transitionsBuilder: slideTransition,
            ),
          ),
          GoRoute(
            path: 'widget',
            name: 'widgetConfig',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const WidgetConfigScreen(),
              transitionsBuilder: slideTransition,
            ),
          ),
        ],
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: slideTransition,
        ),
      ),

      // Vault
      GoRoute(
        path: '/vault',
        name: 'vault',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlaceholderScreen(title: 'Vault'),
          transitionsBuilder: slideTransition,
        ),
      ),

      // Profile Image Viewer
      GoRoute(
        path: '/profile-image-viewer',
        name: 'profileImageViewer',
        pageBuilder: (context, state) {
          final imageUrl = state.uri.queryParameters['imageUrl'];
          final username = state.uri.queryParameters['username'] ?? 'Runner';
          final canDelete =
              state.uri.queryParameters['canDelete'] == '1' ||
              state.uri.queryParameters['canDelete'] == 'true';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ProfileImageViewerScreen(
              imageUrl: imageUrl,
              username: username,
              canDelete: canDelete,
            ),
            transitionsBuilder: fadeTransition,
          );
        },
      ),

      // Followers list
      GoRoute(
        path: '/followers/:userId',
        name: 'followers',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: FollowListScreen(
              userId: userId,
              type: FollowListType.followers,
            ),
            transitionsBuilder: slideTransition,
          );
        },
      ),

      // Following list
      GoRoute(
        path: '/following/:userId',
        name: 'following',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: FollowListScreen(
              userId: userId,
              type: FollowListType.following,
            ),
            transitionsBuilder: slideTransition,
          );
        },
      ),

      // Post Comments
      GoRoute(
        path: '/post/:postId/comments',
        name: 'postComments',
        pageBuilder: (context, state) {
          final postId = state.pathParameters['postId']!;
          final postAuthorName =
              state.uri.queryParameters['authorName'] ?? 'Runner';
          return CustomTransitionPage(
            key: state.pageKey,
            child: PostCommentsScreen(
              postId: postId,
              postAuthorName: postAuthorName,
            ),
            transitionsBuilder: slideTransition,
          );
        },
      ),

      // Public Profile (other users)
      GoRoute(
        path: '/u/:userId',
        name: 'publicProfile',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PublicProfileScreen(userId: userId),
            transitionsBuilder: slideTransition,
          );
        },
      ),

      // Achievements
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AchievementsListScreen(),
          transitionsBuilder: slideTransition,
        ),
      ),

      // Level Benefits
      GoRoute(
        path: '/level-benefits/:currentLevel',
        name: 'levelBenefits',
        pageBuilder: (context, state) {
          final currentLevel =
              int.tryParse(state.pathParameters['currentLevel'] ?? '1') ?? 1;
          return CustomTransitionPage(
            key: state.pageKey,
            child: LevelBenefitsScreen(currentUserLevel: currentLevel),
            transitionsBuilder: slideTransition,
          );
        },
      ),
    ],
  );
});
