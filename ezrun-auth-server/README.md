# EZRUN Better Auth Server

Minimal Better Auth server for EZRUN (email/password + Google + Email OTP).

## Architecture (high level)

- Flutter calls this backend only.
- This backend runs Better Auth (sessions, users, verification).
- Database is Postgres (your Supabase Postgres is fine via `DATABASE_URL`).
- OTP emails are delivered via **Gmail SMTP** (Nodemailer).

## Setup

### Gmail SMTP (one-time)

- Enable 2-Step Verification on the Gmail account.
- Create an App Password (Mail → Other → `otp-app`).
- Save the 16-character password.

SMTP config:
- Host: `smtp.gmail.com`
- Port: `587`
- Secure: `false`

### Server env

Create `.env` from `.env.example`:
- `BETTER_AUTH_SECRET` (>= 32 chars)
- `BETTER_AUTH_URL` (e.g. `https://auth.your-domain.com`)
- `DATABASE_URL` (Postgres connection string; Supabase Postgres works)
- `TRUSTED_ORIGINS` (comma-separated, include `ezrun://`)
- `SMTP_USER` / `SMTP_PASS` / `SMTP_FROM`
- `OTP_EXPIRY_MINUTES`, `OTP_ALLOWED_ATTEMPTS`, `OTP_LENGTH`

### Install deps

```
npm install
```

### Generate schema (Better Auth CLI)

```
npx @better-auth/cli@latest generate
```

## Endpoints

- Mounted Better Auth at `/api/auth/{*any}` (Express v5 path syntax).
- Email OTP plugin endpoints are under:
  - `/api/auth/email-otp/send-verification-otp`
  - `/api/auth/email-otp/verify-email`
  - `/api/auth/sign-in/email-otp`

## Notes

- OTP storage is configured as **hashed**, with **5 min expiry** and **5 attempts** by default.
- Update your Flutter client base URL to `http://<backend-host>:3000/api/auth`.

## Deploy (Render)

This repo includes `render.yaml` for one-click setup.

1. Push `ezrun-auth-server` to GitHub.
2. In Render, create a new Web Service from that repo.
3. Render will detect `render.yaml`; keep build/start commands from it.
4. Set required env vars in Render:
   - `BETTER_AUTH_SECRET`
   - `BETTER_AUTH_URL` (use your Render URL or custom domain, `https://...`)
   - `DATABASE_URL`
   - `TRUSTED_ORIGINS`
   - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` (if using Google sign-in)
   - `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`
5. Deploy, then verify:
   - `GET https://<your-backend-domain>/health` returns `{"status":"ok"}`.

### Flutter app URL after deploy

Set Flutter `BETTER_AUTH_BASE_URL` to:

`https://<your-backend-domain>/api/auth`

Do not keep it on localhost for production builds.
