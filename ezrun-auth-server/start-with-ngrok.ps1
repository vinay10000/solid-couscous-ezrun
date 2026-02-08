# Start auth server with ngrok for Google OAuth
# This script starts both the auth server and ngrok tunnel

Write-Host "🚀 Starting Better Auth Server with ngrok..." -ForegroundColor Green

# Check if ngrok is installed
$ngrokInstalled = Get-Command ngrok -ErrorAction SilentlyContinue
if (-not $ngrokInstalled) {
    Write-Host "❌ ngrok is not installed." -ForegroundColor Red
    Write-Host "Install it with: winget install ngrok" -ForegroundColor Yellow
    Write-Host "Or download from: https://ngrok.com/download" -ForegroundColor Yellow
    exit 1
}

# Start ngrok in background
Write-Host "📡 Starting ngrok tunnel on port 3000..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "ngrok http 3000"

# Wait a bit for ngrok to start
Start-Sleep -Seconds 3

# Try to get ngrok URL
try {
    $ngrokApi = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
    $publicUrl = $ngrokApi.tunnels[0].public_url
    
    Write-Host "`n✅ ngrok tunnel active!" -ForegroundColor Green
    Write-Host "   Public URL: $publicUrl" -ForegroundColor Cyan
    Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
    Write-Host "   1. Update .env with: BETTER_AUTH_URL=$publicUrl" -ForegroundColor White
    Write-Host "   2. Add to Google Cloud Console redirect URIs:" -ForegroundColor White
    Write-Host "      $publicUrl/api/auth/callback/google" -ForegroundColor Cyan
    Write-Host "   3. Update TRUSTED_ORIGINS in .env to include: $publicUrl" -ForegroundColor White
    Write-Host "`n🔗 Google Cloud Console: https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
    Write-Host "`n⚠️  Remember: This ngrok URL will change when you restart ngrok (unless you have a paid account)" -ForegroundColor Yellow
} catch {
    Write-Host "⚠️  Could not fetch ngrok URL automatically." -ForegroundColor Yellow
    Write-Host "   Check the ngrok window for your public URL" -ForegroundColor White
}

Write-Host "`nPress Ctrl+C to stop ngrok" -ForegroundColor Gray
