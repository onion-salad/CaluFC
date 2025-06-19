import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @Binding var showingCamera: Bool
    @Binding var capturedImage: UIImage?
    @State private var todayCalories: Int = 0
    @State private var dailyGoal: Int = 2000
    @State private var meals: [Meal] = []
    @State private var isAnalyzing = false
    @State private var analyzingMeal: Meal?
    @State private var selectedMeal: Meal?
    @State private var showingMealDetail = false
    
    var calorieProgress: Double {
        Double(todayCalories) / Double(dailyGoal)
    }
    
    // MARK: - Computed Properties for Nutrients
    
    var todayNutrients: (protein: Double, carbs: Double, fat: Double) {
        let todayMeals = meals.filter { Calendar.current.isDateInToday($0.time) }
        
        let protein = todayMeals.reduce(0.0) { sum, meal in
            sum + (meal.nutrients?.protein ?? 0)
        }
        let carbs = todayMeals.reduce(0.0) { sum, meal in
            sum + (meal.nutrients?.carbohydrates ?? 0)
        }
        let fat = todayMeals.reduce(0.0) { sum, meal in
            sum + (meal.nutrients?.fat ?? 0)
        }
        
        return (protein, carbs, fat)
    }
    
    var todayMinerals: (calcium: Double, iron: Double, fiber: Double) {
        let todayMeals = meals.filter { Calendar.current.isDateInToday($0.time) }
        
        let calcium = todayMeals.reduce(0.0) { sum, meal in
            sum + (meal.nutrients?.calcium ?? 0)
        }
        let iron = todayMeals.reduce(0.0) { sum, meal in
            sum + (meal.nutrients?.iron ?? 0)
        }
        let fiber = todayMeals.reduce(0.0) { sum, meal in
            sum + (meal.nutrients?.fiber ?? 0)
        }
        
        return (calcium, iron, fiber)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Today's Summary - Minimal Design
                    VStack(spacing: 20) {
                        HStack {
                            Text("今日の摂取量")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            Spacer()
                            Text("\(todayCalories) / \(dailyGoal) kcal")
                                .font(.callout)
                                .foregroundColor(.gray)
                        }
                        
                        // Progress Bar - Simple
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(height: 4)
                                        .foregroundColor(.gray.opacity(0.2))
                                    
                                    Rectangle()
                                        .frame(width: min(geometry.size.width * calorieProgress, geometry.size.width), height: 4)
                                        .foregroundColor(.black)
                                        .animation(.easeInOut, value: calorieProgress)
                                }
                            }
                            .frame(height: 4)
                            
                            Text("\(Int(calorieProgress * 100))% 達成")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Minimal Nutrition Grid
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                MinimalNutrientCard(label: "たんぱく質", value: "\(Int(todayNutrients.protein))g")
                                MinimalNutrientCard(label: "炭水化物", value: "\(Int(todayNutrients.carbs))g")
                                MinimalNutrientCard(label: "脂質", value: "\(Int(todayNutrients.fat))g")
                            }
                            
                            HStack(spacing: 16) {
                                MinimalNutrientCard(label: "カルシウム", value: "\(Int(todayMinerals.calcium))mg")
                                MinimalNutrientCard(label: "鉄分", value: "\(Int(todayMinerals.iron))mg")
                                MinimalNutrientCard(label: "食物繊維", value: "\(Int(todayMinerals.fiber))g")
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Add Meal Button - Minimal
                    Button(action: {
                        print("🎯 [HomeView] Add Meal button pressed")
                        print("   Current showingCamera: \(showingCamera)")
                        showingCamera = true
                        print("   Set showingCamera = true")
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.body)
                            Text("食事を記録")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Meal History - Show all meals, not just today's
                    if !meals.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("食事履歴")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
                            ForEach(meals.prefix(10)) { meal in // Show only recent 10 meals
                                if meal.id == analyzingMeal?.id && isAnalyzing {
                                    MinimalLoadingMealCard(meal: meal)
                                } else {
                                    MinimalMealCard(
                                        meal: meal,
                                        onTap: {
                                            selectedMeal = meal
                                            showingMealDetail = true
                                        },
                                        onDelete: {
                                            Task {
                                                await deleteMeal(meal)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.white)
            .navigationTitle("Calu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                print("🏠 [HomeView] View appeared, loading meals from Supabase...")
                Task {
                    await loadMealsFromSupabase()
                }
            }
            .sheet(isPresented: $showingMealDetail) {
                if let meal = selectedMeal {
                    MealDetailView(meal: meal)
                }
            }
        }
        .onChange(of: capturedImage) { oldImage, newImage in
            print("🔄 [HomeView] capturedImage onChange triggered")
            print("   Old image: \(oldImage != nil ? "exists" : "nil")")
            print("   New image: \(newImage != nil ? "exists" : "nil")")
            
            if let image = newImage {
                print("🍔 [HomeView] Image captured, starting analysis")
                print("   Image size: \(image.size)")
                print("   Hiding camera view...")
                showingCamera = false
                print("   Calling analyzeFood...")
                analyzeFood(image: image)
                print("   Resetting capturedImage...")
                capturedImage = nil // Reset for next capture
                print("✅ [HomeView] onChange processing complete")
            } else {
                print("ℹ️ [HomeView] No image in onChange")
            }
        }
    }
    
    private func analyzeFood(image: UIImage) {
        print("🍔 [HomeView] analyzeFood called")
        print("   Image details: size=\(image.size), scale=\(image.scale)")
        
        // Create a temporary meal with loading state
        print("🍔 [HomeView] Creating temporary meal...")
        let tempMeal = Meal(
            name: "分析中...",
            calories: 0,
            time: Date(),
            image: image,
            nutrients: nil
        )
        print("   Temp meal ID: \(tempMeal.id)")
        
        print("🍔 [HomeView] Setting analysis state...")
        isAnalyzing = true
        analyzingMeal = tempMeal
        meals.insert(tempMeal, at: 0)
        print("   Meals count after insert: \(meals.count)")
        print("   isAnalyzing: \(isAnalyzing)")
        
        print("🍔 [HomeView] Starting async Task...")
        Task {
            print("📱 [Task] Task started on background thread")
            
            print("📱 [Task] Calling SupabaseManager.analyzeFoodWithEdgeFunction...")
            let result = await SupabaseManager.shared.analyzeFoodWithEdgeFunction(image: image)
            print("📱 [Task] SupabaseManager call completed")
            print("   Result: \(result != nil ? "success" : "nil")")
            
            if let result = result {
                print("   Food name: \(result.foodName)")
                print("   Calories: \(result.nutrients.calories)")
            }
            
            print("📱 [Task] Dispatching to main queue...")
            DispatchQueue.main.async {
                print("🏠 [MainQueue] Back on main thread")
                print("🏠 [MainQueue] Setting isAnalyzing = false")
                self.isAnalyzing = false
                
                if let result = result {
                    print("🏠 [MainQueue] Processing successful result...")
                    // Remove the loading meal and add the real one
                    if let index = self.meals.firstIndex(where: { $0.id == tempMeal.id }) {
                        print("   Found temp meal at index: \(index)")
                        let finalMeal = Meal(
                            name: result.foodName,
                            calories: Int(result.nutrients.calories),
                            time: Date(),
                            image: image,
                            nutrients: result.nutrients
                        )
                        self.meals[index] = finalMeal
                        print("   Replaced meal with real data")
                        
                        // Save to Supabase
                        print("💾 [MainQueue] Saving meal to Supabase...")
                        Task {
                            await self.saveMealToSupabase(finalMeal)
                        }
                        
                        // Update daily calories
                        print("   Updating daily calories...")
                        self.updateDailyCalories()
                        print("   New daily calories: \(self.todayCalories)")
                    } else {
                        print("❌ [MainQueue] Could not find temp meal in list")
                    }
                } else {
                    print("❌ [MainQueue] Analysis failed - removing temp meal")
                    let countBefore = self.meals.count
                    self.meals.removeAll { $0.id == tempMeal.id }
                    print("   Meals count: \(countBefore) -> \(self.meals.count)")
                }
                print("✅ [MainQueue] Main queue processing complete")
            }
        }
        print("✅ [HomeView] analyzeFood method complete")
    }
    
    private func updateDailyCalories() {
        todayCalories = meals.reduce(0) { $0 + $1.calories }
    }
    
    // MARK: - Supabase Integration
    
    private func saveMealToSupabase(_ meal: Meal) async {
        do {
            // 認証済みユーザーのみ保存
            guard appleSignInManager.isSignedIn else {
                print("⚠️ [HomeView] User not signed in, skipping Supabase save")
                return
            }
            
            // Convert image to base64 for storage
            let imageUrl: String?
            if let image = meal.image {
                let imageData = image.jpegData(compressionQuality: 0.8)
                imageUrl = imageData?.base64EncodedString()
            } else {
                imageUrl = nil
            }
            
            let mealRecord = MealRecord(
                id: meal.id,
                userId: appleSignInManager.getCurrentUserId(),
                name: meal.name,
                calories: meal.calories,
                imageUrl: imageUrl,
                nutrients: meal.nutrients ?? NutrientsRecord(
                    calories: Double(meal.calories),
                    protein: 0, fat: 0, carbohydrates: 0,
                    calcium: 0, iron: 0, vitaminA: 0,
                    vitaminB1: 0, vitaminB2: 0, vitaminC: 0,
                    vitaminD: 0, vitaminE: 0, fiber: 0,
                    sugar: 0, sodium: 0, cholesterol: 0,
                    saturatedFat: 0, transFat: 0
                ),
                createdAt: ISO8601DateFormatter().string(from: meal.time),
                updatedAt: nil
            )
            
            try await SupabaseManager.shared.saveMeal(mealRecord)
            print("✅ [HomeView] Meal saved to Supabase successfully")
        } catch {
            print("❌ [HomeView] Failed to save meal to Supabase: \(error)")
        }
    }
    
    private func loadMealsFromSupabase() async {
        do {
            // 認証済みユーザーのみロード
            guard appleSignInManager.isSignedIn else {
                print("⚠️ [HomeView] User not signed in, skipping Supabase load")
                return
            }
            
            let userId = appleSignInManager.getCurrentUserId()
            // 全ての食事履歴を取得（dateパラメータをnilにする）
            let mealRecords = try await SupabaseManager.shared.fetchMeals(for: userId, date: nil)
            
            DispatchQueue.main.async {
                print("📥 [HomeView] Loaded \(mealRecords.count) meals from Supabase")
                // Convert MealRecord to Meal with base64 image conversion
                let loadedMeals = mealRecords.map { record in
                    var mealImage: UIImage?
                    if let imageUrlString = record.imageUrl,
                       let imageData = Data(base64Encoded: imageUrlString) {
                        mealImage = UIImage(data: imageData)
                    }
                    
                    return Meal(
                        id: record.id, // IDを保持
                        name: record.name,
                        calories: record.calories,
                        time: ISO8601DateFormatter().date(from: record.createdAt) ?? Date(),
                        image: mealImage,
                        nutrients: record.nutrients
                    )
                }
                
                // 全ての食事を時系列順（新しい順）で設定
                self.meals = loadedMeals.sorted { $0.time > $1.time }
                self.updateDailyCalories()
            }
        } catch {
            print("❌ [HomeView] Failed to load meals from Supabase: \(error)")
        }
    }
    
    private func getCurrentUserId() -> UUID {
        return appleSignInManager.getCurrentUserId()
    }
    
    private func deleteMeal(_ meal: Meal) async {
        do {
            // Supabaseから削除
            try await SupabaseManager.shared.deleteMeal(id: meal.id)
            
            // ローカルリストから削除
            DispatchQueue.main.async {
                self.meals.removeAll { $0.id == meal.id }
                self.updateDailyCalories()
                print("✅ [HomeView] Meal deleted successfully")
            }
        } catch {
            print("❌ [HomeView] Failed to delete meal: \(error)")
        }
    }
}

// MARK: - Minimal Design Components

struct MinimalNutrientCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct MinimalMealCard: View {
    let meal: Meal
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
            // 食事画像（角丸）
            if let image = meal.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.title3)
                    )
            }
            
            // 食事情報
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text(formatDate(meal.time))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // 栄養情報（コンパクト表示）
                if let nutrients = meal.nutrients {
                    HStack(spacing: 8) {
                        Text("P: \(Int(nutrients.protein))g")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("C: \(Int(nutrients.carbohydrates))g")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("F: \(Int(nutrients.fat))g")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // カロリーと削除ボタン
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(meal.calories) kcal")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .alert("食事を削除", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("この食事記録を削除しますか？")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "今日 \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.timeStyle = .short
            return "昨日 \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct NutritionalValue: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
    }
}

struct NutrientBadge: View {
    let value: Int
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
            Text("\(value)")
                .font(.caption)
            Text(unit)
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}

struct MinimalLoadingMealCard: View {
    let meal: Meal
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 撮影した画像を表示（角丸）
            if let image = meal.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .opacity(0.7)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.6)
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("解析中...")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text("栄養情報を解析しています")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .black))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .opacity(isAnimating ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    HomeView(showingCamera: .constant(false), capturedImage: .constant(nil))
}