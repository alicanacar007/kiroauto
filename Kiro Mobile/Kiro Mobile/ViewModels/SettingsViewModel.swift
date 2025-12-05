//
//  SettingsViewModel.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var username: String
    @Published var isAuthenticated: Bool
    
    private let storageService: StorageServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(
        storageService: StorageServiceProtocol,
        authService: AuthServiceProtocol
    ) {
        self.storageService = storageService
        self.authService = authService
        self.settings = storageService.loadSettings()
        self.username = authService.getUsername() ?? ""
        self.isAuthenticated = authService.isAuthenticated
    }
    
    func saveSettings() {
        storageService.saveSettings(settings)
    }
    
    func saveUsername() {
        guard !username.isEmpty else { return }
        authService.saveUsername(username)
        isAuthenticated = authService.isAuthenticated
    }
    
    func logout() {
        authService.logout()
        username = ""
        isAuthenticated = false
    }
}



