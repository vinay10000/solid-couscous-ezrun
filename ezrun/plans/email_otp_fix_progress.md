# Email OTP / "Continue with Email" Fix - Progress

## Problem
When entering email in "Continue with Email" and pressing Continue, it loads continuously. 
Even registered users can't get an OTP sent to their email.

## Root Causes Found

### 1. Flutter Client - Wrong OTP Flow (FIXED)
- **Old behavior**: `initiateEmailAuth` tried `signUp` first, then fell back to `sendEmailOtp` 
  with `type: 'email-verification'`. OTP verification used `verifyEmail` endpoint which only 
  marks email as verified but does NOT create a session.
- **Fix**: Simplified to directly send `type: 'sign-in'` OTP, and added `signInWithEmailOtp` 
  method that calls `/sign-in/email-otp` (creates a session + auto-creates user for new emails).

### 2. Auth Server - Missing SSL for Database (FIXED)
- **Old behavior**: `pg.Pool` created without SSL: `new Pool({ connectionString: databaseUrl })`
- **Fix**: Added SSL: `new Pool({ connectionString: databaseUrl, ssl: { rejectUnauthorized: false } })`
- Supabase's connection pooler requires SSL from external connections (like Render).
- Added a startup connectivity check (`SELECT 1`) to surface DB issues early.

## Files Changed

### Flutter Client (`ezrun/`)
| File | Status | Changes |
|------|--------|---------|
| `lib/core/services/auth_service.dart` | ✅ Done | Simplified `initiateEmailAuth` to use `type: 'sign-in'`; added `signInWithEmailOtp` method; added `type` param to `sendEmailOtp` |
| `lib/features/auth/presentation/screens/email_otp_screen.dart` | ✅ Done | `_verifyOtp` now calls `signInWithEmailOtp` for passwordless flow (`isSignUp == false`), and `verifyEmailOtp` for explicit signup flow |

### Auth Server (`ezrun-auth-server/`)
| File | Status | Changes |
|------|--------|---------|
| `src/auth.ts` | ✅ Done | Added `ssl: { rejectUnauthorized: false }` to Pool config; added DB connectivity check |
| `dist/auth.js` | ✅ Done | Rebuilt from TypeScript source |

### 3. Flutter Client - TypeError on server errors (FIXED)
- **Issue**: `flutter_better_auth` adapter throws `TypeError` when server returns 500 with 
  empty body (`BetterError.message` is non-nullable but receives null).
- **Fix**: Added `on TypeError catch` in `sendEmailOtp` to surface a user-friendly message.
- Error message: "Unable to reach authentication server. Please try again later."

## What's Left

### CRITICAL: Deploy auth server to Render
The Render deployment **hangs on all auth requests** because the database pool lacks SSL.
The Render server can't connect to Supabase's connection pooler without `ssl: { rejectUnauthorized: false }`.

**To deploy:**
1. Push the changes to the git repo that Render is connected to
2. Render will auto-deploy, OR manually trigger a deploy from the Render dashboard
3. After deploy, verify: the server logs should show "✅ Database pool created and connection verified"

### Test end-to-end (after deploy)
1. Test "Continue with Email" with a registered email
2. Verify OTP is received in email
3. Enter OTP and verify user is signed in with a session
4. Test with a new/unregistered email (should auto-create account)

## Verified Locally
- ✅ Database pool with SSL connects to Supabase successfully
- ✅ SMTP connection to Gmail verified
- ✅ OTP email sent successfully to `pearlsurprising@dollicons.com` via local server
- ✅ Server returns `{"success": true}` for sign-in OTP request
- ✅ No linter errors in Flutter code

## Confirmed: Render server hanging
- `GET /health` → 200 OK (no database involved)
- `POST /api/auth/email-otp/send-verification-otp` → **hangs, 60s timeout** (database query fails)
- Root cause: `pg.Pool` without SSL cannot connect to Supabase pooler from Render's infrastructure
