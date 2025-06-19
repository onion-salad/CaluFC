import SwiftUI

struct MealDetailView: View {
    let meal: Meal
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    imageSection
                    basicInfoSection
                    
                    if let nutrients = meal.nutrients {
                        macroNutrientsSection(nutrients: nutrients)
                        vitaminsAndMineralsSection(nutrients: nutrients)
                    }
                }
                .padding(20)
            }
            .background(Color.white)
            .navigationTitle("食事詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    // MARK: - Image Section
    @ViewBuilder
    private var imageSection: some View {
        if let image = meal.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 250)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("画像なし")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("基本情報")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 12) {
                InfoRow(label: "食事名", value: meal.name)
                InfoRow(label: "カロリー", value: "\(meal.calories) kcal")
                InfoRow(label: "記録日時", value: formatDateTime(meal.time))
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Macro Nutrients Section
    private func macroNutrientsSection(nutrients: NutrientsRecord) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("主要栄養素")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                Spacer()
            }
            
            HStack(spacing: 12) {
                MacroNutrientCard(
                    label: "たんぱく質",
                    value: Int(nutrients.protein),
                    unit: "g",
                    percentage: calculatePercentage(nutrients.protein, daily: 75)
                )
                MacroNutrientCard(
                    label: "炭水化物",
                    value: Int(nutrients.carbohydrates),
                    unit: "g",
                    percentage: calculatePercentage(nutrients.carbohydrates, daily: 300)
                )
                MacroNutrientCard(
                    label: "脂質",
                    value: Int(nutrients.fat),
                    unit: "g",
                    percentage: calculatePercentage(nutrients.fat, daily: 65)
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Vitamins and Minerals Section
    private func vitaminsAndMineralsSection(nutrients: NutrientsRecord) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("ビタミン・ミネラル")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(spacing: 8) {
                basicNutrients(nutrients: nutrients)
                vitamins(nutrients: nutrients)
                fats(nutrients: nutrients)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Nutrient Groups
    @ViewBuilder
    private func basicNutrients(nutrients: NutrientsRecord) -> some View {
        if let fiber = nutrients.fiber {
            DetailNutrientRow(name: "食物繊維", value: fiber, unit: "g")
        }
        if let sugar = nutrients.sugar {
            DetailNutrientRow(name: "糖質", value: sugar, unit: "g")
        }
        if let sodium = nutrients.sodium {
            DetailNutrientRow(name: "ナトリウム", value: sodium, unit: "mg")
        }
        if let calcium = nutrients.calcium {
            DetailNutrientRow(name: "カルシウム", value: calcium, unit: "mg")
        }
        if let iron = nutrients.iron {
            DetailNutrientRow(name: "鉄分", value: iron, unit: "mg")
        }
    }
    
    @ViewBuilder
    private func vitamins(nutrients: NutrientsRecord) -> some View {
        if let vitaminA = nutrients.vitaminA {
            DetailNutrientRow(name: "ビタミンA", value: vitaminA, unit: "μg")
        }
        if let vitaminB1 = nutrients.vitaminB1, vitaminB1 > 0 {
            DetailNutrientRow(name: "ビタミンB1", value: vitaminB1, unit: "mg")
        }
        if let vitaminB2 = nutrients.vitaminB2, vitaminB2 > 0 {
            DetailNutrientRow(name: "ビタミンB2", value: vitaminB2, unit: "mg")
        }
        if let vitaminC = nutrients.vitaminC {
            DetailNutrientRow(name: "ビタミンC", value: vitaminC, unit: "mg")
        }
        if let vitaminD = nutrients.vitaminD, vitaminD > 0 {
            DetailNutrientRow(name: "ビタミンD", value: vitaminD, unit: "μg")
        }
    }
    
    @ViewBuilder
    private func fats(nutrients: NutrientsRecord) -> some View {
        if let vitaminE = nutrients.vitaminE, vitaminE > 0 {
            DetailNutrientRow(name: "ビタミンE", value: vitaminE, unit: "mg")
        }
        if let cholesterol = nutrients.cholesterol, cholesterol > 0 {
            DetailNutrientRow(name: "コレステロール", value: cholesterol, unit: "mg")
        }
        if let saturatedFat = nutrients.saturatedFat, saturatedFat > 0 {
            DetailNutrientRow(name: "飽和脂肪酸", value: saturatedFat, unit: "g")
        }
        if let transFat = nutrients.transFat, transFat > 0 {
            DetailNutrientRow(name: "トランス脂肪酸", value: transFat, unit: "g")
        }
    }
    
    // MARK: - Helper Functions
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func calculatePercentage(_ value: Double, daily: Double) -> Double {
        return min((value / daily) * 100, 100)
    }
}

// MARK: - Components

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
        .padding(.vertical, 4)
    }
}

struct MacroNutrientCard: View {
    let label: String
    let value: Int
    let unit: String
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.gray)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black)
                        .frame(width: geometry.size.width * (percentage / 100), height: 4)
                }
            }
            .frame(height: 4)
            
            Text("\(Int(percentage))%")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DetailNutrientRow: View {
    let name: String
    let value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.callout)
                .foregroundColor(.black)
            Spacer()
            Text("\(Int(value))\(unit)")
                .font(.callout)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

#Preview {
    MealDetailView(meal: Meal(
        name: "サンプル食事",
        calories: 500,
        time: Date(),
        image: nil,
        nutrients: NutrientsRecord(
            calories: 500,
            protein: 25,
            fat: 20,
            carbohydrates: 50,
            calcium: 200,
            iron: 5,
            vitaminA: 100,
            vitaminB1: 1,
            vitaminB2: 1,
            vitaminC: 50,
            vitaminD: 5,
            vitaminE: 10,
            fiber: 8,
            sugar: 10,
            sodium: 1000,
            cholesterol: 50,
            saturatedFat: 8,
            transFat: 0
        )
    ))
}