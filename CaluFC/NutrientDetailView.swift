import SwiftUI

struct NutrientDetailView: View {
    let nutrients: NutrientsRecord
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Main Nutrients
                VStack(alignment: .leading, spacing: 12) {
                    Text("主要栄養素")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        NutrientRow(name: "エネルギー", value: "\(Int(nutrients.calories)) kcal", color: .orange)
                        NutrientRow(name: "タンパク質", value: String(format: "%.1f g", nutrients.protein), color: .blue)
                        NutrientRow(name: "脂質", value: String(format: "%.1f g", nutrients.fat), color: .green)
                        NutrientRow(name: "炭水化物", value: String(format: "%.1f g", nutrients.carbohydrates), color: .purple)
                        if let fiber = nutrients.fiber {
                            NutrientRow(name: "食物繊維", value: String(format: "%.1f g", fiber), color: .brown)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Minerals
                if nutrients.calcium != nil || nutrients.iron != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ミネラル")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            if let calcium = nutrients.calcium {
                                NutrientRow(name: "カルシウム", value: String(format: "%.0f mg", calcium), color: .gray)
                            }
                            if let iron = nutrients.iron {
                                NutrientRow(name: "鉄", value: String(format: "%.1f mg", iron), color: .red)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Vitamins
                if nutrients.vitaminA != nil || nutrients.vitaminB1 != nil || nutrients.vitaminB2 != nil || 
                   nutrients.vitaminC != nil || nutrients.vitaminD != nil || nutrients.vitaminE != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ビタミン")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            if let vitaminA = nutrients.vitaminA {
                                NutrientRow(name: "ビタミンA", value: String(format: "%.0f μg", vitaminA), color: .orange)
                            }
                            if let vitaminB1 = nutrients.vitaminB1 {
                                NutrientRow(name: "ビタミンB1", value: String(format: "%.2f mg", vitaminB1), color: .yellow)
                            }
                            if let vitaminB2 = nutrients.vitaminB2 {
                                NutrientRow(name: "ビタミンB2", value: String(format: "%.2f mg", vitaminB2), color: .yellow)
                            }
                            if let vitaminC = nutrients.vitaminC {
                                NutrientRow(name: "ビタミンC", value: String(format: "%.0f mg", vitaminC), color: .pink)
                            }
                            if let vitaminD = nutrients.vitaminD {
                                NutrientRow(name: "ビタミンD", value: String(format: "%.1f μg", vitaminD), color: .blue)
                            }
                            if let vitaminE = nutrients.vitaminE {
                                NutrientRow(name: "ビタミンE", value: String(format: "%.1f mg", vitaminE), color: .green)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Optional Nutrients
                if nutrients.sugar != nil || nutrients.sodium != nil || nutrients.cholesterol != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("その他の栄養素")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            if let sugar = nutrients.sugar {
                                NutrientRow(name: "糖質", value: String(format: "%.1f g", sugar), color: .pink)
                            }
                            if let sodium = nutrients.sodium {
                                NutrientRow(name: "ナトリウム", value: String(format: "%.0f mg", sodium), color: .cyan)
                            }
                            if let cholesterol = nutrients.cholesterol {
                                NutrientRow(name: "コレステロール", value: String(format: "%.0f mg", cholesterol), color: .yellow)
                            }
                            if let saturatedFat = nutrients.saturatedFat {
                                NutrientRow(name: "飽和脂肪酸", value: String(format: "%.1f g", saturatedFat), color: .indigo)
                            }
                            if let transFat = nutrients.transFat {
                                NutrientRow(name: "トランス脂肪酸", value: String(format: "%.1f g", transFat), color: .red)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct NutrientRow: View {
    let name: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 8, height: 8)
            
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}