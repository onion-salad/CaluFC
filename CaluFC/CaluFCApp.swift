//
//  CaluFCApp.swift
//  CaluFC
//
//  Created by 大塚航希 on 2025/06/19.
//

import SwiftUI

@main
struct CaluFCApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var foodAnalysisService = FoodAnalysisService.shared
    @StateObject private var appleSignInManager = AppleSignInManager()
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    
    init() {
        print("🚀 [CaluFCApp] App initializing...")
        print("   Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("   App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")")
        print("✅ [CaluFCApp] App init complete")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !isOnboardingComplete {
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                        .environmentObject(appleSignInManager)
                } else if !appleSignInManager.isSignedIn {
                    AppleSignInView()
                        .environmentObject(appleSignInManager)
                } else {
                    ContentView()
                        .environmentObject(supabaseManager)
                        .environmentObject(foodAnalysisService)
                        .environmentObject(appleSignInManager)
                }
            }
            .preferredColorScheme(.light) // 常にライトモード
            .onAppear {
                print("🏠 [CaluFCApp] App appeared")
                print("   Onboarding complete: \(isOnboardingComplete)")
                print("   Signed in: \(appleSignInManager.isSignedIn)")
                
                // 自動テストログインを試行
                if isOnboardingComplete && !appleSignInManager.isSignedIn {
                    autoSignInWithTestUser()
                }
            }
        }
    }
    
    // MARK: - Auto Sign In
    
    private func autoSignInWithTestUser() {
        Task {
            do {
                print("🔑 [CaluFCApp] Attempting auto sign-in with test user...")
                try await appleSignInManager.signInWithSupabaseEmail(
                    email: "kokimaru0502@yahoo.co.jp",
                    password: "testpass123"
                )
                print("✅ [CaluFCApp] Auto sign-in successful")
            } catch {
                print("❌ [CaluFCApp] Auto sign-in failed: \(error)")
                // サイレントに失敗、手動ログインにフォールバック
            }
        }
    }
}
