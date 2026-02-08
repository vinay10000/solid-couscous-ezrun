# Google OAuth Fix for Mobile App

## Problem
Google OAuth doesn't allow private IP addresses (192.168.x.x) due to security restrictions.

## Solution Options

### Option 1: Use ngrok (Quick Development Solution)

1. **Install ngrok**:
   ```powershell
   # Install via winget
   winget install ngrok
   
   # Or download from https://ngrok.com/download
   ```

2. **Start your auth server**:
   ```powershell
   cd c:\Dev\run\INDVL\ezrun-auth-server
   npm run dev
   ```

3. **In a new terminal, start ngrok**:
   ```powershell
   ngrok http 3000
   ```

4. **Copy the HTTPS URL** from ngrok (e.g., `https://abc123.ngrok.io`)

5. **Update `.env`**:
   ```env
   BETTER_AUTH_URL=https://abc123.ngrok.io
   TRUSTED_ORIGINS=https://abc123.ngrok.io,ezrun://,ezrun://auth-callback
   ```

6. **Update Google Cloud Console** (https://console.cloud.google.com/apis/credentials):
   - Edit your OAuth 2.0 Client ID
   - Add to "Authorized redirect URIs":
     ```
     https://abc123.ngrok.io/api/auth/callback/google
     ```

7. **Restart your auth server** and test

### Option 2: Deploy to Production Server

Deploy your auth server to a hosting service with a real domain:
- Vercel
- Railway
- Render
- Heroku
- DigitalOcean

Then update `.env` with your production URL.

### Option 3: Temporary Workaround (Development Only)

Google Cloud Console allows `http://localhost` for development. You can:

1. **Update Google Cloud Console**:
   Add redirect URI: `http://localhost:3000/api/auth/callback/google`

2. **Update `.env`**:
   ```env
   BETTER_AUTH_URL=http://localhost:3000
   ```

3. **Access from your mobile device**:
   - This won't work directly from a physical device
   - You'll need to test on an Android emulator or use ngrok

## Current Configuration

Your current `.env` should look like:
```env
BETTER_AUTH_URL=http://localhost:3000
GOOGLE_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_google_client_secret
TRUSTED_ORIGINS=http://localhost:3000,ezrun://,ezrun://auth-callback
```

## Recommended Action

**For development**: Use ngrok (Option 1) - it's the fastest way to get Google OAuth working.

**For production**: Deploy to a hosting service with a real domain (Option 2).

## After Fixing

1. Restart your auth server
2. Test Google OAuth from your mobile app
3. Check the terminal logs for any errors

## Verification

Test the auth endpoint:
```powershell
# Check if server is running
curl http://localhost:3000/health

# Check Google OAuth redirect
curl http://localhost:3000/api/auth/callback/google
```
