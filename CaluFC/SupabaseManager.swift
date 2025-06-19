import Foundation
import Supabase
import UIKit

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    let supabaseURL: URL
    let supabaseKey: String
    
    @Published private var currentSession: Session?
    private var isAuthenticating = false
    
    private init() {
        print("🔧 [SupabaseManager] Initializing...")
        
        // Supabase project credentials for calu_by_fc
        self.supabaseURL = URL(string: "https://hoxcaloztsuckrkyvlzy.supabase.co")!
        self.supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhveGNhbG96dHN1Y2tya3l2bHp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAzMDQwNTgsImV4cCI6MjA2NTg4MDA1OH0.m2PKtFTiw1Oxx42s_QBELvBkexO7-clGKQ6h-QbcRg4"
        
        print("   Supabase URL: \(supabaseURL)")
        print("   Supabase Key: \(supabaseKey.prefix(20))...")
        
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        print("✅ [SupabaseManager] Initialization complete")
        
        // 起動時に保存されたセッションを復元
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - Session Management
    
    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentSession = session
                print("✅ [SupabaseManager] Session restored: \(session.user.id)")
            }
        } catch {
            print("ℹ️ [SupabaseManager] No existing session to restore: \(error)")
        }
    }
    
    private func ensureAuthentication() async throws {
        // 既に認証中の場合は待機
        if isAuthenticating {
            while isAuthenticating {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
            }
            return
        }
        
        // セッションがある場合はそのまま使用
        if currentSession != nil {
            print("✅ [SupabaseManager] Using existing session")
            return
        }
        
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        print("🔑 [SupabaseManager] Authenticating with test user...")
        let session = try await signInWithEmail(
            email: "kokimaru0502@yahoo.co.jp",
            password: "testpass123",
            isSignUp: false
        )
        currentSession = session
        print("✅ [SupabaseManager] Authentication successful")
    }
    
    // MARK: - Authentication
    
    func signInWithEmail(email: String, password: String, isSignUp: Bool) async throws -> Session {
        print("📧 [SupabaseManager] Starting email \(isSignUp ? "sign up" : "sign in")...")
        print("   Email: \(email)")
        
        if isSignUp {
            // 新規登録
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            print("✅ [SupabaseManager] Email sign up successful")
            
            guard let session = response.session else {
                throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "サインアップは成功しましたが、セッションが作成されませんでした。メールを確認してください。"])
            }
            return session
        } else {
            // サインイン
            let response = try await client.auth.signIn(
                email: email,
                password: password
            )
            print("✅ [SupabaseManager] Email sign in successful")
            return response
        }
    }
    
    func signOut() async throws {
        print("🔓 [SupabaseManager] Signing out...")
        try await client.auth.signOut()
        print("✅ [SupabaseManager] Sign out successful")
    }
    
    // MARK: - Meals
    
    func saveMeal(_ meal: MealRecord) async throws {
        print("💾 [SupabaseManager] Saving meal for user: \(meal.userId)")
        
        try await ensureAuthentication()
        
        // Use the meal record directly for insertion
        try await client
            .from("meals")
            .insert(meal)
            .execute()
        
        print("✅ [SupabaseManager] Meal saved successfully")
    }
    
    func fetchMeals(for userId: UUID, date: Date? = nil) async throws -> [MealRecord] {
        try await ensureAuthentication()
        
        // For now, we'll fetch all meals for the user and filter in memory
        // TODO: Update once we understand the correct Supabase Swift query syntax
        let response = try await client
            .from("meals")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        // Don't use automatic snake_case conversion - we handle it manually with CodingKeys
        let allMeals = try decoder.decode([MealRecord].self, from: response.data)
        
        // Filter by date if provided
        if let date = date {
            let startOfDay = Calendar.current.startOfDay(for: date)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            return allMeals.filter { meal in
                if let mealDate = formatter.date(from: meal.createdAt) {
                    return mealDate >= startOfDay && mealDate < endOfDay
                }
                return false
            }
        }
        
        return allMeals
    }
    
    func deleteMeal(id: UUID) async throws {
        print("🗑️ [SupabaseManager] Deleting meal with ID: \(id)")
        
        try await ensureAuthentication()
        
        try await client
            .from("meals")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        print("✅ [SupabaseManager] Meal deleted successfully")
    }
    
    // MARK: - User Profile
    
    func saveUserProfile(_ profile: UserProfileRecord) async throws {
        try await ensureAuthentication()
        
        try await client
            .from("user_profiles")
            .upsert(profile)
            .execute()
    }
    
    func fetchUserProfile(for userId: UUID) async throws -> UserProfileRecord? {
        try await ensureAuthentication()
        
        let response = try await client
            .from("user_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        // Don't use automatic snake_case conversion - we handle it manually with CodingKeys
        return try decoder.decode(UserProfileRecord.self, from: response.data)
    }
    
    // MARK: - Food Analysis
    
    func analyzeFood(imageData: Data) async throws -> FoodAnalysisResult {
        // This would integrate with your AI service
        // For now, returning mock data
        return FoodAnalysisResult(
            foodName: "Sample Food",
            nutrients: NutrientsRecord(
                calories: 250,
                protein: 10,
                fat: 12,
                carbohydrates: 30,
                calcium: 100,
                iron: 2,
                vitaminA: 10,
                vitaminB1: 0.5,
                vitaminB2: 0.6,
                vitaminC: 15,
                vitaminD: 2,
                vitaminE: 1.5,
                fiber: 3,
                sugar: 8,
                sodium: 400,
                cholesterol: 20,
                saturatedFat: 4,
                transFat: 0
            ),
            confidence: 0.85
        )
    }
    
    // MARK: - Edge Function Integration
    
    func analyzeFoodWithEdgeFunction(image: UIImage) async -> FoodAnalysisResult? {
        print("🌐 [SupabaseManager] =========================")
        print("🌐 [SupabaseManager] Starting Edge Function analysis")
        print("   Input image size: \(image.size)")
        print("   Input image scale: \(image.scale)")
        print("   Function context: async")
        
        // First, upload image to storage
        print("🌐 [SupabaseManager] Converting image to JPEG...")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ [SupabaseManager] Failed to convert image to JPEG data")
            print("🌐 [SupabaseManager] =========================")
            return nil
        }
        print("   JPEG data size: \(imageData.count) bytes")
        
        let fileName = "meal_images/\(UUID().uuidString).jpg"
        print("🌐 [SupabaseManager] Uploading image with filename: \(fileName)")
        print("   Supabase URL: \(supabaseURL)")
        print("   Supabase Key: \(supabaseKey.prefix(20))...")
        
        do {
            // Skip storage upload for now and call Edge Function directly with base64 image
            print("🌐 [SupabaseManager] Skipping storage upload, calling Edge Function directly")
            
            // Call Edge Function with base64 encoded image
            let functionURL = supabaseURL.appendingPathComponent("functions/v1/analyze-meal")
            print("🌐 [SupabaseManager] Calling Edge Function at: \(functionURL)")
            
            var request = URLRequest(url: functionURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Send base64 encoded image data instead of file path
            let base64Image = imageData.base64EncodedString()
            let requestBody = [
                "image_data": base64Image,
                "user_id": "test-user-\(UUID().uuidString)", // Temporary user ID for testing
                "eaten_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("🌐 [SupabaseManager] Request body keys: \(requestBody.keys)")
            print("🌐 [SupabaseManager] Base64 image size: \(base64Image.count) characters")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 [SupabaseManager] Response status: \(httpResponse.statusCode)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🌐 [SupabaseManager] Response data: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            let edgeResponse = try decoder.decode(EdgeFunctionResponse.self, from: data)
            
            if edgeResponse.success, let analysisData = edgeResponse.data {
                print("✅ [SupabaseManager] Edge Function analysis successful")
                print("   Food name: \(analysisData.name)")
                print("   Calories: \(analysisData.calories)")
                
                let result = FoodAnalysisResult(
                    foodName: analysisData.name,
                    nutrients: NutrientsRecord(
                        calories: analysisData.calories,
                        protein: analysisData.protein,
                        fat: analysisData.fat,
                        carbohydrates: analysisData.carbohydrates,
                        calcium: analysisData.calcium,
                        iron: analysisData.iron,
                        vitaminA: analysisData.vitaminA,
                        vitaminB1: analysisData.vitaminB1,
                        vitaminB2: analysisData.vitaminB2,
                        vitaminC: analysisData.vitaminC,
                        vitaminD: analysisData.vitaminD,
                        vitaminE: analysisData.vitaminE,
                        fiber: analysisData.fiber,
                        sugar: analysisData.sugar,
                        sodium: analysisData.sodium,
                        cholesterol: analysisData.cholesterol,
                        saturatedFat: analysisData.saturatedFat,
                        transFat: analysisData.transFat
                    ),
                    confidence: 0.85
                )
                print("🌐 [SupabaseManager] =========================")
                return result
            } else {
                print("❌ [SupabaseManager] Edge Function returned error: \(edgeResponse.error ?? "Unknown error")")
                print("🌐 [SupabaseManager] =========================")
                return nil
            }
            
        } catch {
            print("❌ [SupabaseManager] Error in Edge Function call:")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error)")
            print("   Error localized: \(error.localizedDescription)")
            
            if let urlError = error as? URLError {
                print("   URL Error code: \(urlError.code)")
                print("   URL Error domain: \(urlError.code.rawValue)")
            }
            
            if let decodingError = error as? DecodingError {
                print("   Decoding error details: \(decodingError)")
            }
            
            // Return mock data for testing
            print("🔄 [SupabaseManager] Returning mock data due to error")
            let mockResult = FoodAnalysisResult(
                foodName: "テスト食品（エラー時のモック）",
                nutrients: NutrientsRecord(
                    calories: 250,
                    protein: 10,
                    fat: 12,
                    carbohydrates: 30,
                    calcium: 100,
                    iron: 2,
                    vitaminA: 10,
                    vitaminB1: 0.5,
                    vitaminB2: 0.6,
                    vitaminC: 15,
                    vitaminD: 2,
                    vitaminE: 1.5,
                    fiber: 3,
                    sugar: 8,
                    sodium: 400,
                    cholesterol: 20,
                    saturatedFat: 4,
                    transFat: 0
                ),
                confidence: 0.85
            )
            print("🌐 [SupabaseManager] =========================")
            return mockResult
        }
    }
}

