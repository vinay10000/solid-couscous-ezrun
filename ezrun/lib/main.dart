import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/profile/presentation/state/settings_controller.dart';

import 'core/constants/api_constants.dart';
import 'core/services/auth_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for immersive dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase (data backend)
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  // Initialize Better Auth
  final betterAuthUrl = await _resolveBetterAuthBaseUrl();
  debugPrint('Better Auth URL: $betterAuthUrl');
  await FlutterBetterAuth.initialize(
    url: betterAuthUrl,
    dio: _buildBetterAuthDio(),
  );
  await AuthService().hydrate();

  // Initialize Mapbox
  MapboxOptions.setAccessToken(ApiConstants.mapboxAccessToken);

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: BetterAuthProvider(child: const EzrunApp()),
    ),
  );
}

/// Root application widget
class EzrunApp extends ConsumerWidget {
  const EzrunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider);
    final themeMode = settings.themePreference.toThemeMode();

    return MaterialApp.router(
      title: 'EZRUN',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.buildLightTheme(),
      darkTheme: AppTheme.buildDarkTheme(),
      themeMode: themeMode,

      // Routing
      routerConfig: router,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
        );
        return child ?? const SizedBox.shrink();
      },

      // Scroll behavior for smooth scrolling
      scrollBehavior: const _AppScrollBehavior(),
    );
  }
}

Dio _buildBetterAuthDio() {
  final headers = <String, dynamic>{
    'Content-Type': 'application/json',
    'User-Agent': 'FlutterBetterAuth/1.0.0',
    'flutter-origin': 'flutter://',
    'expo-origin': 'exp://',
    'x-skip-oauth-proxy': true,
  };

  if (!kIsWeb) {
    final nativeOrigin = '${ApiConstants.betterAuthCallbackScheme}://';
    headers['origin'] = nativeOrigin;
    headers['referer'] = nativeOrigin;
    headers['x-mobile-origin'] = nativeOrigin;
  }

  return Dio(
    BaseOptions(
      headers: headers,
      validateStatus: (status) => status != null && status < 300,
    ),
  );
}

Future<String> _resolveBetterAuthBaseUrl() async {
  final envUrl =
      dotenv.maybeGet('BETTER_AUTH_BASE_URL') ??
      const String.fromEnvironment(
        'BETTER_AUTH_BASE_URL',
        defaultValue: 'https://solid-couscous-ezrun.onrender.com/api/auth',
      );

  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return envUrl;
  }

  final uri = Uri.tryParse(envUrl);
  final host = uri?.host;
  final isLoopbackHost = host == 'localhost' || host == '127.0.0.1';
  if (!isLoopbackHost) {
    return envUrl;
  }

  final androidInfo = await DeviceInfoPlugin().androidInfo;
  if (androidInfo.isPhysicalDevice) {
    // Keep localhost for real devices so adb reverse can map it to the dev machine.
    return envUrl;
  }

  return envUrl
      .replaceFirst('localhost', '10.0.2.2')
      .replaceFirst('127.0.0.1', '10.0.2.2');
}

/// Custom scroll behavior with smooth physics
class _AppScrollBehavior extends ScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
