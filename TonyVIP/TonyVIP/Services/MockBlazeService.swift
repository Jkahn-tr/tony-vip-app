import Foundation

// MARK: - MockBlazeService
//
// Realistic mock for development and testing.
// Replace with RealBlazeService once backend API contracts are defined.
// Simulated latencies match expected real-world response times.

struct MockBlazeService: BlazeServiceProtocol {

    // MARK: fetchContext

    func fetchContext(for contact: VIPContact) async throws -> BlazeContext {
        try await Task.sleep(for: .milliseconds(280)) // Simulate API round-trip
        return contact.blazeContext ?? BlazeContext(
            summary: "No Blaze context loaded for \(contact.name) yet. Blaze will generate a full summary after the first conversation.",
            suggestedOpener: "Hey \(contact.firstName) — wanted to reach out. What are you focused on right now?",
            keyFacts: [],
            lastUpdated: .now
        )
    }

    // MARK: sendMessage

    func sendMessage(_ text: String, to contact: VIPContact) async throws -> Message {
        try await Task.sleep(for: .milliseconds(120)) // Fast local delivery
        return Message(
            id: UUID(),
            contactId: contact.id,
            body: text,
            isFromTony: true,
            sentAt: .now,
            channel: .blaze,
            isRead: true
        )
    }

    // MARK: refreshHealth

    func refreshHealth(for contact: VIPContact) async throws -> RelationshipHealth {
        try await Task.sleep(for: .milliseconds(200))
        guard let days = contact.daysSinceContact else { return .good }
        switch days {
        case 0...7:   return .strong
        case 8...21:  return .good
        case 22...45: return .fading
        default:      return .cold
        }
    }

    // MARK: generateOpener

    func generateOpener(for contact: VIPContact) async throws -> String {
        try await Task.sleep(for: .milliseconds(450)) // Claude generation latency
        if let cached = contact.blazeContext?.suggestedOpener { return cached }
        return "Hey \(contact.firstName) — been meaning to reach out. What's the biggest thing you're working through right now?"
    }
}

// MARK: - VIPContact convenience

private extension VIPContact {
    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }
}
