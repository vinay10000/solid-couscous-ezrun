# Setting up ngrok for Google OAuth

## Steps:

1. **Install ngrok**:
   ```powershell
   winget install ngrok
   ```

2. **Start ngrok tunnel**:
   ```powershell
   ngrok http 3000
   ```

3. **Copy the HTTPS URL** (e.g., `https://abc123.ngrok.io`)

4. **Update `.env`**:
   ```
   BETTER_AUTH_URL=https://abc123.ngrok.io
   TRUSTED_ORIGINS=https://abc123.ngrok.io,ezrun://,ezrun://auth-callback
   ```

5. **Update Google Cloud Console**:
   - Go to: https://console.cloud.google.com/apis/credentials
   - Edit your OAuth 2.0 Client ID
   - Add to "Authorized redirect URIs":
     - `https://abc123.ngrok.io/api/auth/callback/google`

6. **Restart your auth server**

**Note**: ngrok URLs change each time you restart (unless you have a paid account). You'll need to update Google Cloud Console each time.
