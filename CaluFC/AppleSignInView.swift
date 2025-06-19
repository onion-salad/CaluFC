import SwiftUI
import AuthenticationServices

struct AppleSignInView: View {
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @State private var showEmailLogin = false
    
    var body: some View {
        VStack(spacing: 48) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundStyle(.black)
                
                VStack(spacing: 12) {
                    Text("Caluにようこそ")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    Text("サインインして\n栄養データを同期しましょう")
                        .font(.body)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 16) {
                // Apple Sign In ボタン（開発者アカウント必要）
                Button(action: {
                    appleSignInManager.signInWithApple()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "applelogo")
                            .font(.body)
                        Text("Appleでサインイン")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                VStack(spacing: 4) {
                    Text("⚠️ Apple Sign Inをご利用いただくには")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Text("Apple Developer Program（$99/年）への登録が必要です")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // メールでサインインボタン
                Button(action: {
                    showEmailLogin = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.body)
                        Text("メールでサインイン")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // テスト用サインインボタン（推奨）
                Button(action: {
                    appleSignInManager.saveUserSession(
                        userID: "test-user-simulator",
                        name: "テストユーザー",
                        email: "test@example.com"
                    )
                    print("✅ [AppleSignInView] Test sign in completed")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.body)
                        Text("デモ用サインイン")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.6))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                VStack(spacing: 8) {
                    Text("デモ用サインインでアプリをお試しください")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    Text("データは端末内に安全に保存されます")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                HStack(spacing: 24) {
                    PrivacyItem(icon: "lock.fill", text: "プライバシー保護")
                    PrivacyItem(icon: "icloud.fill", text: "クラウド同期")
                    PrivacyItem(icon: "checkmark.seal.fill", text: "安全")
                }
                
                Text("個人情報の保存や共有は行いません")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .sheet(isPresented: $showEmailLogin) {
            EmailSignInView()
                .environmentObject(appleSignInManager)
        }
    }
}

struct PrivacyItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.black)
            
            Text(text)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AppleSignInView()
        .environmentObject(AppleSignInManager())
}