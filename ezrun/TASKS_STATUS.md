## Profile UI + Theme Toggle — Status

### Completed
- [x] **Profile header text**: Top-left now shows `Profile` (no username in the header).
- [x] **Top-right icons**: Kept the existing two actions (no new icons added).
- [x] **Background effect**: Added a light blue/green “wash” background layer for the main Profile screen.
- [x] **Settings option**: Added a persisted toggle in Settings to enable/disable the Profile background theme.
- [x] **Persistence**: Stored via SharedPreferences and loaded through `SettingsController`.

### Left to do
- [ ] **Nothing pending** for this request.

# Tasks Status (EZRUN)

## Completed
- **ErrorHandler fixes (Jan 17, 2026)**: Fixed invalid Material icon reference in `error_handler.dart` and refactored dialog widgets into `core/widgets/status_dialogs.dart` to eliminate analyzer errors, remove deprecated opacity usage, and keep files under 500 lines. Analyzer now clean for both files.
- **Onboarding Screen (Jan 17, 2026)**: Created a modern 3-page onboarding carousel using `onboarding_1.png`. Features include smooth page transitions, skip button, back/next navigation, page indicators, and persistent storage via SharedPreferences. Integrated into router with smart redirect logic (shows on first app launch, skips on return visits or for logged-in users). Design system compliant (dark theme, cyan accents, proper spacing). Zero lint errors.
- **Google sign-in icon**: Replaced arrow icon with proper Google icon for Google sign-in button.
- **Profile image viewer**: Tap profile picture opens full-screen viewer with smooth rounded corners.
- **Public profile avatar viewer**: Tapping the profile pic on the Public Profile page opens the same full-screen viewer (without delete action).
- **Profile image delete**: Delete option removes the image reference from Supabase user metadata and attempts to delete the file from ImageKit.
- **Profile name edit (real-time)**: Tap your name on Profile to edit it; updates Supabase Auth metadata immediately and syncs public `users.name` (with a warning fallback if public sync fails).
- **Map dashboard (Mapbox)**: Replaced placeholder with Mapbox dashboard, controls (zoom/recenter), and Start Run navigation.
- **Mapbox ornaments**: Disabled Mapbox logo/caption, attribution ("i" icon), and scale bar in `MapDashboardScreen._onMapCreated`.
- **Android permissions**: Added required location permissions to `android/app/src/main/AndroidManifest.xml` so Android shows permissions and prompts correctly.
- **Mapbox Standard (3D) style**: Switched map style to Mapbox Standard and set default pitch for 3D view.
- **Mapbox Standard dusk lighting**: Applied `basemap.lightPreset = dusk` so the 3D map renders in dusk theme.
- **Mapbox Flutter SDK alignment**: Updated `mapbox_maps_flutter` to `^2.17.0` and set Standard style via `MapWidget.styleUri` per SDK docs.
- **Liquid Glass (safe integration)**: Added `liquid_glass_renderer` and integrated into bottom navigation with a safe default (falls back unless explicitly enabled).
- **Profile back navigation**: Back arrow on `ProfileScreen` now returns to Map (`/` → `MapDashboardScreen`) instead of popping.
- **Profile overflow fix**: Fixed small bottom RenderFlex overflow by adjusting bottom padding/spacing in `ProfileScreen`.
- **Achievements icons fix**: Removed the `ColorFiltered` multiply-with-transparent bug that could blank out unlocked icons; added deterministic icon sizing so assets always render inside the grid.
- **Pubspec assets fix (Achievements icons)**: Fixed `pubspec.yaml` indentation so `flutter/assets` is under the `flutter:` section (was accidentally nested under `flutter_launcher_icons:`), and explicitly included `assets/images/achievements/`.
- **Bottom nav rename**: Replaced “Clubs” with “Feed” tab and route (`/clubs` → `/feed`).
- **Supabase restore**: Supabase project restored from INACTIVE (was blocking schema operations).
- **My Runs (map overlay + bottom sheet)**: Added “My runs” button on the map dashboard that opens a snapping draggable bottom sheet (25% → 50% → 75% → 100%) showing the current user’s run list and statuses.
- **Custom runs (manual logging)**: Added “Add custom run” in Profile (distance, duration, note) saved locally (per-user) and shown inside the My Runs list.
- **Custom runs (manual logging, Supabase-backed)**: Added “Add custom run” in Profile (distance, duration, note) and store it in Supabase `ezrun_runs` (RLS: users can only read/write their own). These runs appear in “My Runs”.
- **Custom runs management**: Added **Edit/Delete** actions for custom runs from the My Runs list (updates/deletes in Supabase with RLS).
- **UI polish**: Bottom navigation bar is hidden while the **Add/Edit custom run** sheet is open.
- **UI polish**: Bottom navigation bar is hidden while the **My Runs** bottom sheet is open.
- **Runs UX**: My Runs data is prefetched on app start (cached provider), so opening the My Runs sheet is instant.
- **Territories (debug visual check)**: Added **5 mock Bangalore territories** to render on the Home map (Cubbon Park, Lalbagh, Indiranagar 100ft, Koramangala 5th Block, Bellandur/RMZ Ecospace) so you can confirm polygon rendering quickly.
- **Territories (debug visual check)**: Added mock Bangalore territories for a quick rendering check (later removed once real seeding was done).
- **Territories (map look)**: Increased territory vibrance/opacity and switched Mapbox Standard lighting to **night** so territory colors look brighter and closer to the reference.
- **Territories (readability + organic shapes)**: Added **thicker dark outlines** (polyline overlay) and updated mock territories to **irregular multi-point polygons** (no rectangles).
- **Territories (real seeding)**: Seeded **5 real territories** in Supabase for user `john_smith` (`3aa5dcff-0fd8-45ba-b3ed-a254008de9e6`) via `ezrun_claim_territory` RPC (Cubbon Park, Lalbagh, Indiranagar 100ft/Toit, Koramangala 5th Block/Forum, Bellandur/RMZ Ecospace).
- **Territories (more seeding)**: Added **5 more** real territories for `john_smith` (KIA Airport, Nandi Hills base, Hebbal Lake, HSR Layout Sector 7, Jayanagar 4th Block).
- **Territories (tap → details)**: Tapping a territory polygon now opens a bottom sheet showing territory info, with live updates streamed from the `ezrun_territories` row.
- **Territories (bugfix)**: Fixed Home map crash by switching `ref.listen` (invalid in `initState`) to `ref.listenManual` with proper dispose.
- **Territories (seed second user)**: Seeded **5 real territories** for `patelsinghh04` (`db4ac973-3d3e-41e0-abc3-87f06f16e310`) (MG Road/Trinity, Whitefield/ITPL, Electronic City Phase 1, Banashankari 2nd Stage, Yelahanka New Town).
- **Territories (DB fix: run stats)**: Updated `ezrun_get_territories()` to include run stats (distance/duration/pace) for the territory details popup.
- **Territories (DB fix: type mismatch)**: Fixed PostgREST error `Returned type numeric does not match expected type double precision` by casting `ezrun_runs.distance_km` to `DOUBLE PRECISION` in `ezrun_get_territories()`.
- **Territories (popup UI)**: Restyled the territory details popup into a Feed-style card (avatar/name/date/title + 4 metrics: Distance/Duration/Avg Pace/Terra area).
- **Territories (popup UI polish)**: Removed the white horizontal bars (drag handle + divider) from the popup to match the reference UI.
- **Territories (popup data)**: Extended `ezrun_get_territories()` to include `run_note` and `profile_pic` for the popup card header/title.
- **Map (profile entrypoint)**: Added a Map Home overlay pill (your avatar + name) that opens your Public Profile on tap.
- **Leaderboard UI (theme match)**: Restyled `/leaderboard` to match the reference layout (Weekly/All time toggle, podium blocks, list rows) while keeping the existing XP/points logic untouched.
- **Auth (email verification UX)**: Added `/verify-email` screen shown after sign-up when email confirmation is required; polls Supabase for `emailConfirmedAt` and shows an in-app “Email Verified” bottom popup using `assets/images/email_verified.png` (with a safe fallback if the asset is missing).

