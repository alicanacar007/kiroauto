//
//  APIService.swift
//  Kiro Mobile
//
//  Created by Kiro on 12/5/25.
//

import Foundation

protocol APIServiceProtocol {
    func login(username: String, password: String) async throws -> LoginResponse
    func createMission(user: String, prompt: String, repoPath: String, macId: String) async throws -> MissionCreateResponse
    func getMission(id: String) async throws -> Mission
    func getNextStep(missionId: String, macId: String) async throws -> Step?
    func getAllSteps(missionId: String) async throws -> Plan
    func postEvent(missionId: String, event: EventRequest) async throws -> EventResponse
    func deleteMission(id: String) async throws
}

class APIService: APIServiceProtocol {
    private let baseURL: String
    private let session: URLSession
    private var authToken: String?
    
    init(baseURL: String, authToken: String? = nil) {
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.authToken = authToken
    }
    
    private func addAuthHeaders(to request: inout URLRequest) {
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    func login(username: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = LoginRequest(username: username, password: password)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(LoginResponse.self, from: data)
    }
    
    func createMission(user: String, prompt: String, repoPath: String, macId: String) async throws -> MissionCreateResponse {
        let url = URL(string: "\(baseURL)/missions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(to: &request)
        
        let body = MissionCreateRequest(user: user, prompt: prompt, repoPath: repoPath, macId: macId)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MissionCreateResponse.self, from: data)
    }

    
    func getMission(id: String) async throws -> Mission {
        let url = URL(string: "\(baseURL)/missions/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeaders(to: &request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Mission.self, from: data)
    }
    
    func getNextStep(missionId: String, macId: String) async throws -> Step? {
        let url = URL(string: "\(baseURL)/missions/\(missionId)/next_step?mac_id=\(macId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeaders(to: &request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Step.self, from: data)
    }
    
    func getAllSteps(missionId: String) async throws -> Plan {
        let url = URL(string: "\(baseURL)/missions/\(missionId)/steps")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeaders(to: &request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Plan.self, from: data)
    }
    
    func postEvent(missionId: String, event: EventRequest) async throws -> EventResponse {
        let url = URL(string: "\(baseURL)/missions/\(missionId)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(to: &request)
        
        request.httpBody = try JSONEncoder().encode(event)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(EventResponse.self, from: data)
    }
    
    func deleteMission(id: String) async throws {
        let url = URL(string: "\(baseURL)/missions/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addAuthHeaders(to: &request)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
