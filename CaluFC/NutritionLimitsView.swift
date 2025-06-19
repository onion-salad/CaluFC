import SwiftUI

struct NutritionLimitsView: View {
    let weeklyNutrients: WeeklyNutrients
    let profile: UserProfile
    @State private var dailyLimits: NutritionCalculator.DailyNutritionLimits?
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HStack {
                Text("週間摂取量 vs 推奨値")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                Spacer()
            }
            
            if let limits = dailyLimits {
                VStack(spacing: 12) {
                    // マクロ栄養素
                    MacroNutrientComparisonSection(
                        weeklyNutrients: weeklyNutrients,
                        limits: limits
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // ビタミン・ミネラル
                    MicroNutrientComparisonSection(
                        weeklyNutrients: weeklyNutrients,
                        limits: limits
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // 制限すべき栄養素
                    LimitedNutrientSection(
                        weeklyNutrients: weeklyNutrients,
                        limits: limits
                    )
                }
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("推奨値を計算中...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            calculateLimits()
        }
        .onChange(of: profile) { _, _ in
            calculateLimits()
        }
    }
    
    private func calculateLimits() {
        let activityLevel = NutritionCalculator.ActivityLevel(rawValue: profile.activityLevel) ?? .moderate
        dailyLimits = NutritionCalculator.calculateDailyLimits(
            age: profile.age,
            gender: profile.gender,
            weight: profile.weight,
            height: profile.height,
            activityLevel: activityLevel
        )
    }
}

// MARK: - Macro Nutrients Section
struct MacroNutrientComparisonSection: View {
    let weeklyNutrients: WeeklyNutrients
    let limits: NutritionCalculator.DailyNutritionLimits
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("主要栄養素（週間平均）")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 6) {
                // カロリーは WeeklyNutrients に含まれていないためコメントアウト
                // NutritionComparisonRow(
                //     name: "カロリー",
                //     current: weeklyNutrients.calories,
                //     target: limits.calories,
                //     unit: "kcal",
                //     isUpperLimit: false
                // )
                
                NutritionComparisonRow(
                    name: "たんぱく質",
                    current: Double(weeklyNutrients.protein),
                    target: limits.protein,
                    unit: "g",
                    isUpperLimit: false
                )
                
                NutritionComparisonRow(
                    name: "炭水化物",
                    current: Double(weeklyNutrients.carbohydrates),
                    target: limits.carbohydrates,
                    unit: "g",
                    isUpperLimit: false
                )
                
                NutritionComparisonRow(
                    name: "脂質",
                    current: Double(weeklyNutrients.fat),
                    target: limits.fat,
                    unit: "g",
                    isUpperLimit: false
                )
            }
        }
    }
}

// MARK: - Micro Nutrients Section
struct MicroNutrientComparisonSection: View {
    let weeklyNutrients: WeeklyNutrients
    let limits: NutritionCalculator.DailyNutritionLimits
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("ビタミン・ミネラル（週間平均）")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 6) {
                NutritionComparisonRow(
                    name: "食物繊維",
                    current: Double(weeklyNutrients.fiber),
                    target: limits.fiber,
                    unit: "g",
                    isUpperLimit: false
                )
                
                NutritionComparisonRow(
                    name: "カルシウム",
                    current: Double(weeklyNutrients.calcium),
                    target: limits.calcium,
                    unit: "mg",
                    isUpperLimit: false
                )
                
                NutritionComparisonRow(
                    name: "鉄分",
                    current: Double(weeklyNutrients.iron),
                    target: limits.iron,
                    unit: "mg",
                    isUpperLimit: false
                )
                
                NutritionComparisonRow(
                    name: "ビタミンA",
                    current: Double(weeklyNutrients.vitaminA),
                    target: limits.vitaminA,
                    unit: "μg",
                    isUpperLimit: false
                )
                
                NutritionComparisonRow(
                    name: "ビタミンC",
                    current: Double(weeklyNutrients.vitaminC),
                    target: limits.vitaminC,
                    unit: "mg",
                    isUpperLimit: false
                )
            }
        }
    }
}

// MARK: - Limited Nutrients Section
struct LimitedNutrientSection: View {
    let weeklyNutrients: WeeklyNutrients
    let limits: NutritionCalculator.DailyNutritionLimits
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("制限すべき栄養素（週間平均）")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 6) {
                NutritionComparisonRow(
                    name: "ナトリウム",
                    current: Double(weeklyNutrients.sodium),
                    target: limits.sodium,
                    unit: "mg",
                    isUpperLimit: true
                )
                
                NutritionComparisonRow(
                    name: "糖質",
                    current: Double(weeklyNutrients.sugar),
                    target: limits.sugar,
                    unit: "g",
                    isUpperLimit: true
                )
                
                // コレステロールと飽和脂肪酸は WeeklyNutrients に含まれていないためコメントアウト
                // if weeklyNutrients.cholesterol > 0 {
                //     NutritionComparisonRow(
                //         name: "コレステロール",
                //         current: weeklyNutrients.cholesterol,
                //         target: limits.cholesterol,
                //         unit: "mg",
                //         isUpperLimit: true
                //     )
                // }
                // 
                // if weeklyNutrients.saturatedFat > 0 {
                //     NutritionComparisonRow(
                //         name: "飽和脂肪酸",
                //         current: weeklyNutrients.saturatedFat,
                //         target: limits.saturatedFat,
                //         unit: "g",
                //         isUpperLimit: true
                //     )
                // }
            }
        }
    }
}

// MARK: - Nutrition Comparison Row
struct NutritionComparisonRow: View {
    let name: String
    let current: Double
    let target: Double
    let unit: String
    let isUpperLimit: Bool
    
    private var percentage: Double {
        NutritionCalculator.calculateAchievementPercentage(current, target)
    }
    
    private var statusColor: Color {
        let colorString = NutritionCalculator.getStatusColor(current: current, target: target, isUpperLimit: isUpperLimit)
        switch colorString {
        case "green": return .green
        case "yellow": return .orange
        case "red": return .red
        default: return .gray
        }
    }
    
    private var statusText: String {
        if isUpperLimit {
            if percentage <= 80 { return "良好" }
            else if percentage <= 100 { return "注意" }
            else { return "超過" }
        } else {
            if percentage >= 80 { return "十分" }
            else if percentage >= 60 { return "やや不足" }
            else { return "不足" }
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.caption)
                    .foregroundColor(.black)
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(Int(current))\(unit)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        Text("/")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(Int(target))\(unit)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 4) {
                        Text("\(Int(percentage))%")
                            .font(.caption2)
                            .foregroundColor(statusColor)
                        Text(statusText)
                            .font(.caption2)
                            .foregroundColor(statusColor)
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(statusColor)
                        .frame(width: min(geometry.size.width * (percentage / 100), geometry.size.width), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NutritionLimitsView(
        weeklyNutrients: WeeklyNutrients(
            protein: 60,
            carbohydrates: 250,
            fat: 50,
            fiber: 15,
            sugar: 40,
            sodium: 2000,
            calcium: 500,
            iron: 8,
            vitaminA: 600,
            vitaminC: 80
        ),
        profile: UserProfile(
            name: "テストユーザー",
            age: 30,
            gender: "男性",
            weight: 70,
            height: 170,
            activityLevel: "moderate",
            dailyCalorieGoal: 2000
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}