-- Migration: Fix ezrun_get_territories() run_distance_km type mismatch
--
-- PostgREST validates the returned SELECT types against the declared RETURNS TABLE types.
-- If ezrun_runs.distance_km is NUMERIC, we must cast it to DOUBLE PRECISION to match
-- the function signature (run_distance_km DOUBLE PRECISION).

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
    u.name::TEXT as username,
    COALESCE(u.profile_color, '#00D4FF')::VARCHAR(7) as profile_color,
    u.profile_pic::TEXT as profile_pic,
    ST_AsGeoJSON(t.polygon)::jsonb as polygon_geojson,
    t.area_sq_meters::DOUBLE PRECISION,
    t.created_at,
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

GRANT EXECUTE ON FUNCTION ezrun_get_territories() TO anon, authenticated;


