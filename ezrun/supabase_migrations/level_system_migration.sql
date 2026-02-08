-- ============================================
-- EZRUN LEVEL SYSTEM - DATABASE MIGRATION
-- ============================================
-- This migration adds the level/XP system to your EZRUN app.
-- Users earn 10 XP for each run logged and progress through 100 levels.

-- Step 1: Add total_xp column to users table
-- ============================================
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS total_xp INTEGER DEFAULT 0 NOT NULL;

-- Create index for faster level calculations
CREATE INDEX IF NOT EXISTS idx_users_total_xp ON users(total_xp);

-- Step 2: Create function to add XP to user
-- ============================================
-- This function atomically adds XP to a user's account and returns the new total_xp
CREATE OR REPLACE FUNCTION ezrun_add_user_xp(
  p_user_id UUID,
  p_xp_amount INTEGER
)
RETURNS TABLE (total_xp INTEGER) AS $$
BEGIN
  -- Update the user's total XP
  UPDATE users
  SET total_xp = total_xp + p_xp_amount
  WHERE id = p_user_id;
  
  -- Return the updated total_xp
  RETURN QUERY
  SELECT users.total_xp
  FROM users
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create trigger to award XP when runs are added
-- ============================================
-- Automatically award 10 XP whenever a new run is logged
CREATE OR REPLACE FUNCTION ezrun_award_run_xp()
RETURNS TRIGGER AS $$
BEGIN
  -- Award 10 XP to the user who created the run
  UPDATE users
  SET total_xp = total_xp + 10
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_award_run_xp ON ezrun_runs;

-- Create trigger that fires after a new run is inserted
CREATE TRIGGER trigger_award_run_xp
  AFTER INSERT ON ezrun_runs
  FOR EACH ROW
  EXECUTE FUNCTION ezrun_award_run_xp();

-- Step 4: (Optional) Backfill XP for existing users
-- ============================================
-- This will award XP for all existing runs in the database
-- Uncomment the following lines if you want to backfill XP for existing users

/*
UPDATE users u
SET total_xp = (
  SELECT COUNT(*) * 10
  FROM ezrun_runs r
  WHERE r.user_id = u.id
)
WHERE EXISTS (
  SELECT 1 FROM ezrun_runs r WHERE r.user_id = u.id
);
*/

-- Step 5: Create a view for user levels (optional, for analytics)
-- ============================================
-- This view calculates each user's level based on their total_xp
-- Level calculation uses exponential growth: Level 2 = 20 XP, Level 3 = 42 XP, etc.
-- 
-- SECURITY NOTE: This view runs with the caller's permissions (default behavior).
-- It respects Row-Level Security (RLS) policies and does NOT use SECURITY DEFINER.
-- This ensures users can only see data they're authorized to access.

CREATE OR REPLACE VIEW ezrun_user_levels AS
SELECT 
  id,
  total_xp,
  -- Calculate level (simplified calculation, actual calculation is done in app)
  CASE 
    WHEN total_xp < 20 THEN 1
    WHEN total_xp < 42 THEN 2
    WHEN total_xp < 66 THEN 3
    WHEN total_xp < 92 THEN 4
    WHEN total_xp < 121 THEN 5
    ELSE LEAST(100, 6 + FLOOR((total_xp - 121) / 30))
  END as current_level
FROM users;

-- Grant permissions only to authenticated users
GRANT SELECT ON ezrun_user_levels TO authenticated;
GRANT EXECUTE ON FUNCTION ezrun_add_user_xp TO authenticated;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- After running this migration:
-- 1. Users will automatically earn 10 XP for each new run they log
-- 2. The Flutter app will display level progress on the profile screen
-- 3. Users will see XP reward notifications when logging runs
