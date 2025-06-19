# Calu - Minimal Calorie Tracking App

A sleek, minimal calorie tracking iOS app with AI-powered food analysis and comprehensive nutrient tracking.

## Features

- **AI Food Analysis**: Take a photo of your food and get instant nutritional information
- **12 Nutrient Tracking**: Track calories, protein, carbs, fats, fiber, sugar, sodium, cholesterol, saturated fat, trans fat, vitamin A, vitamin C, calcium, and iron
- **Minimal Design**: Clean, modern UI with intuitive navigation
- **Supabase Integration**: Cloud-based data storage for meal history
- **Progress Tracking**: Visual charts and statistics for your nutrition goals
- **Personalized Goals**: Set custom calorie and nutrient goals based on your profile

## Setup

1. **Supabase Configuration**:
   - Create a Supabase project at [supabase.com](https://supabase.com)
   - Run the SQL schema from `supabase_schema.sql` in your Supabase SQL editor
   - Copy your project URL and anon key

2. **API Keys**:
   - Update `SupabaseManager.swift` with your Supabase credentials
   - Add your OpenAI API key to `FoodAnalysisService.swift`

3. **Install Dependencies**:
   - Open the project in Xcode
   - Add the Supabase Swift package: `https://github.com/supabase/supabase-swift.git`

4. **Build and Run**:
   ```bash
   xcodebuild -project "CaluFC.xcodeproj" -scheme "CaluFC" -configuration Debug build
   ```

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **Supabase**: Backend-as-a-Service for data storage
- **OpenAI Vision API**: AI-powered food recognition and analysis
- **Charts**: Native SwiftUI charts for data visualization

## Usage

1. **Add Meals**: Tap the camera button to photograph your food
2. **View Analysis**: Get instant nutritional breakdown of 12 key nutrients
3. **Track Progress**: Monitor daily calorie intake and nutrient distribution
4. **History**: Review past meals and weekly/monthly trends
5. **Profile**: Customize your nutrition goals and preferences