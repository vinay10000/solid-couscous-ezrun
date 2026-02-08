/// App-wide string constants
abstract class AppStrings {
  // ============================================
  // APP INFO
  // ============================================

  static const String appName = 'EZRUN';
  static const String appTagline = 'Run. Capture. Conquer.';

  // ============================================
  // AUTH SCREENS
  // ============================================

  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String username = 'Username';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String sendResetLink = 'Send Reset Link';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String welcomeBack = 'Welcome Back';
  static const String createAccount = 'Create Account';

  // ============================================
  // NAVIGATION
  // ============================================

  static const String navMap = 'Map';
  static const String navLeaderboard = 'Ranking';
  static const String navTraining = 'Training';
  static const String navClubs = 'Clubs';
  static const String navProfile = 'Profile';

  // ============================================
  // RUN
  // ============================================

  static const String startRun = 'Start Run';
  static const String pauseRun = 'Pause';
  static const String resumeRun = 'Resume';
  static const String endRun = 'End Run';
  static const String runComplete = 'Run Complete!';
  static const String terraCaptured = 'Terra Captured!';

  // ============================================
  // STATS
  // ============================================

  static const String distance = 'Distance';
  static const String duration = 'Duration';
  static const String pace = 'Pace';
  static const String calories = 'Calories';
  static const String territory = 'Territory';
  static const String xp = 'XP';
  static const String level = 'Level';
  static const String streak = 'Streak';

  // ============================================
  // PROFILE
  // ============================================

  static const String editProfile = 'Edit Profile';
  static const String accountSettings = 'Account Settings';
  static const String appSettings = 'App Settings';
  static const String privacy = 'Privacy';
  static const String notifications = 'Notifications';
  static const String units = 'Units';
  static const String theme = 'Theme';
  static const String about = 'About';
  static const String help = 'Help & Support';
  static const String totalRuns = 'Total Runs';
  static const String totalDistance = 'Total Distance';
  static const String territoryCaptured = 'Territory Captured';
  static const String currentLevel = 'Current Level';
  static const String currentStreak = 'Current Streak';
  static const String personalBests = 'Personal Bests';
  static const String achievements = 'Achievements';
  static const String signOutConfirm = 'Are you sure you want to sign out?';
  static const String signOutConfirmTitle = 'Sign Out';

  // ============================================
  // ERRORS
  // ============================================

  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection.';
  static const String errorInvalidEmail = 'Please enter a valid email.';
  static const String errorWeakPassword =
      'Password must be at least 8 characters.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorUsernameTaken = 'This username is already taken.';

  // ============================================
  // EMPTY STATES
  // ============================================

  static const String emptyRuns = 'No Runs Yet';
  static const String emptyRunsMessage = 'Start your first run to see it here';
  static const String emptyTerritory = 'No Territory Captured';
  static const String emptyTerritoryMessage =
      'Run to capture your first territory';
  static const String emptyClubs = 'No Clubs Joined';
  static const String emptyClubsMessage =
      'Create or join a club to run with friends';
  static const String emptyLeaderboard = 'Leaderboard Empty';
  static const String emptyLeaderboardMessage =
      'Capture territory to appear on the leaderboard';
}
