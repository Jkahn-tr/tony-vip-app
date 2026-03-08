import Foundation

// MARK: - BlazeServiceProtocol
//
// Swap MockBlazeService → RealBlazeService when backend endpoints are ready.
// All UI code depends on this protocol only — never on the concrete type.

protocol BlazeServiceProtocol: Sendable {

    /// Fetch or refresh the AI context card for a contact.
    func fetchContext(for contact: VIPContact) async throws -> BlazeContext

    /// Send a message via the Blaze channel and return the persisted Message.
    func sendMessage(_ text: String, to contact: VIPContact) async throws -> Message

    /// Recalculate relationship health based on recency + engagement signals.
    func refreshHealth(for contact: VIPContact) async throws -> RelationshipHealth

    /// Generate a fresh suggested opener using latest context.
    func generateOpener(for contact: VIPContact) async throws -> String
}

// MARK: - BlazeServiceError

enum BlazeServiceError: LocalizedError {
    case networkUnavailable
    case contactNotFound(UUID)
    case generationFailed(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Blaze is offline. Showing cached context."
        case .contactNotFound(let id):
            return "Contact \(id) not found in Blaze."
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        case .unauthorized:
            return "Blaze authentication required."
        }
    }
}
