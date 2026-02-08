import nodemailer from "nodemailer";
function requiredEnv(name) {
    const value = process.env[name];
    if (!value)
        throw new Error(`${name} is required`);
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
// Verify SMTP connection at startup so credential/config issues surface early.
transporter.verify().then(() => {
    console.log("✅ SMTP connection verified");
}).catch((err) => {
    console.error("❌ SMTP connection failed:", err.message);
    console.error("   Emails will not be delivered. Check SMTP_USER and SMTP_PASS.");
});
export async function sendOtpEmail(args) {
    const from = process.env.SMTP_FROM ?? `"EZRUN" <${smtpUser}>`;
    const purpose = args.type === "sign-in"
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
