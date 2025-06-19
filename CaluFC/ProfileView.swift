import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @State private var profile = UserProfile(
        id: UUID(),
        name: "User",
        age: 25,
        weight: 70,
        height: 175,
        gender: .male,
        activityLevel: .moderatelyActive,
        dailyCalorieGoal: 2000
    )
    @State private var isEditingGoal = false
    @State private var tempGoal = ""
    @State private var isLoading = true
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Minimal Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.black)
                        
                        VStack(spacing: 4) {
                            Text(appleSignInManager.userName.isEmpty ? profile.name : appleSignInManager.userName)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            Text("メンバー開始: \(Date(), style: .date)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Daily Goal - Minimal
                    VStack(alignment: .leading, spacing: 16) {
                        Text("日次目標")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("カロリー目標")
                                    .font(.callout)
                                    .foregroundColor(.black)
                                Spacer()
                                if isEditingGoal {
                                    TextField("目標", text: $tempGoal)
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.numberPad)
                                        .frame(width: 80)
                                        .onSubmit {
                                            if let goal = Int(tempGoal) {
                                                profile.dailyCalorieGoal = goal
                                                Task {
                                                    await saveProfile()
                                                }
                                            }
                                            isEditingGoal = false
                                        }
                                    Text("kcal")
                                        .font(.callout)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("\(profile.dailyCalorieGoal) kcal")
                                        .font(.callout)
                                        .foregroundColor(.gray)
                                        .onTapGesture {
                                            tempGoal = String(profile.dailyCalorieGoal)
                                            isEditingGoal = true
                                        }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Personal Info - Minimal
                    VStack(alignment: .leading, spacing: 16) {
                        Text("個人情報")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        VStack(spacing: 12) {
                            MinimalProfileRow(title: "性別", value: getJapaneseGender(profile.gender))
                            MinimalProfileRow(title: "年齢", value: "\(profile.age)歳")
                            MinimalProfileRow(title: "体重", value: "\(Int(profile.weight))kg")
                            MinimalProfileRow(title: "身長", value: "\(Int(profile.height))cm")
                            MinimalProfileRow(title: "活動レベル", value: getJapaneseActivityLevel(profile.activityLevel))
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Nutrition Goals - Minimal
                    VStack(alignment: .leading, spacing: 16) {
                        Text("栄養目標")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        VStack(spacing: 8) {
                            MinimalNutritionRow(nutrient: "たんぱく質", value: "75g")
                            MinimalNutritionRow(nutrient: "炭水化物", value: "250g")
                            MinimalNutritionRow(nutrient: "脂質", value: "65g")
                            MinimalNutritionRow(nutrient: "食物繊維", value: "30g")
                            MinimalNutritionRow(nutrient: "糖質", value: "<50g")
                            MinimalNutritionRow(nutrient: "ナトリウム", value: "<2300mg")
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Settings - Minimal
                    VStack(alignment: .leading, spacing: 16) {
                        Text("設定")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        VStack(spacing: 8) {
                            MinimalToggleRow(title: "食事リマインダー")
                            MinimalToggleRow(title: "ダークモード")
                            MinimalProfileRow(title: "単位", value: "メートル法")
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Account - Minimal
                    VStack(alignment: .leading, spacing: 16) {
                        Text("アカウント")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        VStack(spacing: 12) {
                            MinimalProfileRow(
                                title: "メールアドレス", 
                                value: appleSignInManager.userEmail.isEmpty ? "未設定" : appleSignInManager.userEmail
                            )
                            
                            Button(action: {
                                showSignOutAlert = true
                            }) {
                                HStack {
                                    Text("サインアウト")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // About - Minimal
                    VStack(alignment: .leading, spacing: 16) {
                        Text("アプリ情報")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        VStack(spacing: 8) {
                            MinimalProfileRow(title: "バージョン", value: "1.0.0")
                            
                            Button(action: {}) {
                                HStack {
                                    Text("プライバシーポリシー")
                                        .font(.callout)
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            
                            Button(action: {}) {
                                HStack {
                                    Text("利用規約")
                                        .font(.callout)
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
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
                .padding(20)
            }
            .background(Color.white)
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                Task {
                    await loadProfile()
                }
            }
            .alert("サインアウト", isPresented: $showSignOutAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("サインアウト", role: .destructive) {
                    handleSignOut()
                }
            } message: {
                Text("本当にサインアウトしますか？")
            }
        }
    }
    
    private func handleSignOut() {
        Task {
            do {
                // Supabase からサインアウト（メール認証の場合）
                try await SupabaseManager.shared.signOut()
            } catch {
                print("⚠️ [ProfileView] Supabase sign out error: \(error)")
            }
            
            // ローカルセッションをクリア
            DispatchQueue.main.async {
                appleSignInManager.signOut()
                print("✅ [ProfileView] Sign out completed")
            }
        }
    }
    
    // MARK: - Supabase Integration
    
    private func loadProfile() async {
        do {
            let userId = getCurrentUserId()
            if let profileRecord = try await SupabaseManager.shared.fetchUserProfile(for: userId) {
                DispatchQueue.main.async {
                    self.profile = UserProfile(
                        id: profileRecord.id,
                        name: profileRecord.name,
                        age: profileRecord.age,
                        weight: profileRecord.weight,
                        height: profileRecord.height,
                        gender: UserProfile.Gender(rawValue: profileRecord.gender) ?? .male,
                        activityLevel: UserProfile.ActivityLevel(rawValue: profileRecord.activityLevel) ?? .moderatelyActive,
                        dailyCalorieGoal: profileRecord.dailyCalorieGoal
                    )
                    self.isLoading = false
                    print("✅ [ProfileView] Profile loaded from Supabase")
                }
            } else {
                // No profile exists, create a default one
                await createDefaultProfile()
            }
        } catch {
            print("❌ [ProfileView] Failed to load profile: \(error)")
            await createDefaultProfile()
        }
    }
    
    private func createDefaultProfile() async {
        do {
            let userId = getCurrentUserId()
            let profileRecord = UserProfileRecord(
                id: userId,
                name: "User",
                age: 25,
                weight: 70,
                height: 175,
                gender: "Male",
                activityLevel: "Moderately Active",
                dailyCalorieGoal: 2000,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await SupabaseManager.shared.saveUserProfile(profileRecord)
            
            DispatchQueue.main.async {
                self.profile = UserProfile(
                    id: userId,
                    name: "User",
                    age: 25,
                    weight: 70,
                    height: 175,
                    gender: .male,
                    activityLevel: .moderatelyActive,
                    dailyCalorieGoal: 2000
                )
                self.isLoading = false
                print("✅ [ProfileView] Default profile created and saved")
            }
        } catch {
            print("❌ [ProfileView] Failed to create default profile: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func saveProfile() async {
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
                createdAt: nil, // Will be ignored in upsert
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await SupabaseManager.shared.saveUserProfile(profileRecord)
            print("✅ [ProfileView] Profile saved to Supabase")
        } catch {
            print("❌ [ProfileView] Failed to save profile: \(error)")
        }
    }
    
    private func getCurrentUserId() -> UUID {
        return appleSignInManager.getCurrentUserId()
    }
    
    private func getJapaneseGender(_ gender: UserProfile.Gender) -> String {
        switch gender {
        case .male: return "男性"
        case .female: return "女性"
        case .other: return "その他"
        }
    }
    
    private func getJapaneseActivityLevel(_ level: UserProfile.ActivityLevel) -> String {
        switch level {
        case .sedentary: return "座りがち"
        case .lightlyActive: return "軽い運動"
        case .moderatelyActive: return "適度な運動"
        case .veryActive: return "活発"
        case .extraActive: return "非常に活発"
        }
    }
}

// MARK: - Minimal Design Components

struct MinimalProfileRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundColor(.black)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct MinimalNutritionRow: View {
    let nutrient: String
    let value: String
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.black)
                .frame(width: 3, height: 12)
            Text(nutrient)
                .font(.callout)
                .foregroundColor(.black)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct MinimalToggleRow: View {
    let title: String
    @State private var isOn = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundColor(.black)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .black))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfileView()
}