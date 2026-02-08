import "dotenv/config";
import cors from "cors";
import express from "express";
import { toNodeHandler } from "better-auth/node";

import { auth } from "./auth.js";

const app = express();
const port = Number(process.env.PORT ?? 3000);
const host = "0.0.0.0"; // Listen on all network interfaces
const isProduction = process.env.NODE_ENV === "production";
const trustedOrigins = (process.env.TRUSTED_ORIGINS ?? "")
  .split(",")
  .map((item) => item.trim())
  .filter((item) => item.length > 0);
const allowNoOrigin = process.env.ALLOW_NO_ORIGIN === "true";

// ===== REQUEST LOGGING MIDDLEWARE =====
app.use((req, _res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.url}`);
  console.log(`  Origin: ${req.headers.origin || "none"}`);
  console.log(`  User-Agent: ${req.headers["user-agent"] || "none"}`);
  next();
});

// ===== CORS WITH BETTER ERROR LOGGING =====
app.use(
  cors({
    origin: (origin, callback) => {
      console.log(
        `CORS check - Origin: ${origin || "(no origin)"}, Trusted: [${trustedOrigins.join(", ")}]`
      );

      if (!origin) {
        if (allowNoOrigin) {
          return callback(null, true);
        }
        console.error("❌ CORS BLOCKED: Missing Origin header");
        return callback(new Error("Origin header required"));
      }

      if (trustedOrigins.includes(origin)) {
        return callback(null, true);
      }
      
      console.error(`❌ CORS BLOCKED: Origin "${origin}" not in trusted list`);
      return callback(new Error("Origin not allowed by CORS"));
    },
    credentials: true
  })
);

// ===== BETTER AUTH ROUTES =====
app.use("/api/auth", toNodeHandler(auth));

// ===== HEALTH CHECK =====
app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

// ===== ERROR HANDLING MIDDLEWARE (MUST BE LAST) =====
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error("❌ ERROR CAUGHT:");
  console.error("  Path:", req.method, req.url);
  console.error("  Message:", err.message);
  console.error("  Stack:", err.stack);
  
  res.status(err.status || 500).json({
    error: isProduction ? "Internal Server Error" : err.message || "Internal Server Error",
    path: req.url
  });
});

// ===== START SERVER =====
app.listen(port, host, () => {
  console.log(`✅ Better Auth server listening on:`);
  console.log(`   - http://localhost:${port}`);
  console.log(`   - http://0.0.0.0:${port} (all interfaces)`);
  console.log(`   - Check your LAN IP with: ipconfig`);
});
