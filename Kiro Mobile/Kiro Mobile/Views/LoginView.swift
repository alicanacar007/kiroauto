//
//  LoginView.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var storageService = StorageService()
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = true
    @State private var isLoggingIn: Bool = false
    @State private var errorMessage: String?
    @State private var showPassword: Bool = false
    
    var onLoginSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo/App Name
            VStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("Kiro Mobile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Mission Control")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            
            // Login Form
            VStack(spacing: 20) {
                // Username Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter your username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        if showPassword {
                            TextField("Enter your password", text: $password)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Enter your password", text: $password)
                        }
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }
                
                // Remember Me
                Toggle("Remember me", isOn: $rememberMe)
                    .font(.subheadline)
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Login Button
                Button {
                    Task {
                        await login()
                    }
                } label: {
                    HStack {
                        if isLoggingIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(username.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(username.isEmpty || password.isEmpty || isLoggingIn)
                
                // Skip Login (if login is optional)
                if !authService.requiresLogin {
                    Button {
                        // Allow username-only mode
                        if !username.isEmpty {
                            authService.saveUsername(username)
                            onLoginSuccess()
                        }
                    } label: {
                        Text("Continue without password")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(username.isEmpty)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Pre-fill credentials if available
            if let savedCredentials = authService.getCredentials() {
                username = savedCredentials.username
                // Only auto-fill password if rememberMe was enabled
                if savedCredentials.rememberMe {
                    password = savedCredentials.password
                    rememberMe = true
                } else {
                    rememberMe = false
                }
            } else if let savedUsername = authService.getUsername() {
                // Fallback to just username if no full credentials exist
                username = savedUsername
            }
        }
    }
    
    private func login() async {
        isLoggingIn = true
        errorMessage = nil
        
        let settings = storageService.loadSettings()
        
        do {
            // Try to login via API
            let apiService = APIService(baseURL: settings.backendURL)
            let response = try await apiService.login(username: username, password: password)
            
            if response.success {
                // Save credentials
                authService.saveCredentials(
                    username: username,
                    password: password,
                    rememberMe: rememberMe
                )
                
                // Save token if provided
                if let token = response.token {
                    authService.saveToken(token)
                }
                
                isLoggingIn = false
                onLoginSuccess()
            } else {
                errorMessage = response.message ?? "Login failed"
                isLoggingIn = false
            }
        } catch {
            // If backend doesn't have auth endpoint yet, use local auth
            if let apiError = error as? APIError,
               case .httpError(let statusCode) = apiError,
               statusCode == 404 {
                // Backend doesn't have auth endpoint - use local storage
                authService.saveCredentials(
                    username: username,
                    password: password,
                    rememberMe: rememberMe
                )
                isLoggingIn = false
                onLoginSuccess()
            } else {
                errorMessage = "Login failed: \(error.localizedDescription)"
                isLoggingIn = false
            }
        }
    }
}


