EZRUN Monorepo
================

This repository contains two apps used by the EZRUN platform:
- ezrun: Flutter mobile app (client)
- ezrun-auth-server: Node.js / TypeScript authentication API server

Getting started
Prerequisites
- Flutter SDK (for ezrun)
- Node.js and npm (for ezrun-auth-server)
- Git (optional but recommended for versioning)

Quick start
1) Run the auth server
   - cd ezrun-auth-server
   - npm install
   - cp .env.example .env (configure env vars as needed)
   - npm run dev
   
   The server runs by default on http://localhost:3000 (port can be overridden via PORT in .env).

2) Run the Flutter app
   - cd ezrun
   - flutter pub get
   - flutter run

Project structure
- ezrun/            → Flutter app (client)
- ezrun-auth-server→ Node.js / TS API server (authentication)

Contributing
- Create a feature/bugfix branch per task
- Run tests and lint when applicable
- Open a PR to review changes

Notes
- The two projects are separate; changes to one do not automatically affect the other.
- If you need a unified dev workflow, I can add a lightweight script or makefile to orchestrate both apps.




<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Welcome Screen Dark Mode</title>
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Epilogue:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://cdn.jsdelivr.net/npm/remixicon@3.5.0/fonts/remixicon.css" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,typography"></script>
<script>
      tailwind.config = {
        darkMode: "class",
        theme: {
          extend: {
            colors: {
              primary: "#000000",
              "background-light": "#FFFFFF",
              "background-dark": "#0F0F0F", // Very dark gray, almost black
              "surface-dark": "#1F1F1F",
            },
            fontFamily: {
              display: ["Epilogue", "sans-serif"],
              sans: ["Epilogue", "sans-serif"],
            },
            borderRadius: {
              DEFAULT: "0.5rem",
              'pill': '50rem',
            },
          },
        },
      };
    </script>
<style>body {
            transition: background-color 0.3s ease, color 0.3s ease;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-gray-100 dark:bg-gray-900 flex items-center justify-center min-h-screen font-sans p-4">
<div class="w-full max-w-sm bg-background-light dark:bg-background-dark h-[844px] rounded-[2.5rem] shadow-2xl overflow-hidden relative flex flex-col justify-between border-[8px] border-gray-200 dark:border-gray-800">
<div class="px-6 pt-4 pb-2 flex justify-between items-center text-xs font-semibold text-gray-900 dark:text-white">
<span>9:41</span>
<div class="flex items-center gap-1.5">
<i class="ri-signal-wifi-fill"></i>
<i class="ri-signal-tower-fill"></i>
<i class="ri-battery-fill text-lg"></i>
</div>
</div>
<div class="px-6 py-2 flex justify-between items-center">
<button class="w-10 h-10 rounded-full flex items-center justify-center hover:bg-gray-100 dark:hover:bg-surface-dark transition-colors text-gray-900 dark:text-white">
<i class="ri-arrow-left-s-line text-2xl"></i>
</button>
<button class="text-sm font-medium text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white transition-colors">
                Skip
            </button>
</div>
<div class="flex-1 flex flex-col px-8 pt-4 pb-8">
<div class="flex-1 flex items-center justify-center mb-6">
<div class="relative w-64 h-64 flex items-center justify-center">
<img alt="Person waving hello illustration" class="w-full h-full object-contain filter dark:invert dark:brightness-200 dark:contrast-150 grayscale transition-all duration-300" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCV-_9Pgv8U4U53qKaeyvRuqNzTL1v5kc6vQhE47ZytzOJU_T1xQUZjDcq0wARDDgAJivk3UXho6J6Bs2KUGtztsR8PNJkM-SvkMo4xhZ9ULZTetWNWQLaInA2OVz5FFX3yq0s9Vv9jRRIDSC8zyEHklqc7DGBXFFAz6ySw8BxJQuUdi7CRKvJELMwMXZ8UDDtIk71QgcPdrguDLNHVKkEt53C2bJlf8LLagQi6vmL45A5c1SLqWSmu_3YIptqb72p63N3ssb4jW8_g"/>
</div>
</div>
<div class="mb-8">
<h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2 flex items-center gap-2">
                    Hi ! <span class="animate-pulse">👋</span>
</h1>
<p class="text-gray-500 dark:text-gray-400 text-sm">
                    Please Sign in to continue our Apps
                </p>
</div>
<div class="space-y-4">
<button class="w-full py-4 rounded-pill bg-primary dark:bg-white text-white dark:text-black font-semibold text-base shadow-lg hover:opacity-90 transition-opacity">
                    Sign in
                </button>
<button class="w-full py-4 rounded-pill bg-primary dark:bg-white text-white dark:text-black font-semibold text-base shadow-lg hover:opacity-90 transition-opacity">
                    Sign up
                </button>
</div>
<div class="flex items-center gap-4 my-8">
<div class="h-px bg-gray-200 dark:bg-gray-800 flex-1"></div>
<span class="text-xs text-gray-400 dark:text-gray-500 font-medium">Or Sign In with</span>
<div class="h-px bg-gray-200 dark:bg-gray-800 flex-1"></div>
</div>
<div>
<button class="w-full py-4 rounded-pill border border-gray-200 dark:border-gray-700 bg-white dark:bg-surface-dark text-gray-900 dark:text-white font-semibold text-base shadow-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-all flex items-center justify-center gap-3">
<img alt="Google" class="w-5 h-5" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDe0IUroKtkHHiefdTBjI6MQcgr-01YJ3PIH86Cfujl8H7xFSo3a7zpUuGk0coLjOrOYtLeSH5b2CainQz4L3PVGJf9IzjkA85LKsYHefxaSJn3VVG0gAXyETbCjmOZEcovfNRBpEQ0oOZYl8PvTrYpzl1XitovB9-5U9qk9Ej6MHYAfW0S5VkAHi47RQxqLa9h-EqMgU8-tFNdUwypmggM3o0RKtkwkgJoRhMil-T_2wg3RSINAjMndBUO6nGUl2ij2jxgZssKSYZ2"/>
<span>Continue with Google</span>
</button>
</div>
<div class="h-4"></div>
</div>
</div>
<div class="fixed bottom-4 right-4 bg-white dark:bg-gray-800 p-4 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 hidden md:block">
<p class="text-sm font-medium text-gray-600 dark:text-gray-300 mb-2">Toggle Theme to Test</p>
<button class="bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors" onclick="document.documentElement.classList.toggle('dark')">
            Switch Mode
        </button>
</div>
<script>
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            document.documentElement.classList.add('dark');
        }
    </script>
</body></html>