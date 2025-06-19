import Foundation
import UIKit
import Vision
import CoreML

class FoodAnalysisService: ObservableObject {
    static let shared = FoodAnalysisService()
    
    private let openAIKey = "YOUR_OPENAI_API_KEY"
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    func analyzeFood(from image: UIImage) async throws -> FoodAnalysisResult {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FoodAnalysisError.imageConversionFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Prepare the request
        let messages = [
            [
                "role": "system",
                "content": """
                You are a nutrition analysis expert. Analyze the food in the image and provide detailed nutritional information.
                Return the response in JSON format with the following structure:
                {
                    "food_name": "name of the food",
                    "confidence": 0.85,
                    "serving_size": "estimated serving size",
                    "nutrients": {
                        "calories": 250,
                        "protein": 10.5,
                        "fat": 12.3,
                        "carbohydrates": 30.2,
                        "calcium": 100,
                        "iron": 2.5,
                        "vitamin_a": 10.5,
                        "vitamin_b1": 0.5,
                        "vitamin_b2": 0.6,
                        "vitamin_c": 15.2,
                        "vitamin_d": 2.0,
                        "vitamin_e": 1.5,
                        "fiber": 3.1,
                        "sugar": 8.5,
                        "sodium": 400,
                        "cholesterol": 20,
                        "saturated_fat": 4.2,
                        "trans_fat": 0.0
                    }
                }
                All nutrient values should be in their standard units (calories in kcal, macronutrients in grams, micronutrients in mg).
                """
            ],
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": "Analyze this food image and provide detailed nutritional information including all vitamins (A, B1, B2, C, D, E) and minerals."
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\\(base64Image)"
                        ]
                    ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.3
        ]
        
        // Make the API request
        var request = URLRequest(url: URL(string: openAIEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \\(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FoodAnalysisError.apiRequestFailed
        }
        
        // Parse the response
        let responseData = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = responseData.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
            throw FoodAnalysisError.invalidResponse
        }
        
        let analysisData = try JSONDecoder().decode(FoodAnalysisData.self, from: jsonData)
        
        return FoodAnalysisResult(
            foodName: analysisData.foodName,
            nutrients: NutrientsRecord(
                calories: analysisData.nutrients.calories,
                protein: analysisData.nutrients.protein,
                fat: analysisData.nutrients.fat,
                carbohydrates: analysisData.nutrients.carbohydrates,
                calcium: analysisData.nutrients.calcium,
                iron: analysisData.nutrients.iron,
                vitaminA: analysisData.nutrients.vitaminA,
                vitaminB1: analysisData.nutrients.vitaminB1,
                vitaminB2: analysisData.nutrients.vitaminB2,
                vitaminC: analysisData.nutrients.vitaminC,
                vitaminD: analysisData.nutrients.vitaminD,
                vitaminE: analysisData.nutrients.vitaminE,
                fiber: analysisData.nutrients.fiber,
                sugar: analysisData.nutrients.sugar,
                sodium: analysisData.nutrients.sodium,
                cholesterol: analysisData.nutrients.cholesterol,
                saturatedFat: analysisData.nutrients.saturatedFat,
                transFat: analysisData.nutrients.transFat
            ),
            confidence: analysisData.confidence
        )
    }
    
    // Fallback method using Vision framework for basic food detection
    func detectFoodType(from image: UIImage) async throws -> String? {
        guard let ciImage = CIImage(image: image) else {
            throw FoodAnalysisError.imageConversionFailed
        }
        
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        try handler.perform([request])
        
        guard let results = request.results else {
            return nil
        }
        
        // Filter for food-related classifications
        let foodClassifications = results
            .filter { $0.confidence > 0.5 }
            .map { $0.identifier }
            .filter { identifier in
                // Basic food-related keywords
                let foodKeywords = ["food", "fruit", "vegetable", "meat", "bread", "pasta", "rice", "salad", "soup", "dessert", "snack"]
                return foodKeywords.contains { identifier.lowercased().contains($0) }
            }
        
        return foodClassifications.first
    }
}

// MARK: - Models

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

struct FoodAnalysisData: Codable {
    let foodName: String
    let confidence: Double
    let servingSize: String
    let nutrients: NutrientsData
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case confidence
        case servingSize = "serving_size"
        case nutrients
    }
    
    struct NutrientsData: Codable {
        let calories: Double
        let protein: Double
        let fat: Double
        let carbohydrates: Double
        let calcium: Double
        let iron: Double
        let vitaminA: Double
        let vitaminB1: Double
        let vitaminB2: Double
        let vitaminC: Double
        let vitaminD: Double
        let vitaminE: Double
        let fiber: Double
        let sugar: Double
        let sodium: Double
        let cholesterol: Double
        let saturatedFat: Double
        let transFat: Double
        
        enum CodingKeys: String, CodingKey {
            case calories
            case protein
            case fat
            case carbohydrates
            case calcium
            case iron
            case vitaminA = "vitamin_a"
            case vitaminB1 = "vitamin_b1"
            case vitaminB2 = "vitamin_b2"
            case vitaminC = "vitamin_c"
            case vitaminD = "vitamin_d"
            case vitaminE = "vitamin_e"
            case fiber
            case sugar
            case sodium
            case cholesterol
            case saturatedFat = "saturated_fat"
            case transFat = "trans_fat"
        }
    }
}

// MARK: - Errors

enum FoodAnalysisError: LocalizedError {
    case imageConversionFailed
    case apiRequestFailed
    case invalidResponse
    case noFoodDetected
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for analysis"
        case .apiRequestFailed:
            return "Failed to analyze food"
        case .invalidResponse:
            return "Invalid response from analysis service"
        case .noFoodDetected:
            return "No food detected in image"
        }
    }
}