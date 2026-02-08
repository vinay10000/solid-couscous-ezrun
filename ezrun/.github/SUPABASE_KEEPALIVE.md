# Supabase Keep-Alive Setup

This GitHub Actions workflow automatically pings your Supabase database every 6 days to prevent it from pausing due to inactivity.

## 🔧 Setup Instructions

### Step 1: Push to GitHub
Make sure this repository is pushed to GitHub.

### Step 2: Add GitHub Secrets
You need to add two secrets to your GitHub repository:

1. Go to your GitHub repository
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

#### Secret 1: `SUPABASE_URL`
- **Name**: `SUPABASE_URL`
- **Value**: `https://olyuuljglgcycjaufoyt.supabase.co`

#### Secret 2: `SUPABASE_ANON_KEY`
- **Name**: `SUPABASE_ANON_KEY`  
- **Value**: `sb_publishable_1JKuPs_IvSzoKeco3b96pg_jKSHiMDe`

### Step 3: Test the Workflow
1. Go to **Actions** tab in your GitHub repository
2. Select **Supabase Keep-Alive Ping** workflow
3. Click **Run workflow** → **Run workflow** (green button)
4. Wait a few seconds and check if it runs successfully ✅

## 📅 Schedule
- **Automatic runs**: Every 6 days at 3:00 AM UTC
- **Manual runs**: You can trigger it manually anytime from the Actions tab

## 🔍 How It Works
The workflow makes a simple REST API query to your Supabase database. This counts as activity and prevents Supabase from pausing your project after 7 days of inactivity.

## ⚠️ Important Notes
- This only works if your repository is on GitHub
- The workflow needs to be in the `main` or `master` branch to run on schedule
- Free tier projects still have other limitations (500MB database, 2GB bandwidth, etc.)

## 🚀 Alternative Solutions
If you prefer not to use GitHub Actions, you can also:
- Use [cron-job.org](https://cron-job.org) to ping a Supabase Edge Function
- Deploy a serverless function on Vercel/Netlify with cron
- Upgrade to Supabase Pro ($25/month) - no auto-pause

## 📊 Monitoring
Check the **Actions** tab regularly to ensure the workflow runs successfully. If it fails, your database might still pause, so fix any issues promptly!
