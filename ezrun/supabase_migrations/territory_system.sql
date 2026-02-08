-- Migration: Territory Capture System with PostGIS
-- Enables geo-spatial queries for territory polygons

-- Enable PostGIS extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- Add profile_color to users table for user-selected territory color
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS profile_color VARCHAR(7) DEFAULT '#00D4FF';

-- Create territories table
CREATE TABLE IF NOT EXISTS ezrun_territories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  run_id UUID REFERENCES ezrun_runs(id) ON DELETE SET NULL,
  
  -- Polygon stored as PostGIS geometry (SRID 4326 = WGS84)
  polygon GEOMETRY(POLYGON, 4326) NOT NULL,
  
  -- Cached area in square meters for quick display
  area_sq_meters DOUBLE PRECISION NOT NULL DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_territories_user ON ezrun_territories(user_id);
CREATE INDEX IF NOT EXISTS idx_territories_geo ON ezrun_territories USING GIST(polygon);
CREATE INDEX IF NOT EXISTS idx_territories_created ON ezrun_territories(created_at DESC);

-- Enable RLS
ALTER TABLE ezrun_territories ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Anyone can read, only owner can insert (stealing handled by function)
CREATE POLICY "territories_read_all" ON ezrun_territories
  FOR SELECT USING (true);

CREATE POLICY "territories_insert_own" ON ezrun_territories
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "territories_delete_own" ON ezrun_territories
  FOR DELETE USING (auth.uid() = user_id);

-- Function to claim territory (handles stealing/overlapping)
CREATE OR REPLACE FUNCTION ezrun_claim_territory(
  p_user_id UUID,
  p_run_id UUID,
  p_polygon_points JSONB
) RETURNS UUID AS $$
DECLARE
  v_territory_id UUID;
  v_polygon GEOMETRY;
  v_area DOUBLE PRECISION;
BEGIN
  -- Convert JSONB points to PostGIS polygon
  -- Points format: [{"lat": 12.34, "lng": 56.78}, ...]
  SELECT ST_MakePolygon(
    ST_MakeLine(
      ARRAY(
        SELECT ST_SetSRID(ST_MakePoint(
          (point->>'lng')::DOUBLE PRECISION,
          (point->>'lat')::DOUBLE PRECISION
        ), 4326)
        FROM jsonb_array_elements(p_polygon_points) AS point
      )
    )
  ) INTO v_polygon;
  
  -- Calculate area in square meters
  SELECT ST_Area(v_polygon::geography) INTO v_area;
  
  -- Check minimum area (200 sq meters)
  IF v_area < 200 THEN
    RAISE EXCEPTION 'Territory too small. Minimum area is 200 square meters.';
  END IF;
  
  -- Delete any existing territories that overlap with new polygon (stealing)
  DELETE FROM ezrun_territories
  WHERE ST_Intersects(polygon, v_polygon)
    AND user_id != p_user_id;
  
  -- Insert new territory
  INSERT INTO ezrun_territories (user_id, run_id, polygon, area_sq_meters)
  VALUES (p_user_id, p_run_id, v_polygon, v_area)
  RETURNING id INTO v_territory_id;
  
  RETURN v_territory_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all territories with user info (for map display)
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
    u.username,
    COALESCE(u.profile_color, '#00D4FF') as profile_color,
    ST_AsGeoJSON(t.polygon)::jsonb as polygon_geojson,
    t.area_sq_meters,
    t.created_at
  FROM ezrun_territories t
  LEFT JOIN users u ON u.id = t.user_id
  ORDER BY t.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

