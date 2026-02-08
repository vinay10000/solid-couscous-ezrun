-- Migration: Add route_coordinates to ezrun_runs
-- This column stores the GPS polyline as a JSONB array of {lat, lng} objects

ALTER TABLE ezrun_runs 
ADD COLUMN IF NOT EXISTS route_coordinates JSONB DEFAULT '[]'::jsonb;

-- Add comment for documentation
COMMENT ON COLUMN ezrun_runs.route_coordinates IS 'GPS route polyline stored as array of {lat, lng} coordinate objects';