// MARK: - Database Models

struct MealRecord: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let calories: Int
    let imageUrl: String?
    let nutrients: NutrientsRecord
    let createdAt: String
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case calories
        case imageUrl = "image_url"
        case nutrients
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct NutrientsRecord: Codable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbohydrates: Double
    let calcium: Double?
    let iron: Double?
    let vitaminA: Double?
    let vitaminB1: Double?
    let vitaminB2: Double?
    let vitaminC: Double?
    let vitaminD: Double?
    let vitaminE: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let cholesterol: Double?
    let saturatedFat: Double?
    let transFat: Double?
    
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

struct UserProfileRecord: Codable {
    let id: UUID
    let name: String
    let age: Int
    let weight: Double
    let height: Double
    let gender: String
    let activityLevel: String
    let dailyCalorieGoal: Int
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case weight
        case height
        case gender
        case activityLevel = "activity_level"
        case dailyCalorieGoal = "daily_calorie_goal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct FoodAnalysisResult {
    let foodName: String
    let nutrients: NutrientsRecord
    let confidence: Double
}

// MARK: - Edge Function Response Models

struct EdgeFunctionResponse: Codable {
    let success: Bool
    let data: EdgeFunctionData?
    let error: String?
}

struct EdgeFunctionData: Codable {
    let name: String
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
    let sugar: Double?
    let sodium: Double?
    let cholesterol: Double?
    let saturatedFat: Double?
    let transFat: Double?
    let memo: String?
    let ingredients: [Ingredient]?
    let imageUrl: String?
    let eatenAt: String?
    
    enum CodingKeys: String, CodingKey {
        case name
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
        case memo
        case ingredients
        case imageUrl = "image_url"
        case eatenAt = "eaten_at"
    }
}

struct Ingredient: Codable {
    let name: String
    let amount: String
}