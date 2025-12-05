//
//  ContentView.swift
//  Kiro Mobile
//
//  Created by Ali Can Acar on 12/5/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var missionViewModel: MissionViewModel
    
    init() {
        let storageService = StorageService()
        let authService = AuthService()
        let settings = storageService.loadSettings()
        let token = authService.getToken()
        let apiService = APIService(baseURL: settings.backendURL, authToken: token)
        
        _missionViewModel = StateObject(wrappedValue: MissionViewModel(
            apiService: apiService,
            storageService: storageService,
            authService: authService
        ))
    }
    
    var body: some View {
        MissionListView(viewModel: missionViewModel, onLogout: nil)
            .task {
                // Request notification permissions on app launch
                _ = await NotificationService.shared.requestAuthorization()
            }
    }
}

#Preview {
    ContentView()
}
