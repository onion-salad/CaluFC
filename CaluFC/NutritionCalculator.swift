import Foundation

// 日本人の食事摂取基準（DRIs）2020年版に基づく栄養素計算
struct NutritionCalculator {
    
    // MARK: - Age Groups
    enum AgeGroup {
        case age18_29
        case age30_49
        case age50_64
        case age65_74
        case age75Plus
        
        static func fromAge(_ age: Int) -> AgeGroup {
            switch age {
            case 18...29: return .age18_29
            case 30...49: return .age30_49
            case 50...64: return .age50_64
            case 65...74: return .age65_74
            default: return .age75Plus
            }
        }
    }
    
    // MARK: - Activity Level
    enum ActivityLevel: String, CaseIterable {
        case low = "low"        // 低い（座位中心）
        case moderate = "moderate" // 普通（座位中心＋軽い運動）
        case high = "high"      // 高い（移動や立位多い、活発な運動）
        
        var multiplier: Double {
            switch self {
            case .low: return 1.50
            case .moderate: return 1.75
            case .high: return 2.00
            }
        }
    }
    
    // MARK: - Daily Nutrition Limits
    struct DailyNutritionLimits {
        let calories: Double        // kcal
        let protein: Double         // g (15-20% of calories)
        let fat: Double            // g (20-30% of calories)  
        let carbohydrates: Double  // g (50-65% of calories)
        let sodium: Double         // mg (上限値)
        let fiber: Double          // g (目標量)
        let calcium: Double        // mg (推奨量)
        let iron: Double           // mg (推奨量)
        let vitaminA: Double       // μg (推奨量)
        let vitaminB1: Double      // mg (推奨量)
        let vitaminB2: Double      // mg (推奨量)
        let vitaminC: Double       // mg (推奨量)
        let vitaminD: Double       // μg (目安量)
        let vitaminE: Double       // mg (目安量)
        let cholesterol: Double    // mg (上限値なし、200mg未満推奨)
        let saturatedFat: Double   // g (総脂質の7%以下)
        let sugar: Double          // g (WHO推奨: 総エネルギーの10%未満)
        
        // 上限値を超えているかのチェック
        func isExceeding(nutrients: NutrientsRecord) -> [String: Bool] {
            var exceeding: [String: Bool] = [:]
            
            exceeding["calories"] = nutrients.calories > calories
            exceeding["protein"] = nutrients.protein > protein
            exceeding["fat"] = nutrients.fat > fat
            exceeding["carbohydrates"] = nutrients.carbohydrates > carbohydrates
            exceeding["sodium"] = (nutrients.sodium ?? 0) > sodium
            exceeding["fiber"] = (nutrients.fiber ?? 0) < fiber // 不足チェック
            exceeding["calcium"] = (nutrients.calcium ?? 0) < calcium // 不足チェック
            exceeding["iron"] = (nutrients.iron ?? 0) < iron // 不足チェック
            exceeding["vitaminA"] = (nutrients.vitaminA ?? 0) < vitaminA // 不足チェック
            exceeding["vitaminC"] = (nutrients.vitaminC ?? 0) < vitaminC // 不足チェック
            exceeding["cholesterol"] = (nutrients.cholesterol ?? 0) > cholesterol
            exceeding["saturatedFat"] = (nutrients.saturatedFat ?? 0) > saturatedFat
            
            return exceeding
        }
    }
    
