//
//  ContentView.swift
//  Kiro Mobile
//
//  Created by Ali Can Acar on 12/5/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @State private var isAuthenticated: Bool = false
    @State private var missionViewModel: MissionViewModel?
    
    var body: some View {
        Group {
            if isAuthenticated, let viewModel = missionViewModel {
                MissionListView(viewModel: viewModel, onLogout: {
                    isAuthenticated = false
                    missionViewModel = nil
                })
                    .task {
                        // Request notification permissions on app launch
                        _ = await NotificationService.shared.requestAuthorization()
                    }
            } else {
                LoginView {
                    // Create mission view model after successful login
                    createMissionViewModel()
                    isAuthenticated = true
                }
            }
        }
        .onAppear {
            checkAuthentication()
            if isAuthenticated && missionViewModel == nil {
                createMissionViewModel()
            }
        }
    }
    
    private func checkAuthentication() {
        isAuthenticated = authService.isAuthenticated
    }
    
    private func createMissionViewModel() {
        let settings = StorageService().loadSettings()
        let token = authService.getToken()
        let apiService = APIService(baseURL: settings.backendURL, authToken: token)
        let storageService = StorageService()
        let authService = AuthService()
        
        missionViewModel = MissionViewModel(
            apiService: apiService,
            storageService: storageService,
            authService: authService
        )
    }
}

#Preview {
    ContentView()
}
