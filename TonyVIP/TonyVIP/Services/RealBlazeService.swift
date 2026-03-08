import Foundation

// MARK: - RealBlazeService
//
// Stub — wire to real backend when API contracts are ready from Bartok.
// Swap in TonyVIPApp.swift: replace MockBlazeService() with RealBlazeService(baseURL: ...)

struct RealBlazeService: BlazeServiceProtocol {

    let baseURL: URL
    let authToken: String

    private var headers: [String: String] {
        ["Authorization": "Bearer \(authToken)", "Content-Type": "application/json"]
    }

    func fetchContext(for contact: VIPContact) async throws -> BlazeContext {
        // TODO: GET \(baseURL)/contacts/\(contact.id)/context
        throw BlazeServiceError.networkUnavailable
    }

    func sendMessage(_ text: String, to contact: VIPContact) async throws -> Message {
        // TODO: POST \(baseURL)/contacts/\(contact.id)/messages { body: text }
        throw BlazeServiceError.networkUnavailable
    }

    func refreshHealth(for contact: VIPContact) async throws -> RelationshipHealth {
        // TODO: GET \(baseURL)/contacts/\(contact.id)/health
        throw BlazeServiceError.networkUnavailable
    }

    func generateOpener(for contact: VIPContact) async throws -> String {
        // TODO: POST \(baseURL)/contacts/\(contact.id)/opener
        throw BlazeServiceError.networkUnavailable
    }
}