    // MARK: - BMR Calculation (Harris-Benedict Formula)
    static func calculateBMR(age: Int, gender: String, weight: Double, height: Double) -> Double {
        if gender.lowercased() == "male" || gender == "男性" {
            return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
    }
    
    // MARK: - Daily Calorie Needs
    static func calculateDailyCalories(age: Int, gender: String, weight: Double, height: Double, activityLevel: ActivityLevel) -> Double {
        let bmr = calculateBMR(age: age, gender: gender, weight: weight, height: height)
        return bmr * activityLevel.multiplier
    }
    
    // MARK: - Calculate Daily Nutrition Limits
    static func calculateDailyLimits(age: Int, gender: String, weight: Double, height: Double, activityLevel: ActivityLevel) -> DailyNutritionLimits {
        
        let ageGroup = AgeGroup.fromAge(age)
        let isMale = gender.lowercased() == "male" || gender == "男性"
        let dailyCalories = calculateDailyCalories(age: age, gender: gender, weight: weight, height: height, activityLevel: activityLevel)
        
        // マクロ栄養素の計算（カロリーベース）
        let proteinCalories = dailyCalories * 0.175 // 15-20%の中央値17.5%
        let fatCalories = dailyCalories * 0.25     // 20-30%の中央値25%
        let carbCalories = dailyCalories * 0.575   // 50-65%の中央値57.5%
        
        let protein = proteinCalories / 4.0        // 1g = 4kcal
        let fat = fatCalories / 9.0               // 1g = 9kcal
        let carbohydrates = carbCalories / 4.0    // 1g = 4kcal
        
        // 年齢・性別別の推奨値（DRIs 2020年版）
        let sodium: Double
        let fiber: Double
        let calcium: Double
        let iron: Double
        let vitaminA: Double
        let vitaminB1: Double
        let vitaminB2: Double
        let vitaminC: Double
        let vitaminD: Double = 15.0 // 全年齢共通
        let vitaminE: Double
        
        if isMale {
            // 男性の値
            sodium = 7500.0 // 7.5g未満（上限値）
            
            switch ageGroup {
            case .age18_29, .age30_49:
                fiber = 21.0
                calcium = 800.0
                iron = 7.5
                vitaminA = 900.0
                vitaminB1 = 1.4
                vitaminB2 = 1.6
                vitaminC = 100.0
                vitaminE = 6.0
            case .age50_64:
                fiber = 21.0
                calcium = 800.0
                iron = 7.5
                vitaminA = 900.0
                vitaminB1 = 1.3
                vitaminB2 = 1.5
                vitaminC = 100.0
                vitaminE = 6.0
            case .age65_74, .age75Plus:
                fiber = 20.0
                calcium = 800.0
                iron = 7.0
                vitaminA = 850.0
                vitaminB1 = 1.2
                vitaminB2 = 1.3
                vitaminC = 100.0
                vitaminE = 6.0
            }
        } else {
            // 女性の値
            sodium = 6500.0 // 6.5g未満（上限値）
            
            switch ageGroup {
            case .age18_29, .age30_49:
                fiber = 18.0
                calcium = 650.0
                iron = 10.5 // 月経あり
                vitaminA = 700.0
                vitaminB1 = 1.1
                vitaminB2 = 1.2
                vitaminC = 100.0
                vitaminE = 5.0
            case .age50_64:
                fiber = 18.0
                calcium = 650.0
                iron = 6.5 // 月経なし
                vitaminA = 700.0
                vitaminB1 = 1.1
                vitaminB2 = 1.2
                vitaminC = 100.0
                vitaminE = 5.0
            case .age65_74, .age75Plus:
                fiber = 17.0
                calcium = 650.0
                iron = 6.0
                vitaminA = 700.0
                vitaminB1 = 1.0
                vitaminB2 = 1.1
                vitaminC = 100.0
                vitaminE = 5.0
            }
        }
        
        // 飽和脂肪酸は総脂質の7%以下
        let saturatedFat = fat * 0.07
        
        // 糖質はWHO推奨：総エネルギーの10%未満
        let sugar = (dailyCalories * 0.10) / 4.0 // 1g = 4kcal
        
        return DailyNutritionLimits(
            calories: dailyCalories,
            protein: protein,
            fat: fat,
            carbohydrates: carbohydrates,
            sodium: sodium,
            fiber: fiber,
            calcium: calcium,
            iron: iron,
            vitaminA: vitaminA,
            vitaminB1: vitaminB1,
            vitaminB2: vitaminB2,
            vitaminC: vitaminC,
            vitaminD: vitaminD,
            vitaminE: vitaminE,
            cholesterol: 200.0, // 200mg未満推奨
            saturatedFat: saturatedFat,
            sugar: sugar
        )
    }
    
    // MARK: - Calculate Achievement Percentage
    static func calculateAchievementPercentage(_ current: Double, _ target: Double) -> Double {
        guard target > 0 else { return 0 }
        return min((current / target) * 100, 200) // 最大200%まで表示
    }
    
    // MARK: - Get Status Color
    static func getStatusColor(current: Double, target: Double, isUpperLimit: Bool = false) -> String {
        let percentage = (current / target) * 100
        
        if isUpperLimit {
            // 上限値の場合（ナトリウム、コレステロールなど）
            if percentage <= 80 { return "green" }
            else if percentage <= 100 { return "yellow" }
            else { return "red" }
        } else {
            // 推奨値の場合（その他のビタミン・ミネラル）
            if percentage >= 80 { return "green" }
            else if percentage >= 60 { return "yellow" }
            else { return "red" }
        }
    }
}