//
//  SettingsView.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var requiresLogin: Bool = UserDefaults.standard.bool(forKey: "kiro_requires_login")
    @State private var showLogoutConfirmation = false
    var onLogout: (() -> Void)?
    
    init(onLogout: (() -> Void)? = nil) {
        self.onLogout = onLogout
        let storageService = StorageService()
        let authService = AuthService()
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            storageService: storageService,
            authService: authService
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Authentication")) {
                    TextField("Username", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button {
                        viewModel.saveUsername()
                    } label: {
                        Text("Save Username")
                    }
                    .disabled(viewModel.username.isEmpty)
                    
                    Toggle("Require Login", isOn: $requiresLogin)
                        .onChange(of: requiresLogin) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "kiro_requires_login")
                        }
                    
                    if viewModel.isAuthenticated {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Authenticated")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Backend Configuration")) {
                    TextField("Backend URL", text: $viewModel.settings.backendURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    TextField("Mac ID", text: $viewModel.settings.macId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button {
                        viewModel.saveSettings()
                    } label: {
                        Text("Save Settings")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        Text("Logout")
                    }
                    .disabled(!viewModel.isAuthenticated)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    viewModel.logout()
                    dismiss()
                    onLogout?()
                }
            } message: {
                Text("Are you sure you want to logout? You'll need to login again to access missions.")
            }
        }
    }
}

