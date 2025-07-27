//
//  AuthenticationView.swift
//  CRDO
//
//  Created by Ethan yip on 7/25/25.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.black.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 60)
                    
                    // App branding
                    VStack(spacing: 15) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gold)
                        
                        Text("CRDO")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Build your city. Build yourself.")
                            .font(.subheadline)
                            .foregroundColor(.gold)
                            .italic()
                    }
                    

                    
                    // Email/Password Authentication
                    VStack(spacing: 20) {
                        // Toggle between sign in and sign up
                        HStack(spacing: 0) {
                            Button("Sign In") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSignUp = false
                                }
                            }
                            .foregroundColor(isSignUp ? .white.opacity(0.6) : .gold)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            
                            Button("Sign Up") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSignUp = true
                                }
                            }
                            .foregroundColor(isSignUp ? .gold : .white.opacity(0.6))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        
                        // Form fields
                        VStack(spacing: 15) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(GlassTextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack {
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                            .textFieldStyle(GlassTextFieldStyle())
                                            .textContentType(.password)
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .textFieldStyle(GlassTextFieldStyle())
                                            .textContentType(.password)
                                    }
                                    
                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.gold)
                                    }
                                }
                            }
                            
                            // Confirm password field (only for sign up)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    HStack {
                                        if showConfirmPassword {
                                            TextField("Confirm your password", text: $confirmPassword)
                                                .textFieldStyle(GlassTextFieldStyle())
                                                .textContentType(.password)
                                        } else {
                                            SecureField("Confirm your password", text: $confirmPassword)
                                                .textFieldStyle(GlassTextFieldStyle())
                                                .textContentType(.password)
                                        }
                                        
                                        Button(action: {
                                            showConfirmPassword.toggle()
                                        }) {
                                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                                .foregroundColor(.gold)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Error message
                        if let errorMessage = supabaseManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // Action button
                        Button(action: {
                            Task {
                                if isSignUp {
                                    if password == confirmPassword {
                                        await supabaseManager.signUp(email: email, password: password)
                                    } else {
                                        supabaseManager.errorMessage = "Passwords don't match"
                                    }
                                } else {
                                    await supabaseManager.signIn(email: email, password: password)
                                }
                            }
                        }) {
                            HStack {
                                if supabaseManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.gold)
                            )
                        }
                        .disabled(supabaseManager.isLoading || email.isEmpty || password.isEmpty || (isSignUp && confirmPassword.isEmpty))
                        .opacity((email.isEmpty || password.isEmpty || (isSignUp && confirmPassword.isEmpty)) ? 0.6 : 1.0)
                        .padding(.horizontal, 20)
                        
                        // Forgot password (only for sign in)
                        if !isSignUp {
                            Button("Forgot Password?") {
                                // TODO: Implement forgot password functionality
                            }
                            .font(.subheadline)
                            .foregroundColor(.gold)
                            .padding(.top, 10)
                        }
                    }
                    
                    Spacer(minLength: 60)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
    }
}

#Preview {
    AuthenticationView()
} 