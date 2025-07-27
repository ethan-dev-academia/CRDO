# CRDO - Build Your City, Build Yourself

A fitness app that gamifies your workout routine by building a virtual city as you exercise. Every workout session contributes to your city's growth, making fitness fun and rewarding.

## Features

- 🏙️ **City Building**: Watch your virtual city grow with every workout
- 🔥 **Streak Tracking**: Build and maintain workout streaks
- 📊 **Progress Analytics**: Track your fitness journey with detailed statistics
- 🔐 **Secure Authentication**: Sign in with email/password
- 📱 **Real-time Updates**: Live progress updates and city building
- 🎯 **Gamified Experience**: Unlock buildings and progress through levels

## Tech Stack

- **Frontend**: SwiftUI (iOS)
- **Backend**: Supabase
- **Authentication**: Supabase Auth
- **Database**: PostgreSQL (via Supabase)
- **Real-time**: Supabase Realtime

## Setup Instructions

### 1. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key from the project settings
3. Update `CRDO/Config.swift` with your credentials:

```swift
static let supabaseURL = "https://your-project.supabase.co"
static let supabaseAnonKey = "your-anon-key"
```

### 2. Database Schema

Run the following SQL in your Supabase SQL editor:

```sql
-- Enable Row Level Security
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Create user_profiles table
CREATE TABLE user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT,
    email TEXT,
    fitness_level TEXT,
    goals TEXT[],
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_workouts INTEGER DEFAULT 0,
    onboarding_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create workout_sessions table
CREATE TABLE workout_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    duration INTEGER NOT NULL,
    calories_burned INTEGER,
    workout_type TEXT NOT NULL,
    city_progress_earned INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create city_progress table
CREATE TABLE city_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    total_progress INTEGER DEFAULT 0,
    buildings_unlocked INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    city_data JSONB,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE city_progress ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own workout sessions" ON workout_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workout sessions" ON workout_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own city progress" ON city_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own city progress" ON city_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own city progress" ON city_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_created_at ON workout_sessions(created_at DESC);
CREATE INDEX idx_city_progress_user_id ON city_progress(user_id);
```



### 3. Xcode Setup

1. Open the project in Xcode
2. Add the following dependency via Swift Package Manager:
   - `https://github.com/supabase/supabase-swift.git`

### 4. Supabase Authentication Setup

1. In your Supabase dashboard, go to Authentication > Settings
2. Email authentication is enabled by default
3. You can customize email templates and settings as needed

## Project Structure

```
CRDO/
├── CRDOApp.swift              # Main app entry point
├── ContentView.swift          # Main content view with onboarding
├── AuthenticationView.swift   # Sign in/up interface
├── MainAppView.swift          # Main app interface after auth
├── SupabaseManager.swift      # Supabase client and operations
├── Config.swift              # Configuration constants
└── Assets.xcassets/          # App assets
```

## Key Features Implementation

### Authentication Flow
- Users can sign up/sign in with email/password
- Automatic user profile creation
- Session persistence

### Onboarding
- Multi-step onboarding process
- User preference collection
- Progress tracking through panels

### Main App Features
- **City View**: Visual representation of user's progress
- **Workout View**: Timer and workout tracking
- **Progress View**: Statistics and workout history
- **Profile View**: User settings and account management

### Real-time Features
- Live city progress updates
- Streak tracking
- Workout session recording

## Usage

1. **First Launch**: Users see the onboarding flow
2. **Authentication**: Users can sign in with email/password
3. **Onboarding**: New users complete the onboarding process
4. **Main App**: Users access city building, workouts, and progress tracking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@crdo.app or create an issue in this repository. 