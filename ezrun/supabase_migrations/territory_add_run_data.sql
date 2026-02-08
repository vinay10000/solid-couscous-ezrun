-- This migration updates the territory query function to include
-- run data (distance, duration, pace) from the associated run.

-- Force drop the function to avoid return type conflicts
DROP FUNCTION IF EXISTS ezrun_get_territories() CASCADE;

CREATE OR REPLACE FUNCTION ezrun_get_territories()
RETURNS TABLE (
  id UUID,
  user_id UUID,
  username TEXT,
  profile_color VARCHAR(7),
  profile_pic TEXT,
  polygon_geojson JSONB,
  area_sq_meters DOUBLE PRECISION,
  created_at TIMESTAMPTZ,
  -- New run data fields
  run_distance_km DOUBLE PRECISION,
  run_duration_seconds INTEGER,
  run_avg_pace_sec_per_km INTEGER,
  run_note TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.user_id,
    u.name as username,
    COALESCE(u.profile_color, '#00D4FF') as profile_color,
    u.profile_pic::TEXT as profile_pic,
    ST_AsGeoJSON(t.polygon)::jsonb as polygon_geojson,
    t.area_sq_meters,
    t.created_at,
    -- Run data from associated run
    r.distance_km::DOUBLE PRECISION as run_distance_km,
    r.duration_seconds::INTEGER as run_duration_seconds,
    r.avg_pace_sec_per_km::INTEGER as run_avg_pace_sec_per_km,
    r.note::TEXT as run_note
  FROM ezrun_territories t
  LEFT JOIN users u ON u.id = t.user_id
  LEFT JOIN ezrun_runs r ON r.id = t.run_id
  ORDER BY t.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure PostgREST roles can execute the RPC.
GRANT EXECUTE ON FUNCTION ezrun_get_territories() TO anon, authenticated;

