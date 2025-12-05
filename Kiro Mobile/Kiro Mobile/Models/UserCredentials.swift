//
//  UserCredentials.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation

struct UserCredentials: Codable {
    let username: String
    let password: String
    let rememberMe: Bool
    
    enum CodingKeys: String, CodingKey {
        case username
        case password
        case rememberMe = "remember_me"
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case password
    }
}

struct LoginResponse: Codable {
    let success: Bool
    let token: String?
    let user: UserInfo?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case token
        case user
        case message
    }
}

struct UserInfo: Codable {
    let username: String
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case email
    }
}



