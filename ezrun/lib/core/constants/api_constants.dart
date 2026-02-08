import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API and configuration constants
abstract class ApiConstants {
  static String _env(String key, String fallback) =>
      dotenv.maybeGet(key) ?? fallback;

  // ============================================
  // SUPABASE CONFIGURATION
  // Replace these with your actual values
  // ============================================

  /// Supabase project URL
  static String get supabaseUrl => _env(
    'SUPABASE_URL',
    'https://olyuuljglgcycjaufoyt.supabase.co',
  );

  /// Supabase anonymous key
  static String get supabaseAnonKey => _env(
    'SUPABASE_ANON_KEY',
    'sb_publishable_1JKuPs_IvSzoKeco3b96pg_jKSHiMDe',
  );

  // ============================================
  // AUTH (GOOGLE SIGN-IN)
  // ============================================

  /// Google OAuth "Web application" client id (used as serverClientId)
  ///
  /// Even for native Android sign-in, Google issues the ID token for a "server"
  /// audience. For Flutter `google_sign_in`, this is provided as `serverClientId`.
  ///
  /// Example:
  ///   1234567890-abcdefg.apps.googleusercontent.com
  static String get googleWebClientId => _env(
    'GOOGLE_WEB_CLIENT_ID',
    'your_google_web_client_id.apps.googleusercontent.com',
  );

  // ============================================
  // BETTER AUTH CONFIGURATION
  // ============================================

  /// Better Auth base URL (include `/api/auth`)
  static String get betterAuthBaseUrl => _env(
    'BETTER_AUTH_BASE_URL',
    'http://localhost:3000/api/auth',
  );

  /// Better Auth callback scheme (used for social sign-in)
  static String get betterAuthCallbackScheme => _env(
    'BETTER_AUTH_CALLBACK_SCHEME',
    'ezrun',
  );

  /// Better Auth secret (server-only; do not ship in production builds)
  static String get betterAuthSecret =>
      _env('BETTER_AUTH_SECRET', 'set_in_local_env_only');

  // ============================================
  // IMAGEKIT CONFIGURATION
  // ============================================

  /// ImageKit public key
  static String get imageKitPublicKey => _env(
    'IMAGEKIT_PUBLIC_KEY',
    'public_w2aMVbEkSHlMI8jXUWHwtU5gRz4=',
  );

  /// ImageKit private key (keep secure in production)
  static String get imageKitPrivateKey =>
      _env('IMAGEKIT_PRIVATE_KEY', 'set_in_local_env_only');

  /// ImageKit endpoint
  static String get imageKitEndpoint => _env(
    'IMAGEKIT_ENDPOINT',
    'https://upload.imagekit.io/api/v1/files/upload',
  );

  // ============================================
  // MAPBOX CONFIGURATION
  // Replace with your actual token
  // ============================================

  /// Mapbox access token
  static String get mapboxAccessToken => _env(
    'MAPBOX_ACCESS_TOKEN',
    'pk.eyJ1Ijoia2ltZG9ramEwIiwiYSI6ImNtZTN6bzY2ODA1cmEya3F3YjdqZW5wcmkifQ.1aZ7qasxm49t3vsfDrtxbA',
  );

  /// Mapbox dark style URL
  static const String mapboxStyleDark = 'mapbox://styles/mapbox/dark-v11';

  /// Mapbox Standard (3D) core style URL
  static const String mapboxStyleStandard = 'mapbox://styles/mapbox/standard';

  /// Mapbox satellite style URL
  static const String mapboxStyleSatellite =
      'mapbox://styles/mapbox/satellite-streets-v12';

  // ============================================
  // MAP DEFAULTS
  // ============================================

  /// Default map center latitude
  static const double defaultLatitude = 0.0;

  /// Default map center longitude
  static const double defaultLongitude = 0.0;

  /// Default map zoom level
  static const double defaultZoom = 15.0;

  /// Min zoom level
  static const double minZoom = 3.0;

  /// Max zoom level
  static const double maxZoom = 20.0;

  // ============================================
  // H3 TERRITORY GRID
  // ============================================

  /// H3 resolution for territory hexagons
  /// Resolution 8 = ~460m edge, ~0.74 km² area
  static const int h3Resolution = 8;

  // ============================================
  // TIMEOUTS
  // ============================================

  /// Connection timeout in milliseconds
  static const int connectionTimeout = 30000;

  /// Receive timeout in milliseconds
  static const int receiveTimeout = 30000;

  // ============================================
  // GPS SETTINGS
  // ============================================

  /// Distance filter for GPS updates (meters)
  static const int gpsDistanceFilter = 5;

  /// GPS update interval (milliseconds)
  static const int gpsUpdateInterval = 1000;
}
