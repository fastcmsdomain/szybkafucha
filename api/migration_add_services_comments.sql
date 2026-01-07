-- Migration: Add services and comments columns to newsletter_subscribers table
-- Date: 2026-01-06
-- Description: Adds support for collecting user service preferences and feedback comments

-- Add services column (JSON to store array of selected services)
ALTER TABLE newsletter_subscribers 
ADD COLUMN services TEXT NULL COMMENT 'JSON array of selected services (e.g. ["cleaning", "shopping"])';

-- Add comments column (TEXT to store user feedback/suggestions)
ALTER TABLE newsletter_subscribers 
ADD COLUMN comments TEXT NULL COMMENT 'User feedback and suggestions for app improvements (max 500 chars)';

-- Optional: Add index for better query performance if needed
-- CREATE INDEX idx_newsletter_services ON newsletter_subscribers(services(255));