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

struct UserProfile {
    let id: UUID
    var name: String
    var age: Int
    var weight: Double // kg
    var height: Double // cm
    var gender: Gender
    var activityLevel: ActivityLevel
    var dailyCalorieGoal: Int
    
    enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
    }
    
    enum ActivityLevel: String, CaseIterable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case extraActive = "Extra Active"
    }
}