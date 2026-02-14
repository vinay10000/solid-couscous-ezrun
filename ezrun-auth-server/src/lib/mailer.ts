import nodemailer from "nodemailer";

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is required`);
  return value;
}

const smtpUser = requiredEnv("SMTP_USER");
const smtpPass = requiredEnv("SMTP_PASS");

const smtpHost = process.env.SMTP_HOST ?? "smtp.gmail.com";
const connectionTimeoutMs = Number(process.env.SMTP_CONNECTION_TIMEOUT_MS ?? "10000");
const greetingTimeoutMs = Number(process.env.SMTP_GREETING_TIMEOUT_MS ?? "10000");
const socketTimeoutMs = Number(process.env.SMTP_SOCKET_TIMEOUT_MS ?? "15000");

function createTransport(port: number, secure: boolean) {
  return nodemailer.createTransport({
    host: smtpHost,
    port,
    secure,
    auth: {
      user: smtpUser,
      pass: smtpPass,
    },
    connectionTimeout: connectionTimeoutMs,
    greetingTimeout: greetingTimeoutMs,
    socketTimeout: socketTimeoutMs,
  });
}

// Gmail commonly supports STARTTLS on 587 and SSL on 465.
// Some hosts block one of them; keep both to improve reliability.
export const transporter = createTransport(587, false);
const fallbackTransporter = createTransport(465, true);

// Verify SMTP connection at startup so credential/config issues surface early.
transporter.verify().then(() => {
  console.log("✅ SMTP connection verified");
}).catch((err: any) => {
  console.error("❌ SMTP connection failed:", err.message);
  console.error("   Trying fallback SMTP port 465...");
  fallbackTransporter.verify().then(() => {
    console.log("✅ Fallback SMTP connection verified (port 465)");
  }).catch((fallbackErr: any) => {
    console.error("❌ Fallback SMTP connection failed:", fallbackErr.message);
    console.error("   Server will continue but OTP emails will fail to send.");
    console.error("   Check SMTP_USER/SMTP_PASS and provider network access from Render.");
  });
});

type OtpEmailType = "sign-in" | "email-verification" | "forget-password";

export async function sendOtpEmail(args: {
  to: string;
  otp: string;
  type: OtpEmailType;
}) {
  const from = process.env.SMTP_FROM ?? `"EZRUN" <${smtpUser}>`;

  const purpose =
    args.type === "sign-in"
      ? "Sign in"
      : args.type === "forget-password"
        ? "Reset password"
        : "Verify your email";

  const message = {
    from,
    to: args.to,
    subject: `EZRUN OTP (${purpose})`,
    text: `Your OTP is ${args.otp}. It expires soon.`,
    html: `<p>Your OTP is <strong>${args.otp}</strong>. It expires soon.</p>`,
  };

  try {
    await transporter.sendMail(message);
  } catch (err: any) {
    const code = String(err?.code ?? "");
    const messageText = String(err?.message ?? "");
    const shouldRetryWithFallback =
      code === "ETIMEDOUT" ||
      code === "ECONNECTION" ||
      messageText.toLowerCase().includes("timeout");

    if (!shouldRetryWithFallback) {
      throw err;
    }

    console.warn("⚠️ Primary SMTP failed, retrying with fallback port 465...");
    await fallbackTransporter.sendMail(message);
  }
}

