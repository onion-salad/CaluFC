import Foundation
import UIKit

struct Meal: Identifiable {
    let id: UUID
    let name: String
    let calories: Int
    let time: Date
    let image: UIImage?
    let nutrients: NutrientsRecord?
    
    init(id: UUID = UUID(), name: String, calories: Int, time: Date, image: UIImage? = nil, nutrients: NutrientsRecord? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.time = time
        self.image = image
        self.nutrients = nutrients
    }
}

struct Nutrients {
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let cholesterol: Double
    let saturatedFat: Double
    let transFat: Double
    let vitaminA: Double
    let vitaminC: Double
    let calcium: Double
    let iron: Double
    
    static var empty: Nutrients {
        Nutrients(
            calories: 0,
            protein: 0,
            carbohydrates: 0,
            fat: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            cholesterol: 0,
            saturatedFat: 0,
            transFat: 0,
            vitaminA: 0,
            vitaminC: 0,
            calcium: 0,
            iron: 0
        )
    }
}

struct UserProfile: Equatable {
    let id: UUID
    var name: String
    var age: Int
    var weight: Double // kg
    var height: Double // cm
    var gender: String // "男性" or "女性"
    var activityLevel: String // "low", "moderate", "high"
    var dailyCalorieGoal: Int
    
    // デフォルト値を提供するイニシャライザ
    init(name: String = "", age: Int = 25, gender: String = "男性", weight: Double = 60, height: Double = 165, activityLevel: String = "moderate", dailyCalorieGoal: Int = 2000) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.gender = gender
        self.weight = weight
        self.height = height
        self.activityLevel = activityLevel
        self.dailyCalorieGoal = dailyCalorieGoal
    }
    
    enum Gender: String, CaseIterable {
        case male = "男性"
        case female = "女性"
        
        var english: String {
            switch self {
            case .male: return "male"
            case .female: return "female"
            }
        }
    }
    
    enum ActivityLevel: String, CaseIterable {
        case low = "低い（座位中心）"
        case moderate = "普通（軽い運動あり）"
        case high = "高い（活発な運動）"
        
        var key: String {
            switch self {
            case .low: return "low"
            case .moderate: return "moderate"
            case .high: return "high"
            }
        }
    }
}