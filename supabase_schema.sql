-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    age INTEGER NOT NULL CHECK (age > 0 AND age < 150),
    weight DECIMAL(5,2) NOT NULL CHECK (weight > 0),
    height DECIMAL(5,2) NOT NULL CHECK (height > 0),
    gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    activity_level TEXT NOT NULL CHECK (activity_level IN ('Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active')),
    daily_calorie_goal INTEGER NOT NULL CHECK (daily_calorie_goal > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create nutrients type
CREATE TYPE nutrients AS (
    calories DECIMAL(10,2),
    protein DECIMAL(10,2),
    fat DECIMAL(10,2),
    carbohydrates DECIMAL(10,2),
    calcium DECIMAL(10,2),
    iron DECIMAL(10,2),
    vitamin_a DECIMAL(10,2),
    vitamin_b1 DECIMAL(10,2),
    vitamin_b2 DECIMAL(10,2),
    vitamin_c DECIMAL(10,2),
    vitamin_d DECIMAL(10,2),
    vitamin_e DECIMAL(10,2),
    fiber DECIMAL(10,2),
    sugar DECIMAL(10,2),
    sodium DECIMAL(10,2),
    cholesterol DECIMAL(10,2),
    saturated_fat DECIMAL(10,2),
    trans_fat DECIMAL(10,2)
);

-- Create meals table
CREATE TABLE IF NOT EXISTS meals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    calories INTEGER NOT NULL CHECK (calories >= 0),
    image_url TEXT,
    nutrients JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_meals_user_id ON meals(user_id);
CREATE INDEX idx_meals_created_at ON meals(created_at);
CREATE INDEX idx_meals_user_date ON meals(user_id, created_at);

-- Create RLS policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Meals policies
CREATE POLICY "Users can view own meals" ON meals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own meals" ON meals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own meals" ON meals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own meals" ON meals
    FOR DELETE USING (auth.uid() = user_id);

-- Create functions for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meals_updated_at BEFORE UPDATE ON meals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create view for daily statistics
CREATE VIEW daily_nutrition_stats AS
SELECT 
    user_id,
    DATE(created_at) as date,
    COUNT(*) as meal_count,
    SUM(calories) as total_calories,
    SUM((nutrients->>'protein')::DECIMAL) as total_protein,
    SUM((nutrients->>'fat')::DECIMAL) as total_fat,
    SUM((nutrients->>'carbohydrates')::DECIMAL) as total_carbohydrates,
    SUM((nutrients->>'calcium')::DECIMAL) as total_calcium,
    SUM((nutrients->>'iron')::DECIMAL) as total_iron,
    SUM((nutrients->>'vitamin_a')::DECIMAL) as total_vitamin_a,
    SUM((nutrients->>'vitamin_b1')::DECIMAL) as total_vitamin_b1,
    SUM((nutrients->>'vitamin_b2')::DECIMAL) as total_vitamin_b2,
    SUM((nutrients->>'vitamin_c')::DECIMAL) as total_vitamin_c,
    SUM((nutrients->>'vitamin_d')::DECIMAL) as total_vitamin_d,
    SUM((nutrients->>'vitamin_e')::DECIMAL) as total_vitamin_e,
    SUM((nutrients->>'fiber')::DECIMAL) as total_fiber,
    SUM((nutrients->>'sugar')::DECIMAL) as total_sugar,
    SUM((nutrients->>'sodium')::DECIMAL) as total_sodium
FROM meals
GROUP BY user_id, DATE(created_at);

-- Grant permissions on the view
GRANT SELECT ON daily_nutrition_stats TO authenticated;