import { betterAuth } from "better-auth";
import { emailOTP } from "better-auth/plugins";
import { Pool } from "pg";

import { sendOtpEmail } from "./lib/mailer.js";

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  throw new Error("DATABASE_URL is required");
}

const trustedOrigins = (process.env.TRUSTED_ORIGINS ?? "")
  .split(",")
  .map((origin) => origin.trim())
  .filter((origin) => origin.length > 0);

function intFromEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const value = Number(raw);
  if (!Number.isFinite(value) || value <= 0) return fallback;
  return Math.floor(value);
}

// Create database pool with error handling
const pool = new Pool({ connectionString: databaseUrl });

pool.on("error", (err) => {
  console.error("❌ Unexpected database pool error:", err);
});

console.log("✅ Database pool created");
console.log(`   Trusted origins: [${trustedOrigins.join(", ")}]`);

export const auth = betterAuth({
  secret: process.env.BETTER_AUTH_SECRET,
  baseURL: process.env.BETTER_AUTH_URL,
  trustedOrigins,
  advanced: {
    disableCSRFCheck: true, // Disable CSRF for mobile apps
  },
  database: pool,
  emailAndPassword: {
    enabled: true,
    requireEmailVerification: true
  },
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID ?? "",
      clientSecret: process.env.GOOGLE_CLIENT_SECRET ?? ""
    }
  },
  plugins: [
    emailOTP({
      overrideDefaultEmailVerification: true,
      otpLength: intFromEnv("OTP_LENGTH", 6),
      expiresIn: intFromEnv(
        "OTP_EXPIRY_SECONDS",
        intFromEnv("OTP_EXPIRY_MINUTES", 5) * 60
      ),
      allowedAttempts: intFromEnv("OTP_ALLOWED_ATTEMPTS", 5),
      storeOTP: "hashed",
      sendVerificationOnSignUp: true,
      async sendVerificationOTP({ email, otp, type }) {
        console.log(`📧 Sending OTP email to ${email} (${type})`);
        // Avoid awaiting to reduce timing side-channels; log failures.
        void sendOtpEmail({ to: email, otp, type }).catch((err) => {
          console.error("❌ Failed to send OTP email:", err.message);
          console.error("   Full error:", err);
        });
      }
    })
  ]
});
