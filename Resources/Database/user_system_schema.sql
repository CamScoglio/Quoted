-- User System Database Schema for Supabase
-- This file contains all the SQL needed to set up the user-centric quote system

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables if they exist (for development)
DROP TABLE IF EXISTS user_daily_quotes CASCADE;
DROP TABLE IF EXISTS quote_analytics CASCADE;
DROP TABLE IF EXISTS app_analytics CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE,
    anonymous_id TEXT UNIQUE, -- For anonymous users
    display_name TEXT,
    avatar_url TEXT,
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'pro')),
    preferences JSONB DEFAULT '{
        "notificationTime": null,
        "preferredCategories": [],
        "favoriteAuthors": [],
        "themePreference": "system",
        "readingStreak": {
            "currentStreak": 0,
            "longestStreak": 0,
            "lastReadDate": null
        },
        "privacySettings": {
            "shareReadingStats": false,
            "allowAnalytics": true,
            "emailNotifications": true
        }
    }',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_daily_quotes table (replaces user_sessions)
CREATE TABLE user_daily_quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    quote_id UUID REFERENCES quotes(id),
    assigned_date DATE DEFAULT CURRENT_DATE,
    viewed_at TIMESTAMP WITH TIME ZONE,
    favorited BOOLEAN DEFAULT false,
    shared BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one quote per user per day
    UNIQUE(user_id, assigned_date)
);

-- Create quote_analytics table
CREATE TABLE quote_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    quote_id UUID REFERENCES quotes(id),
    action TEXT NOT NULL CHECK (action IN ('viewed', 'favorited', 'shared')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- Create app_analytics table
CREATE TABLE app_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event TEXT NOT NULL CHECK (event IN ('app_opened', 'widget_interaction')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_anonymous_id ON users(anonymous_id);
CREATE INDEX idx_user_daily_quotes_user_id ON user_daily_quotes(user_id);
CREATE INDEX idx_user_daily_quotes_date ON user_daily_quotes(assigned_date);
CREATE INDEX idx_user_daily_quotes_user_date ON user_daily_quotes(user_id, assigned_date);
CREATE INDEX idx_quote_analytics_user_id ON quote_analytics(user_id);
CREATE INDEX idx_quote_analytics_timestamp ON quote_analytics(timestamp);
CREATE INDEX idx_quote_analytics_action ON quote_analytics(action);
CREATE INDEX idx_app_analytics_user_id ON app_analytics(user_id);
CREATE INDEX idx_app_analytics_timestamp ON app_analytics(timestamp);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_daily_quotes_updated_at BEFORE UPDATE ON user_daily_quotes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_daily_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_analytics ENABLE ROW LEVEL SECURITY;

-- Users can only see and modify their own data
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id OR anonymous_id IS NOT NULL);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id OR anonymous_id IS NOT NULL);

-- User daily quotes policies
CREATE POLICY "Users can view own daily quotes" ON user_daily_quotes FOR SELECT USING (
    user_id IN (SELECT id FROM users WHERE auth.uid() = id OR anonymous_id IS NOT NULL)
);
CREATE POLICY "Users can insert own daily quotes" ON user_daily_quotes FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM users WHERE auth.uid() = id OR anonymous_id IS NOT NULL)
);
CREATE POLICY "Users can update own daily quotes" ON user_daily_quotes FOR UPDATE USING (
    user_id IN (SELECT id FROM users WHERE auth.uid() = id OR anonymous_id IS NOT NULL)
);

-- Analytics policies (users can only insert their own analytics)
CREATE POLICY "Users can insert own quote analytics" ON quote_analytics FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM users WHERE auth.uid() = id OR anonymous_id IS NOT NULL)
);
CREATE POLICY "Users can view own quote analytics" ON quote_analytics FOR SELECT USING (
    user_id IN (SELECT id FROM users WHERE auth.uid() = id OR anonymous_id IS NOT NULL)
);

CREATE POLICY "Users can insert own app analytics" ON app_analytics FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM users WHERE auth.uid() = id OR anonymous_id IS NOT NULL)
);
CREATE POLICY "Users can view own app analytics" ON app_analytics FOR SELECT USING (
    user_id IN (SELECT id FROM users WHERE auth.uid() = id OR anonymous_id IS NOT NULL)
);

-- Useful functions for the app

-- Function to get or create today's quote for a user
CREATE OR REPLACE FUNCTION get_or_assign_daily_quote(p_user_id UUID)
RETURNS TABLE (
    quote_id UUID,
    quote_text TEXT,
    author_name TEXT,
    author_bio TEXT,
    category_name TEXT,
    category_description TEXT,
    assigned_date DATE,
    viewed_at TIMESTAMP WITH TIME ZONE,
    favorited BOOLEAN
) AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
    existing_quote_id UUID;
    random_quote_id UUID;
BEGIN
    -- Check if user already has a quote for today
    SELECT udq.quote_id INTO existing_quote_id
    FROM user_daily_quotes udq
    WHERE udq.user_id = p_user_id AND udq.assigned_date = today_date;
    
    -- If no quote for today, assign a random one
    IF existing_quote_id IS NULL THEN
        -- Get a random quote that the user hasn't seen recently (last 30 days)
        SELECT q.id INTO random_quote_id
        FROM quotes q
        WHERE q.id NOT IN (
            SELECT udq.quote_id 
            FROM user_daily_quotes udq 
            WHERE udq.user_id = p_user_id 
            AND udq.assigned_date > (CURRENT_DATE - INTERVAL '30 days')
        )
        ORDER BY RANDOM()
        LIMIT 1;
        
        -- If all quotes have been seen recently, just pick any random quote
        IF random_quote_id IS NULL THEN
            SELECT q.id INTO random_quote_id
            FROM quotes q
            ORDER BY RANDOM()
            LIMIT 1;
        END IF;
        
        -- Insert the new daily quote assignment
        INSERT INTO user_daily_quotes (user_id, quote_id, assigned_date)
        VALUES (p_user_id, random_quote_id, today_date);
        
        existing_quote_id := random_quote_id;
    END IF;
    
    -- Return the quote details
    RETURN QUERY
    SELECT 
        q.id,
        q.text,
        a.name,
        a.bio,
        c.name,
        c.description,
        udq.assigned_date,
        udq.viewed_at,
        udq.favorited
    FROM quotes q
    JOIN authors a ON q.author_id = a.id
    JOIN categories c ON q.category_id = c.id
    JOIN user_daily_quotes udq ON q.id = udq.quote_id
    WHERE q.id = existing_quote_id 
    AND udq.user_id = p_user_id 
    AND udq.assigned_date = today_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark a quote as viewed
CREATE OR REPLACE FUNCTION mark_quote_viewed(p_user_id UUID, p_quote_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE user_daily_quotes
    SET viewed_at = NOW()
    WHERE user_id = p_user_id 
    AND quote_id = p_quote_id 
    AND assigned_date = CURRENT_DATE
    AND viewed_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to toggle quote favorite status
CREATE OR REPLACE FUNCTION toggle_quote_favorite(p_user_id UUID, p_quote_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    new_favorite_status BOOLEAN;
BEGIN
    UPDATE user_daily_quotes
    SET favorited = NOT favorited
    WHERE user_id = p_user_id 
    AND quote_id = p_quote_id 
    AND assigned_date = CURRENT_DATE
    RETURNING favorited INTO new_favorite_status;
    
    RETURN new_favorite_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 