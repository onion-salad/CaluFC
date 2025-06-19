import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var profile = UserProfile(
        id: UUID(),
        name: "",
        age: 25,
        weight: 70,
        height: 170,
        gender: .male,
        activityLevel: .moderatelyActive,
        dailyCalorieGoal: 2000
    )
    @State private var showingAppleSignIn = false
    @Binding var isOnboardingComplete: Bool
    
    let totalSteps = 4
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar
                VStack(spacing: 8) {
                    HStack {
                        Text("\(currentStep + 1) / \(totalSteps)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    
                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                        .progressViewStyle(LinearProgressViewStyle(tint: .black))
                        .scaleEffect(y: 1.5)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 0:
                            WelcomeStepView()
                        case 1:
                            BasicInfoStepView(profile: $profile)
                        case 2:
                            PhysicalInfoStepView(profile: $profile)
                        case 3:
                            GoalsStepView(profile: $profile)
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("戻る") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    }
                    
                    Button(currentStep == totalSteps - 1 ? "開始する" : "次へ") {
                        if currentStep == totalSteps - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep += 1
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCurrentStepValid ? Color.black : Color.gray)
                    .cornerRadius(8)
                    .disabled(!isCurrentStepValid)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !profile.name.isEmpty
        case 2: return profile.weight > 0 && profile.height > 0
        case 3: return profile.dailyCalorieGoal > 0
        default: return false
        }
    }
    
    private func completeOnboarding() {
        Task {
            await saveInitialProfile()
            DispatchQueue.main.async {
                isOnboardingComplete = true
            }
        }
    }
    
    private func saveInitialProfile() async {
        // For now, just save locally to avoid RLS issues
        // TODO: Fix Supabase RLS policies and re-enable database saving
        UserDefaults.standard.set(profile.name, forKey: "user_profile_name")
        UserDefaults.standard.set(profile.age, forKey: "user_profile_age")
        UserDefaults.standard.set(profile.weight, forKey: "user_profile_weight")
        UserDefaults.standard.set(profile.height, forKey: "user_profile_height")
        UserDefaults.standard.set(profile.gender.rawValue, forKey: "user_profile_gender")
        UserDefaults.standard.set(profile.activityLevel.rawValue, forKey: "user_profile_activity_level")
        UserDefaults.standard.set(profile.dailyCalorieGoal, forKey: "user_profile_daily_calorie_goal")
        
        print("✅ [OnboardingView] Initial profile saved locally")
        
        /*
        // Original Supabase code - commented out due to RLS policy issues
        do {
            let profileRecord = UserProfileRecord(
                id: profile.id,
                name: profile.name,
                age: profile.age,
                weight: profile.weight,
                height: profile.height,
                gender: profile.gender.rawValue,
                activityLevel: profile.activityLevel.rawValue,
                dailyCalorieGoal: profile.dailyCalorieGoal,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await SupabaseManager.shared.saveUserProfile(profileRecord)
            print("✅ [OnboardingView] Initial profile saved successfully")
        } catch {
            print("❌ [OnboardingView] Failed to save initial profile: \(error)")
        }
        */
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.black)
            
            VStack(spacing: 16) {
                Text("Caluへようこそ")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text("AIで食事を分析し\n栄養管理を簡単に")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                FeatureRow(icon: "camera.fill", title: "撮影分析", description: "食事を撮影するだけで栄養を瞬時に解析")
                FeatureRow(icon: "chart.bar.fill", title: "記録管理", description: "毎日の摂取量と栄養目標を確認")
                FeatureRow(icon: "clock.fill", title: "履歴確認", description: "食事パターンと進捗を把握")
            }
        }
    }
}

struct BasicInfoStepView: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("基本情報")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text("あなたに合わせた栄養管理のために")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("お名前")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    TextField("名前を入力", text: $profile.name)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("年齢")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    Picker("年齢", selection: $profile.age) {
                        ForEach(15...100, id: \.self) { age in
                            Text("\(age)歳").tag(age)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("性別")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    Picker("性別", selection: $profile.gender) {
                        Text("男性").tag(UserProfile.Gender.male)
                        Text("女性").tag(UserProfile.Gender.female)
                        Text("その他").tag(UserProfile.Gender.other)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}

struct PhysicalInfoStepView: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("身体情報")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text("栄養必要量の計算に使用します")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("体重")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    Picker("体重", selection: Binding(
                        get: { Int(profile.weight) },
                        set: { profile.weight = Double($0) }
                    )) {
                        ForEach(30...200, id: \.self) { weight in
                            Text("\(weight)kg").tag(weight)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("身長")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    Picker("身長", selection: Binding(
                        get: { Int(profile.height) },
                        set: { profile.height = Double($0) }
                    )) {
                        ForEach(120...220, id: \.self) { height in
                            Text("\(height)cm").tag(height)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("運動レベル")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    Picker("運動レベル", selection: $profile.activityLevel) {
                        Text("運動なし").tag(UserProfile.ActivityLevel.sedentary)
                        Text("軽い運動").tag(UserProfile.ActivityLevel.lightlyActive)
                        Text("適度な運動").tag(UserProfile.ActivityLevel.moderatelyActive)
                        Text("激しい運動").tag(UserProfile.ActivityLevel.veryActive)
                        Text("非常に激しい運動").tag(UserProfile.ActivityLevel.extraActive)
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
}

struct GoalsStepView: View {
    @Binding var profile: UserProfile
    
    var calculatedCalories: Int {
        // Basic BMR calculation using Mifflin-St Jeor Equation
        let bmr: Double
        if profile.gender == .male {
            bmr = 88.362 + (13.397 * profile.weight) + (4.799 * profile.height) - (5.677 * Double(profile.age))
        } else {
            bmr = 447.593 + (9.247 * profile.weight) + (3.098 * profile.height) - (4.330 * Double(profile.age))
        }
        
        let activityMultiplier: Double
        switch profile.activityLevel {
        case .sedentary: activityMultiplier = 1.2
        case .lightlyActive: activityMultiplier = 1.375
        case .moderatelyActive: activityMultiplier = 1.55
        case .veryActive: activityMultiplier = 1.725
        case .extraActive: activityMultiplier = 1.9
        }
        
        return Int(bmr * activityMultiplier)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("目標設定")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text("あなたの情報から推奨カロリーを算出しました")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Text("1日のカロリー目標")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    Text("\(calculatedCalories) kcal")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    Text("推奨値")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    Button("推奨値を使用") {
                        profile.dailyCalorieGoal = calculatedCalories
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black, lineWidth: 1)
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("または手動で設定:")
                        .font(.caption)
                        .foregroundColor(.black)
                    
                    HStack {
                        TextField("目標値", value: $profile.dailyCalorieGoal, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        Text("kcal")
                            .foregroundStyle(.gray)
                    }
                }
            }
            
            VStack(spacing: 12) {
                Text("栄養目標")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                VStack(spacing: 8) {
                    GoalRow(nutrient: "タンパク質", value: "\(Int(Double(profile.dailyCalorieGoal) * 0.15 / 4))g", color: .black)
                    GoalRow(nutrient: "炭水化物", value: "\(Int(Double(profile.dailyCalorieGoal) * 0.5 / 4))g", color: .black)
                    GoalRow(nutrient: "脂質", value: "\(Int(Double(profile.dailyCalorieGoal) * 0.35 / 9))g", color: .black)
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .onAppear {
            if profile.dailyCalorieGoal == 2000 {
                profile.dailyCalorieGoal = calculatedCalories
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.black)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
    }
}

struct GoalRow: View {
    let nutrient: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(nutrient)
                .font(.caption)
                .foregroundColor(.black)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}