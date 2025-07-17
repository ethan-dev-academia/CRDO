import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AuthView: View {
    // @AppStorage("signedInUserID") private var signedInUserID: String = ""
    // @State private var customUserID: String = ""
    // @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Sign In or Sign Up")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            // Removed Google Sign-In Button
            
            // Sign in with Apple
//            SignInWithAppleButton(
//                .signIn,
//                onRequest: { request in
//                    request.requestedScopes = [.fullName, .email]
//                },
//                onCompletion: handleAppleSignIn
//            )
//            .signInWithAppleButtonStyle(.black)
//            .frame(height: 50)
//            .cornerRadius(10)
//            .padding(.horizontal, 40)
            
            Text("or")
                .foregroundColor(.gray)
                .font(.headline)
            
            // Custom User ID
//            VStack(spacing: 12) {
//                TextField("Enter a custom user ID", text: $customUserID)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .padding(.horizontal, 40)
//                Button(action: {
//                    if customUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                        errorMessage = "User ID cannot be empty."
//                    } else {
//                        Auth.auth().signInAnonymously { (authResult, error) in
//                            if let error = error {
//                                errorMessage = error.localizedDescription
//                                return
//                            }
//                            if let user = authResult?.user {
//                                signedInUserID = customUserID.trimmingCharacters(in: .whitespacesAndNewlines)
//                                let changeRequest = user.createProfileChangeRequest()
//                                changeRequest.displayName = customUserID
//                                changeRequest.commitChanges(completion: nil)
//                            }
//                        }
//                    }
//                }) {
//                    Text("Continue")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.blue)
//                        .cornerRadius(10)
//                        .padding(.horizontal, 40)
//                }
//            }
            
//            if let error = errorMessage {
//                Text(error)
//                    .foregroundColor(.red)
//                    .padding(.top, 8)
//            }
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
//    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
//        switch result {
//        case .success(let auth):
//            if let credential = auth.credential as? ASAuthorizationAppleIDCredential,
//               let appleIDToken = credential.identityToken,
//               let idTokenString = String(data: appleIDToken, encoding: .utf8) {
//                let firebaseCredential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: "", fullName: credential.fullName)
//                Auth.auth().signIn(with: firebaseCredential) { (authResult, error) in
//                    if let error = error {
//                        errorMessage = error.localizedDescription
//                        return
//                    }
//                    if let user = authResult?.user {
//                        signedInUserID = user.uid
//                    }
//                }
//            }
//        case .failure(let error):
//            errorMessage = error.localizedDescription
//        }
//    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
} 
