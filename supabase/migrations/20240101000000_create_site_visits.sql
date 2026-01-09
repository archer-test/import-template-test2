-- Create the site_visits table for tracking global visit count
CREATE TABLE IF NOT EXISTS site_visits (
  id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  visit_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Insert initial row with visit_count of 0
INSERT INTO site_visits (id, visit_count) VALUES (1, 0)
ON CONFLICT (id) DO NOTHING;

-- Create function to increment visit count atomically
CREATE OR REPLACE FUNCTION increment_visit_count()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  new_count INTEGER;
BEGIN
  UPDATE site_visits
  SET visit_count = visit_count + 1,
      updated_at = TIMEZONE('utc', NOW())
  WHERE id = 1
  RETURNING visit_count INTO new_count;

  RETURN new_count;
END;
$$;

-- Enable Row Level Security
ALTER TABLE site_visits ENABLE ROW LEVEL SECURITY;

-- Create policy to allow anonymous reads
CREATE POLICY "Allow anonymous read access" ON site_visits
  FOR SELECT
  TO anon
  USING (true);

-- Create policy to allow anonymous updates (for incrementing counter)
CREATE POLICY "Allow anonymous update access" ON site_visits
  FOR UPDATE
  TO anon
  USING (true);
