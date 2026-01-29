-- Migration: Add services, comments, and city columns to newsletter_subscribers table
-- Date: 2026-01-06
-- Updated: 2026-01-08
-- Description: Adds support for collecting user service preferences, feedback comments, and city

-- Add city column (VARCHAR to store selected city)
ALTER TABLE newsletter_subscribers
ADD COLUMN city VARCHAR(100) NULL COMMENT 'User selected city (e.g. "Warszawa", "Kraków")';

-- Add services column (JSON to store array of selected services)
ALTER TABLE newsletter_subscribers
ADD COLUMN services TEXT NULL COMMENT 'JSON array of selected services (e.g. ["cleaning", "shopping"])';

-- Add comments column (TEXT to store user feedback/suggestions)
ALTER TABLE newsletter_subscribers
ADD COLUMN comments TEXT NULL COMMENT 'User feedback and suggestions for app improvements (max 500 chars)';

-- Optional: Add index for better query performance if needed
-- CREATE INDEX idx_newsletter_city ON newsletter_subscribers(city);
-- CREATE INDEX idx_newsletter_services ON newsletter_subscribers(services(255));