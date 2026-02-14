import nodemailer from "nodemailer";

type OtpEmailType = "sign-in" | "email-verification" | "forget-password";

const resendApiKey = process.env.RESEND_API_KEY?.trim();
const resendFrom =
  process.env.RESEND_FROM?.trim() ??
  process.env.SMTP_FROM?.trim() ??
  "EZRUN <onboarding@resend.dev>";

const smtpUser = process.env.SMTP_USER?.trim();
const smtpPass = process.env.SMTP_PASS?.trim();
const smtpConfigured = Boolean(smtpUser && smtpPass);

const smtpHost = process.env.SMTP_HOST ?? "smtp.gmail.com";
const connectionTimeoutMs = Number(process.env.SMTP_CONNECTION_TIMEOUT_MS ?? "10000");
const greetingTimeoutMs = Number(process.env.SMTP_GREETING_TIMEOUT_MS ?? "10000");
const socketTimeoutMs = Number(process.env.SMTP_SOCKET_TIMEOUT_MS ?? "15000");
const resendTimeoutMs = Number(process.env.RESEND_TIMEOUT_MS ?? "10000");

function createTransport(port: number, secure: boolean) {
  if (!smtpUser || !smtpPass) {
    throw new Error("SMTP credentials are not configured");
  }

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

const transporter = smtpConfigured ? createTransport(587, false) : null;
const fallbackTransporter = smtpConfigured ? createTransport(465, true) : null;

if (resendApiKey) {
  console.log("✅ Resend email provider configured");
} else {
  console.warn("⚠️ RESEND_API_KEY not configured; will use SMTP if available.");
}

if (transporter && fallbackTransporter) {
  transporter.verify().then(() => {
    console.log("✅ SMTP connection verified");
  }).catch((err: any) => {
    console.error("❌ SMTP connection failed:", err.message);
    console.error("   Trying fallback SMTP port 465...");
    fallbackTransporter.verify().then(() => {
      console.log("✅ Fallback SMTP connection verified (port 465)");
    }).catch((fallbackErr: any) => {
      console.error("❌ Fallback SMTP connection failed:", fallbackErr.message);
      console.error("   Server will continue but OTP emails may fail to send.");
      console.error("   Configure RESEND_API_KEY for reliable delivery on Render.");
    });
  });
} else {
  console.warn("⚠️ SMTP_USER/SMTP_PASS not configured; SMTP fallback disabled.");
}

function formatPurpose(type: OtpEmailType): string {
  return type === "sign-in"
    ? "Sign in"
    : type === "forget-password"
      ? "Reset password"
      : "Verify your email";
}

async function sendViaResend(args: {
  to: string;
  otp: string;
  type: OtpEmailType;
}) {
  if (!resendApiKey) {
    throw new Error("RESEND_API_KEY is not configured");
  }

  const purpose = formatPurpose(args.type);
  const abortController = new AbortController();
  const timeoutHandle = setTimeout(() => abortController.abort(), resendTimeoutMs);

  try {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: resendFrom,
        to: [args.to],
        subject: `EZRUN OTP (${purpose})`,
        text: `Your OTP is ${args.otp}. It expires soon.`,
        html: `<p>Your OTP is <strong>${args.otp}</strong>. It expires soon.</p>`,
      }),
      signal: abortController.signal,
    });

    if (!response.ok) {
      const rawBody = await response.text();
      throw new Error(`Resend API error (${response.status}): ${rawBody}`);
    }
  } finally {
    clearTimeout(timeoutHandle);
  }
}

async function sendViaSmtp(args: {
  to: string;
  otp: string;
  type: OtpEmailType;
}) {
  if (!transporter || !fallbackTransporter || !smtpUser) {
    throw new Error("SMTP is not configured");
  }

  const message = {
    from: process.env.SMTP_FROM ?? `"EZRUN" <${smtpUser}>`,
    to: args.to,
    subject: `EZRUN OTP (${formatPurpose(args.type)})`,
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

export async function sendOtpEmail(args: {
  to: string;
  otp: string;
  type: OtpEmailType;
}) {
  const errors: string[] = [];

  if (resendApiKey) {
    try {
      await sendViaResend(args);
      return;
    } catch (err: any) {
      errors.push(`Resend: ${String(err?.message ?? err)}`);
      console.error("❌ Resend send failed:", err?.message ?? err);
    }
  }

  if (smtpConfigured) {
    try {
      await sendViaSmtp(args);
      return;
    } catch (err: any) {
      errors.push(`SMTP: ${String(err?.message ?? err)}`);
      console.error("❌ SMTP send failed:", err?.message ?? err);
    }
  }

  throw new Error(
    `No email provider could send OTP. ${errors.join(" | ") || "No provider configured."}`,
  );
}

