import Foundation

// MARK: - RealBlazeService
//
// Live implementation backed by Supabase Edge Functions.
// Base URL: https://blaze-api.supabase.co/functions/v1
//
// Auth flow:
//   Phase 1: Static service token stored in iOS Keychain (BlazeKeychain.token)
//   Phase 2: Supabase Auth + Apple Sign-In with auto-refresh tokens
//
// To activate: swap MockBlazeService() → RealBlazeService() in TonyVIPApp.swift

struct RealBlazeService: BlazeServiceProtocol {

    private let baseURL = URL(string: "https://blaze-api.supabase.co/functions/v1")!
    private let token: String

    // For dev/testing — replace with Keychain read in production
    init(token: String = BlazeKeychain.serviceToken) {
        self.token = token
    }

    private var authHeaders: [String: String] {
        ["Authorization": "Bearer \(token)", "Content-Type": "application/json"]
    }

    // MARK: - fetchContext

    func fetchContext(for contact: VIPContact) async throws -> BlazeContext {
        let url = baseURL.appendingPathComponent("contacts/\(contact.id)/context")
        let data = try await get(url)
        let raw = try JSONDecoder.blaze.decode(ContextResponse.self, from: data)
        return BlazeContext(
            summary: raw.summary,
            suggestedOpener: raw.suggested_opener,
            keyFacts: raw.key_facts,
            lastUpdated: raw.last_updated
        )
    }

    // MARK: - sendMessage

    func sendMessage(_ text: String, to contact: VIPContact) async throws -> Message {
        let url = baseURL.appendingPathComponent("messages/send")
        let body: [String: Any] = [
            "contact_id": contact.id.uuidString,
            "body": text,
            "channel": "blaze"
        ]
        let data = try await post(url, body: body)
        let raw = try JSONDecoder.blaze.decode(MessageResponse.self, from: data)
        return Message(
            id: raw.id,
            contactId: raw.contact_id,
            body: raw.body,
            isFromTony: raw.is_from_tony,
            sentAt: raw.sent_at,
            channel: MessageChannel(rawValue: raw.channel) ?? .blaze,
            isRead: raw.is_read
        )
    }

    // MARK: - refreshHealth

    func refreshHealth(for contact: VIPContact) async throws -> RelationshipHealth {
        let url = baseURL.appendingPathComponent("contacts/\(contact.id)/health")
        let data = try await get(url)
        let raw = try JSONDecoder.blaze.decode(HealthResponse.self, from: data)
        return RelationshipHealth(rawValue: raw.health) ?? .good
    }

    // MARK: - generateOpener

    func generateOpener(for contact: VIPContact) async throws -> String {
        let url = baseURL.appendingPathComponent("contacts/\(contact.id)/opener/generate")
        let data = try await post(url, body: ["hint": NSNull()])
        let raw = try JSONDecoder.blaze.decode(OpenerResponse.self, from: data)
        return raw.opener
    }

    // MARK: - HTTP helpers

    private func get(_ url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        authHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: data)
        return data
    }

    private func post(_ url: URL, body: [String: Any]) async throws -> Data {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        authHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: data)
        return data
    }

    private func patch(_ url: URL, body: [String: Any]) async throws -> Data {
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        authHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: data)
        return data
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw BlazeServiceError.networkUnavailable
        }
        switch http.statusCode {
        case 200...299: return
        case 401: throw BlazeServiceError.unauthorized
        case 404: throw BlazeServiceError.contactNotFound(UUID())
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw BlazeServiceError.generationFailed("HTTP \(http.statusCode): \(msg)")
        }
    }
}

// MARK: - Response DTOs

private struct ContextResponse: Decodable {
    let summary: String
    let suggested_opener: String?
    let key_facts: [String]
    let last_updated: Date
}

private struct MessageResponse: Decodable {
    let id: UUID
    let contact_id: UUID
    let body: String
    let is_from_tony: Bool
    let sent_at: Date
    let channel: String
    let is_read: Bool
}

private struct HealthResponse: Decodable {
    let contact_id: UUID
    let health: String
    let score: Double
    let days_since_contact: Int?
    let alert_threshold_reached: Bool
}

private struct OpenerResponse: Decodable {
    let opener: String
    let generated_at: Date
}

// MARK: - JSONDecoder convenience

private extension JSONDecoder {
    static let blaze: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

// MARK: - BlazeKeychain

enum BlazeKeychain {
    // Phase 1: service token for dev — replace with Keychain read
    // Generate in Supabase dashboard → Settings → API → service_role key
    static let serviceToken: String = "REPLACE_WITH_SUPABASE_SERVICE_TOKEN"

    // TODO Phase 2: read/write from iOS Keychain
    // static func read() -> String? { ... }
    // static func store(_ token: String) { ... }
}
