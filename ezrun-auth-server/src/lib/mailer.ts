import nodemailer from "nodemailer";

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is required`);
  return value;
}

const smtpUser = requiredEnv("SMTP_USER");
const smtpPass = requiredEnv("SMTP_PASS");

export const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 587,
  secure: false,
  auth: {
    user: smtpUser,
    pass: smtpPass,
  },
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

  await transporter.sendMail({
    from,
    to: args.to,
    subject: `EZRUN OTP (${purpose})`,
    text: `Your OTP is ${args.otp}. It expires soon.`,
    html: `<p>Your OTP is <strong>${args.otp}</strong>. It expires soon.</p>`,
  });
}

