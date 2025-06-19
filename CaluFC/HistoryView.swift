import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @State private var selectedPeriod = TimePeriod.week
    @State private var calorieData: [DailyCalories] = []
    @State private var weeklyNutrients = WeeklyNutrients.empty
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    Picker("期間", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.displayName)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Calorie Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("カロリー摂取量")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        
                        Chart(calorieData) { data in
                            BarMark(
                                x: .value("Day", data.date, unit: .day),
                                y: .value("Calories", data.calories)
                            )
                            .foregroundStyle(data.calories > 2000 ? Color.red : Color.primary)
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                        
                        // Average Stats
                        HStack(spacing: 40) {
                            StatCard(title: "1日平均", value: String(averageCalories), unit: "kcal")
                            StatCard(title: "目標", value: "2,000", unit: "kcal")
                            StatCard(title: "達成率", value: String(successRate), unit: "%")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Nutrient Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text(getNutrientTitle())
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            HistoryNutrientRow(name: "たんぱく質", value: weeklyNutrients.protein, unit: "g")
                            HistoryNutrientRow(name: "炭水化物", value: weeklyNutrients.carbohydrates, unit: "g")
                            HistoryNutrientRow(name: "脂質", value: weeklyNutrients.fat, unit: "g")
                            HistoryNutrientRow(name: "食物繊維", value: weeklyNutrients.fiber, unit: "g")
                            HistoryNutrientRow(name: "糖質", value: weeklyNutrients.sugar, unit: "g")
                            HistoryNutrientRow(name: "ナトリウム", value: weeklyNutrients.sodium, unit: "mg")
                            HistoryNutrientRow(name: "カルシウム", value: weeklyNutrients.calcium, unit: "mg")
                            HistoryNutrientRow(name: "鉄分", value: weeklyNutrients.iron, unit: "mg")
                            HistoryNutrientRow(name: "ビタミンA", value: weeklyNutrients.vitaminA, unit: "μg")
                            HistoryNutrientRow(name: "ビタミンC", value: weeklyNutrients.vitaminC, unit: "mg")
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.white)
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                Task {
                    await loadHistoryData()
                }
            }
            .onChange(of: selectedPeriod) { _, _ in
                Task {
                    await loadHistoryData()
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadHistoryData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 認証済みユーザーのみロード
            guard appleSignInManager.isSignedIn else {
                print("⚠️ [HistoryView] User not signed in, showing empty data")
                DispatchQueue.main.async {
                    self.calorieData = []
                    self.weeklyNutrients = WeeklyNutrients.empty
                }
                return
            }
            
            let userId = appleSignInManager.getCurrentUserId()
            let dateRange = getDateRange(for: selectedPeriod)
            
            // Load all meals and filter locally to avoid timezone issues
            let allMealsFromDB = try await SupabaseManager.shared.fetchMeals(for: userId, date: nil)
            
            // Filter meals based on the selected period
            let startDate = dateRange.first ?? Date()
            let endDate = Calendar.current.date(byAdding: .day, value: 1, to: dateRange.last ?? Date()) ?? Date()
            
            let allMeals = allMealsFromDB.filter { meal in
                if let mealDate = ISO8601DateFormatter().date(from: meal.createdAt) {
                    return mealDate >= startDate && mealDate < endDate
                }
                return false
            }
            
            DispatchQueue.main.async {
                self.processHistoryData(meals: allMeals, dateRange: dateRange)
                print("📊 [HistoryView] Loaded \(allMeals.count) meals for history from \(allMealsFromDB.count) total meals")
            }
        } catch {
            print("❌ [HistoryView] Failed to load history data: \(error)")
        }
    }
    
    private func processHistoryData(meals: [MealRecord], dateRange: [Date]) {
        // Process calorie data by day
        var dailyCaloriesMap: [Date: Int] = [:]
        
        for meal in meals {
            if let mealDate = ISO8601DateFormatter().date(from: meal.createdAt) {
                let dayStart = Calendar.current.startOfDay(for: mealDate)
                dailyCaloriesMap[dayStart, default: 0] += meal.calories
            }
        }
        
        // Create DailyCalories array
        calorieData = dateRange.map { date in
            DailyCalories(date: date, calories: dailyCaloriesMap[date] ?? 0)
        }
        
        // Calculate weekly nutrients average
        calculateWeeklyNutrients(from: meals)
    }
    
    private func calculateWeeklyNutrients(from meals: [MealRecord]) {
        guard !meals.isEmpty else {
            weeklyNutrients = WeeklyNutrients.empty
            return
        }
        
        let totalNutrients = meals.reduce(into: WeeklyNutrients.empty) { result, meal in
            result.protein += Int(meal.nutrients.protein)
            result.carbohydrates += Int(meal.nutrients.carbohydrates)
            result.fat += Int(meal.nutrients.fat)
            result.fiber += Int(meal.nutrients.fiber ?? 0)
            result.sugar += Int(meal.nutrients.sugar ?? 0)
            result.sodium += Int(meal.nutrients.sodium ?? 0)
            result.calcium += Int(meal.nutrients.calcium ?? 0)
            result.iron += Int(meal.nutrients.iron ?? 0)
            result.vitaminA += Int(meal.nutrients.vitaminA ?? 0)
            result.vitaminC += Int(meal.nutrients.vitaminC ?? 0)
        }
        
        // Calculate average based on the actual selected period
        let daysInPeriod: Int
        switch selectedPeriod {
        case .week: daysInPeriod = 7
        case .month: daysInPeriod = 30
        case .year: daysInPeriod = 365
        }
        
        weeklyNutrients = WeeklyNutrients(
            protein: totalNutrients.protein / daysInPeriod,
            carbohydrates: totalNutrients.carbohydrates / daysInPeriod,
            fat: totalNutrients.fat / daysInPeriod,
            fiber: totalNutrients.fiber / daysInPeriod,
            sugar: totalNutrients.sugar / daysInPeriod,
            sodium: totalNutrients.sodium / daysInPeriod,
            calcium: totalNutrients.calcium / daysInPeriod,
            iron: totalNutrients.iron / daysInPeriod,
            vitaminA: totalNutrients.vitaminA / daysInPeriod,
            vitaminC: totalNutrients.vitaminC / daysInPeriod
        )
    }
    
    private func getDateRange(for period: TimePeriod) -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        
        switch period {
        case .week:
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    dates.append(calendar.startOfDay(for: date))
                }
            }
        case .month:
            for i in 0..<30 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    dates.append(calendar.startOfDay(for: date))
                }
            }
        case .year:
            for i in 0..<365 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    dates.append(calendar.startOfDay(for: date))
                }
            }
        }
        
        return dates.reversed()
    }
    
    private func getCurrentUserId() -> UUID {
        return appleSignInManager.getCurrentUserId()
    }
    
    // MARK: - Computed Properties
    
    private var averageCalories: Int {
        guard !calorieData.isEmpty else { return 0 }
        let total = calorieData.reduce(0) { $0 + $1.calories }
        return total / calorieData.count
    }
    
    private var successRate: Int {
        guard !calorieData.isEmpty else { return 0 }
        let goal = 2000
        let successfulDays = calorieData.filter { $0.calories >= Int(Double(goal) * 0.8) && $0.calories <= Int(Double(goal) * 1.2) }.count
        return (successfulDays * 100) / calorieData.count
    }
    
    private func getNutrientTitle() -> String {
        switch selectedPeriod {
        case .week: return "週間栄養素平均"
        case .month: return "月間栄養素平均"
        case .year: return "年間栄養素平均"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistoryNutrientRow: View {
    let name: String
    let value: Int
    let unit: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.callout)
                .foregroundColor(.black)
            
            Spacer()
            
            Text("\(value)\(unit)")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

enum TimePeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var displayName: String {
        switch self {
        case .week: return "週間"
        case .month: return "月間"
        case .year: return "年間"
        }
    }
}

struct DailyCalories: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
}

struct WeeklyNutrients {
    var protein: Int
    var carbohydrates: Int
    var fat: Int
    var fiber: Int
    var sugar: Int
    var sodium: Int
    var calcium: Int
    var iron: Int
    var vitaminA: Int
    var vitaminC: Int
    
    static var empty: WeeklyNutrients {
        WeeklyNutrients(
            protein: 0, carbohydrates: 0, fat: 0,
            fiber: 0, sugar: 0, sodium: 0,
            calcium: 0, iron: 0, vitaminA: 0, vitaminC: 0
        )
    }
}

#Preview {
    HistoryView()
}