## Left / Next
- **Asset (email verified illustration)**: Add `assets/images/email_verified.png` (used by the “Email Verified” popup avatar/illustration).
- **Territories (DB apply)**: Apply `supabase_migrations/territory_add_run_data.sql` (adds run stats + `run_note` + `profile_pic` to `ezrun_get_territories()`), then apply `supabase_migrations/territory_fix_get_territories_run_distance_cast.sql` (casts `ezrun_runs.distance_km` → `DOUBLE PRECISION` and keeps the signature aligned) so the map can load territories without PostgREST type errors.
- **Auth (Google Sign-In)**:
  - **Native Android OAuth setup required**: Create a Google **Android OAuth client** (package + SHA-1) and set `ApiConstants.googleWebClientId` (server client id) for `google_sign_in`.
  - **Supabase provider**: Ensure Google provider is enabled so Supabase accepts Google sign-in via `signInWithIdToken`.
  - **Test flow**: Tap "Continue with Google" on Sign In, select account, verify you land on `/` immediately (no app restart) with a valid session.
- **Mapbox compliance decision**: If attribution is required, switch from disabled to repositioned (e.g., `OrnamentPosition.TOP_RIGHT`) instead of hiding.
- **Liquid Glass (real mode)**: Enable real liquid glass by running with `--dart-define ENABLE_LIQUID_GLASS=true` and verify performance on your Android device (Impeller required).
- **Verify ImageKit deletion correctness**: Ensure we delete by ImageKit *fileId* (may require storing `fileId` returned by ImageKit on upload, rather than deriving from URL).
- **Map polish**: Add 3D-friendly camera presets (bearing/pitch toggles), optional terrain/sky, and a “3D” toggle.
- **Run tracking**: Implement `/run` screen (GPS tracking, polyline, stats).
- **Runs backend**: Add DB schema + RLS + RPC for runs so the My Runs sheet can load real data (`ezrun_my_runs` RPC or `ezrun_runs` table).
- **Runs polish**: Add edit/delete for runs (at least for custom runs), and status workflows for territory capture/rejections.
- **Runs recap**: Replace placeholder `/run-summary/:runId` for custom runs with a real recap screen (or disable recap for custom runs).
- **Feed (Explore / Following)**: Build `/feed` with Explore + Following tabs and post list UI.
- **Leaderboard (Weekly)**: Wire the "Weekly" toggle to real weekly points (requires backend/data source); currently it is UI-only and uses the same existing leaderboard stream.
- **Social system (Instagram-like)**:
  - **Posts**: Photo posts, captions, timestamps.
  - **Likes**: Like/unlike per post + counts.
  - **Comments**: Comment list + add comment.
  - **Follow graph**: Follow/unfollow, followers/following counts.
  - **Profile integration**: Show followers/following counts; tap opens followers/following user lists.
  - **Follow requests (DB apply)**: Apply `supabase_migrations/social_follow_requests.sql` to your Supabase project so follow requests + `users.is_private` work end-to-end.
  - **Privacy UI**: Add a Profile setting toggle to update `users.is_private` (so users can control whether follows require approval).

## In Progress / Implemented (Social)
- **DB schema + RLS**: Added `ezrun_posts`, `ezrun_post_likes`, `ezrun_post_comments`, `ezrun_follows` + feed RPCs.
- **Feed**: Explore/Following tabs now load from Supabase; like/unlike + comments screen working.
- **Create Post**: Supports **photo+caption** or **text-only**. Photos upload to ImageKit (`/ezrun/posts/`) → create `ezrun_posts` record.
- **Profile social counts**: Posts/Followers/Following counts shown; tapping Followers/Following opens list screens.
- **Explore follow UX**: Explore posts show a Follow/Following button next to the username; tapping username/avatar opens a Public Profile screen.
- **Public Profile follow**: Public Profile page also shows Follow/Following (state-aware) for the viewed user.
- **Notifications screen**: Added `/notifications` screen that shows:
  - **Likes on your posts**: “the "username" liked your post”
  - **Follow requests**: Incoming requests with **Accept/Deny** actions (accept creates `ezrun_follows` edge)
- **Follow request UX (private accounts)**: If `users.is_private = true`, tapping Follow creates a `ezrun_follow_requests` pending request and shows **Requested** state in Explore/Public Profile.


