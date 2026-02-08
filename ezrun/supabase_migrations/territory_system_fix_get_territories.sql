-- Migration: Fix ezrun_get_territories() user name column
--
-- The initial migration referenced `users.username`, but our `users` table uses
-- `name`. This breaks territory loading on the map.

CREATE OR REPLACE FUNCTION ezrun_get_territories()
RETURNS TABLE (
  id UUID,
  user_id UUID,
  username TEXT,
  profile_color VARCHAR(7),
  polygon_geojson JSONB,
  area_sq_meters DOUBLE PRECISION,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.user_id,
    u.name as username,
    COALESCE(u.profile_color, '#00D4FF') as profile_color,
    ST_AsGeoJSON(t.polygon)::jsonb as polygon_geojson,
    t.area_sq_meters,
    t.created_at
  FROM ezrun_territories t
  LEFT JOIN users u ON u.id = t.user_id
  ORDER BY t.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure PostgREST roles can execute the RPC.
GRANT EXECUTE ON FUNCTION ezrun_get_territories() TO anon, authenticated;


