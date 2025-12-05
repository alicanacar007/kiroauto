//
//  AuthService.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation
import Security
import Combine
import SwiftUI

protocol AuthServiceProtocol {
    func saveUsername(_ username: String)
    func getUsername() -> String?
    func saveCredentials(username: String, password: String, rememberMe: Bool)
    func getCredentials() -> UserCredentials?
    func saveToken(_ token: String)
    func getToken() -> String?
    func logout()
    var isAuthenticated: Bool { get }
    var requiresLogin: Bool { get }
}

class AuthService: ObservableObject, AuthServiceProtocol {
    private let keychainKey = "kiro_username"
    private let credentialsKey = "kiro_credentials"
    private let tokenKey = "kiro_auth_token"
    private let service = "com.kiro.mobile"
    
    // Set to true to require login, false to allow username-only mode
    var requiresLogin: Bool {
        // Can be made configurable via UserDefaults or settings
        return UserDefaults.standard.bool(forKey: "kiro_requires_login")
    }
    
    var isAuthenticated: Bool {
        if requiresLogin {
            return getToken() != nil || getCredentials() != nil
        } else {
            return getUsername() != nil
        }
    }
    
    func saveUsername(_ username: String) {
        let data = Data(username.utf8)
        
        // Delete any existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    func getUsername() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let username = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return username
    }
    
    func saveCredentials(username: String, password: String, rememberMe: Bool) {
        // Save username separately for easy access
        saveUsername(username)
        
        // Save credentials securely in keychain
        let credentials = UserCredentials(username: username, password: password, rememberMe: rememberMe)
        
        guard let data = try? JSONEncoder().encode(credentials) else {
            return
        }
        
        // Delete any existing credentials
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentialsKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new credentials
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentialsKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: rememberMe ? kSecAttrAccessibleWhenUnlocked : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    func getCredentials() -> UserCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentialsKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONDecoder().decode(UserCredentials.self, from: data) else {
            return nil
        }
        
        return credentials
    }
    
    func saveToken(_ token: String) {
        let data = Data(token.utf8)
        
        // Delete any existing token
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new token
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func logout() {
        // Delete username
        let usernameQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(usernameQuery as CFDictionary)
        
        // Delete credentials
        let credentialsQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentialsKey
        ]
        SecItemDelete(credentialsQuery as CFDictionary)
        
        // Delete token
        let tokenQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(tokenQuery as CFDictionary)
    }
}
