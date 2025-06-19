import Foundation
import AuthenticationServices
import SwiftUI
import Supabase

class AppleSignInManager: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var userID = ""
    @Published var userName = ""
    @Published var userEmail = ""
    
    override init() {
        super.init()
        checkSignInStatus()
    }
    
    func signInWithApple() {
        print("🍎 [AppleSignInManager] Starting Apple Sign In...")
        
        // シミュレーターでの制限をチェック
        #if targetEnvironment(simulator)
        print("⚠️ [AppleSignInManager] Running on simulator - Apple Sign In may not work properly")
        #endif
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        print("🍎 [AppleSignInManager] Performing authorization request...")
        authorizationController.performRequests()
    }
    
    func signOut() {
        isSignedIn = false
        userID = ""
        userName = ""
        userEmail = ""
        
        // Clear stored credentials
        UserDefaults.standard.removeObject(forKey: "apple_user_id")
        UserDefaults.standard.removeObject(forKey: "apple_user_name")
        UserDefaults.standard.removeObject(forKey: "apple_user_email")
        
        print("🔓 [AppleSignInManager] User signed out")
    }
    
    private func checkSignInStatus() {
        if let savedUserID = UserDefaults.standard.string(forKey: "apple_user_id") {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: savedUserID) { [weak self] (credentialState, error) in
                DispatchQueue.main.async {
                    switch credentialState {
                    case .authorized:
                        print("✅ [AppleSignInManager] User is still authorized")
                        self?.restoreUserSession(userID: savedUserID)
                    case .revoked, .notFound:
                        print("❌ [AppleSignInManager] User authorization revoked or not found")
                        self?.signOut()
                    default:
                        print("⚠️ [AppleSignInManager] Unknown credential state")
                        break
                    }
                }
            }
        }
    }
    
    private func restoreUserSession(userID: String) {
        self.userID = userID
        self.userName = UserDefaults.standard.string(forKey: "apple_user_name") ?? ""
        self.userEmail = UserDefaults.standard.string(forKey: "apple_user_email") ?? ""
        self.isSignedIn = true
        print("🔄 [AppleSignInManager] User session restored for ID: \(userID)")
    }
    
    func saveUserSession(userID: String, name: String, email: String) {
        UserDefaults.standard.set(userID, forKey: "apple_user_id")
        UserDefaults.standard.set(name, forKey: "apple_user_name")
        UserDefaults.standard.set(email, forKey: "apple_user_email")
        
        self.userID = userID
        self.userName = name
        self.userEmail = email
        self.isSignedIn = true
        
        print("💾 [AppleSignInManager] User session saved: \(userID)")
    }
    
    func getCurrentUserId() -> UUID {
        if isSignedIn, !userID.isEmpty {
            // For email auth, use the actual Supabase auth user ID
            return UUID(uuidString: userID) ?? UUID()
        } else {
            // Use the known test user ID for now
            return UUID(uuidString: "759756ff-9c28-4764-b2d7-5ba04f1bef5b") ?? UUID()
        }
    }
    
    // MARK: - Email Authentication Integration
    
    func signInWithSupabaseEmail(email: String, password: String) async throws {
        do {
            let session = try await SupabaseManager.shared.signInWithEmail(
                email: email,
                password: password,
                isSignUp: false
            )
            
            DispatchQueue.main.async {
                self.saveUserSession(
                    userID: session.user.id.uuidString,
                    name: email.components(separatedBy: "@").first ?? "ユーザー",
                    email: email
                )
                print("✅ [AppleSignInManager] Email authentication successful")
            }
        } catch {
            print("❌ [AppleSignInManager] Email authentication failed: \(error)")
            throw error
        }
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            let identityToken = appleIDCredential.identityToken
            
            let name = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            print("✅ [AppleSignInManager] Apple sign in credential received")
            print("   User ID: \(userID)")
            print("   Name: \(name)")
            print("   Email: \(email ?? "Not provided")")
            
            guard let identityToken = identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8) else {
                print("❌ [AppleSignInManager] Unable to get identity token")
                return
            }
            
            // For testing without Supabase Auth integration, just use local storage
            DispatchQueue.main.async {
                self.saveUserSession(
                    userID: userID,
                    name: name.isEmpty ? "ユーザー" : name,
                    email: email ?? ""
                )
                print("✅ [AppleSignInManager] Local sign in completed successfully")
            }
            
            // TODO: Integrate with Supabase Auth using signInWithIdToken
            // This would require proper Supabase Apple provider configuration
            /*
            Task {
                do {
                    let session = try await SupabaseManager.shared.supabase.auth.signInWithIdToken(
                        credentials: .init(
                            provider: .apple,
                            idToken: idTokenString
                        )
                    )
                    
                    DispatchQueue.main.async {
                        self.isSignedIn = true
                        print("✅ [AppleSignInManager] Supabase sign in successful")
                    }
                } catch {
                    print("❌ [AppleSignInManager] Supabase sign in failed: \(error)")
                    // Fallback to local storage
                    DispatchQueue.main.async {
                        self.saveUserSession(userID: userID, name: name, email: email ?? "")
                    }
                }
            }
            */
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = error as? ASAuthorizationError
        
        print("❌ [AppleSignInManager] Authorization error occurred")
        print("   Error domain: \(error.localizedDescription)")
        print("   Error code: \((error as NSError).code)")
        
        switch authError?.code {
        case .canceled:
            print("ℹ️ [AppleSignInManager] User canceled sign in")
        case .failed:
            print("❌ [AppleSignInManager] Authorization failed - this is common on simulator")
            #if targetEnvironment(simulator)
            print("💡 [AppleSignInManager] Use the test sign in button for simulator testing")
            #endif
        case .invalidResponse:
            print("❌ [AppleSignInManager] Invalid response")
        case .notHandled:
            print("❌ [AppleSignInManager] Not handled")
        case .unknown:
            print("❌ [AppleSignInManager] Unknown error")
        default:
            print("❌ [AppleSignInManager] Sign in failed: \(error)")
            #if targetEnvironment(simulator)
            print("💡 [AppleSignInManager] Apple Sign In typically doesn't work on simulator")
            print("   Please use the test sign in button or test on a real device")
            #endif
        }
    }
}

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

struct AppleSignInButton: UIViewRepresentable {
    @ObservedObject var signInManager: AppleSignInManager
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: type, authorizationButtonStyle: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleSignIn), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(signInManager: signInManager)
    }
    
    class Coordinator: NSObject {
        let signInManager: AppleSignInManager
        
        init(signInManager: AppleSignInManager) {
            self.signInManager = signInManager
        }
        
        @objc func handleSignIn() {
            signInManager.signInWithApple()
        }
    }
}