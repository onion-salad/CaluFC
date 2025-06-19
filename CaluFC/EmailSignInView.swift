import SwiftUI

struct EmailSignInView: View {
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 24) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.black)
                    
                    VStack(spacing: 12) {
                        Text(isSignUp ? "新規登録" : "メールでサインイン")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        Text("メールアドレスとパスワードを入力してください")
                            .font(.body)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        TextField("メールアドレス", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        SecureField("パスワード", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        handleSignIn()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "登録" : "サインイン")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(8)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    .padding(.horizontal)
                    
                    Button(action: {
                        isSignUp.toggle()
                    }) {
                        Text(isSignUp ? "既にアカウントをお持ちですか？ サインイン" : "アカウントをお持ちでない方はこちら 新規登録")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleSignIn() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let session = try await SupabaseManager.shared.signInWithEmail(
                    email: email,
                    password: password,
                    isSignUp: isSignUp
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    // サインイン成功
                    let displayName = session.user.email?.components(separatedBy: "@").first ?? "ユーザー"
                    
                    self.appleSignInManager.saveUserSession(
                        userID: session.user.id.uuidString,
                        name: displayName,
                        email: session.user.email ?? ""
                    )
                    
                    print("✅ [EmailSignInView] Email sign in successful")
                    self.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    print("❌ [EmailSignInView] Email sign in failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    EmailSignInView()
        .environmentObject(AppleSignInManager())
}