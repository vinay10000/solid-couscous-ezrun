import { betterAuth } from "better-auth";
import { emailOTP } from "better-auth/plugins";
import { Pool } from "pg";
import { sendOtpEmail } from "./lib/mailer.js";
const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
    throw new Error("DATABASE_URL is required");
}
const betterAuthSecret = process.env.BETTER_AUTH_SECRET;
if (!betterAuthSecret) {
    throw new Error("BETTER_AUTH_SECRET is required");
}
const betterAuthUrl = process.env.BETTER_AUTH_URL;
if (!betterAuthUrl) {
    throw new Error("BETTER_AUTH_URL is required");
}
const trustedOrigins = (process.env.TRUSTED_ORIGINS ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
if (trustedOrigins.length === 0) {
    console.warn("⚠️ No TRUSTED_ORIGINS configured; cross-origin browser requests will be blocked.");
}
const disableCsrfCheck = process.env.DISABLE_CSRF_CHECK === "true";
if (disableCsrfCheck) {
    console.warn("⚠️ CSRF protection is disabled via DISABLE_CSRF_CHECK=true.");
}
function intFromEnv(name, fallback) {
    const raw = process.env[name];
    if (!raw)
        return fallback;
    const value = Number(raw);
    if (!Number.isFinite(value) || value <= 0)
        return fallback;
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
    secret: betterAuthSecret,
    baseURL: betterAuthUrl,
    trustedOrigins,
    advanced: {
        disableCSRFCheck: disableCsrfCheck, // Enable only when explicitly configured.
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
            expiresIn: intFromEnv("OTP_EXPIRY_SECONDS", intFromEnv("OTP_EXPIRY_MINUTES", 5) * 60),
            allowedAttempts: intFromEnv("OTP_ALLOWED_ATTEMPTS", 5),
            storeOTP: "hashed",
            sendVerificationOnSignUp: true,
            async sendVerificationOTP({ email, otp, type }) {
                console.log(`📧 Sending OTP email to ${email} (${type})`);
                await sendOtpEmail({ to: email, otp, type });
                console.log(`✅ OTP email sent successfully to ${email}`);
            }
        })
    ]
});
