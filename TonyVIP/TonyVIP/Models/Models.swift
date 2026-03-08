import Foundation
import SwiftUI

// MARK: - VIP Contact

struct VIPContact: Identifiable, Hashable, Equatable {
    let id: UUID
    var name: String
    var role: String
    var organization: String
    var avatarInitials: String
    var avatarColorHex: String          // store as hex, compute Color on use
    var avatarColor: Color { Color(hex: avatarColorHex) }
    var phone: String?
    var email: String?
    var relationshipHealth: RelationshipHealth
    var tier: ContactTier
    var lastContactedAt: Date?
    var notes: [ContactNote]
    var rpmProjects: [RPMReference]
    var pendingItems: [PendingItem]
    var tags: [String]
    var blazeContext: BlazeContext?

    var daysSinceContact: Int? {
        guard let last = lastContactedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: .now).day
    }

    // Manual Hashable — hash on id only
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: VIPContact, rhs: VIPContact) -> Bool { lhs.id == rhs.id }
}

enum RelationshipHealth: String, CaseIterable {
    case strong   = "Strong"
    case good     = "Good"
    case fading   = "Fading"
    case cold     = "Cold"

    var color: Color {
        switch self {
        case .strong: return Color(hex: "10b981")
        case .good:   return Color(hex: "60a5fa")
        case .fading: return Color(hex: "f59e0b")
        case .cold:   return Color(hex: "ef4444")
        }
    }

    var icon: String {
        switch self {
        case .strong: return "flame.fill"
        case .good:   return "checkmark.circle.fill"
        case .fading: return "clock.fill"
        case .cold:   return "snowflake"
        }
    }
}

enum ContactTier: String, CaseIterable {
    case inner    = "Inner Circle"
    case vip      = "VIP"
    case key      = "Key Contact"

    var badgeColor: Color {
        switch self {
        case .inner: return Color(hex: "f59e0b")
        case .vip:   return Color(hex: "a78bfa")
        case .key:   return Color(hex: "60a5fa")
        }
    }
}

// MARK: - Message

struct Message: Identifiable {
    let id: UUID
    var contactId: UUID
    var body: String
    var isFromTony: Bool
    var sentAt: Date
    var channel: MessageChannel
    var isRead: Bool
}

enum MessageChannel: String {
    case blaze   = "Blaze"
    case sms     = "SMS"
    case email   = "Email"

    var icon: String {
        switch self {
        case .blaze: return "flame.fill"
        case .sms:   return "message.fill"
        case .email: return "envelope.fill"
        }
    }
}

// MARK: - Contact Note

struct ContactNote: Identifiable, Hashable, Equatable {
    let id: UUID
    var body: String
    var createdAt: Date
    var isPinned: Bool
}

// MARK: - RPM Reference

struct RPMReference: Identifiable, Hashable, Equatable {
    let id: UUID
    var projectName: String
    var outcome: String
    var lastUpdated: Date
    var status: RPMStatus
}

enum RPMStatus: String, Hashable {
    case active    = "Active"
    case pending   = "Pending"
    case complete  = "Complete"

    var color: Color {
        switch self {
        case .active:   return Color(hex: "10b981")
        case .pending:  return Color(hex: "f59e0b")
        case .complete: return Color(hex: "60a5fa")
        }
    }
}

// MARK: - Pending Item

struct PendingItem: Identifiable, Hashable, Equatable {
    let id: UUID
    var title: String
    var dueDate: Date?
    var isUrgent: Bool
}

// MARK: - Blaze Context (AI-generated summary)

struct BlazeContext: Hashable, Equatable {
    var summary: String
    var suggestedOpener: String?
    var keyFacts: [String]
    var lastUpdated: Date
}

// MARK: - App Store

@MainActor
class AppStore: ObservableObject {

    // MARK: Published state
    @Published var contacts: [VIPContact] = SampleData.contacts
    @Published var messages: [Message] = []
    @Published var selectedContact: VIPContact?
    @Published var searchQuery: String = ""
    @Published var selectedTier: ContactTier? = nil
    @Published var selectedHealth: RelationshipHealth? = nil
    @Published var isSendingMessage: Bool = false
    @Published var blazeError: String? = nil

    // MARK: Services — swap MockBlazeService → RealBlazeService when ready
    private let blazeService: any BlazeServiceProtocol
    private let persistence: PersistenceController

    init(
        blazeService: any BlazeServiceProtocol = MockBlazeService(),
        persistence: PersistenceController = .shared
    ) {
        self.blazeService = blazeService
        self.persistence = persistence
        bootstrap()
    }

    // MARK: Bootstrap — seed + load persisted data

    private func bootstrap() {
        persistence.seedIfEmpty()
        messages = persistence.allMessages()

        // Hydrate persisted relationship health overrides
        for i in contacts.indices {
            if let health = persistence.health(for: contacts[i].id) {
                contacts[i].relationshipHealth = health
            }
            // Hydrate persisted notes
            let persistedNotes = persistence.notes(for: contacts[i].id)
            if !persistedNotes.isEmpty {
                contacts[i].notes = persistedNotes
            }
        }
    }

    // MARK: Filtering

    var filteredContacts: [VIPContact] {
        var list = contacts
        if !searchQuery.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.organization.localizedCaseInsensitiveContains(searchQuery) ||
                $0.role.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        if let tier = selectedTier   { list = list.filter { $0.tier == tier } }
        if let h    = selectedHealth { list = list.filter { $0.relationshipHealth == h } }
        return list.sorted { ($0.lastContactedAt ?? .distantPast) > ($1.lastContactedAt ?? .distantPast) }
    }

    // MARK: Message helpers

    func messages(for contact: VIPContact) -> [Message] {
        messages.filter { $0.contactId == contact.id }
                .sorted { $0.sentAt < $1.sentAt }
    }

    func unreadCount(for contact: VIPContact) -> Int {
        messages(for: contact).filter { !$0.isRead && !$0.isFromTony }.count
    }

    func markAllRead(for contact: VIPContact) {
        for i in messages.indices where messages[i].contactId == contact.id {
            if !messages[i].isRead {
                messages[i].isRead = true
                persistence.markRead(messageId: messages[i].id)
            }
        }
    }

    // MARK: Send — async, Blaze-backed, persisted

    func send(text: String, to contact: VIPContact) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSendingMessage = true
        blazeError = nil

        Task {
            do {
                let msg = try await blazeService.sendMessage(trimmed, to: contact)
                messages.append(msg)
                persistence.save(message: msg)
            } catch {
                // Fallback: insert locally even if Blaze is down
                let fallback = Message(
                    id: UUID(), contactId: contact.id, body: trimmed,
                    isFromTony: true, sentAt: .now, channel: .blaze, isRead: true
                )
                messages.append(fallback)
                persistence.save(message: fallback)
                blazeError = error.localizedDescription
            }
            isSendingMessage = false
        }
    }

    // MARK: Refresh relationship health via Blaze

    func refreshHealth(for contact: VIPContact) {
        guard let idx = contacts.firstIndex(of: contact) else { return }
        Task {
            do {
                let health = try await blazeService.refreshHealth(for: contact)
                contacts[idx].relationshipHealth = health
                persistence.saveHealth(health, days: contact.daysSinceContact, for: contact.id)
            } catch {
                blazeError = error.localizedDescription
            }
        }
    }

    // MARK: Notes — write-through to SwiftData

    func addNote(_ body: String, to contact: VIPContact, pinned: Bool = false) {
        guard let idx = contacts.firstIndex(of: contact) else { return }
        let note = ContactNote(id: UUID(), body: body, createdAt: .now, isPinned: pinned)
        contacts[idx].notes.insert(note, at: 0)
        persistence.save(note: note, for: contact.id)
    }

    func deleteNote(_ note: ContactNote, from contact: VIPContact) {
        guard let idx = contacts.firstIndex(of: contact) else { return }
        contacts[idx].notes.removeAll { $0.id == note.id }
        persistence.deleteNote(id: note.id)
    }

    func togglePin(_ note: ContactNote, for contact: VIPContact) {
        guard let cIdx = contacts.firstIndex(of: contact),
              let nIdx = contacts[cIdx].notes.firstIndex(of: note) else { return }
        contacts[cIdx].notes[nIdx].isPinned.toggle()
        let updated = contacts[cIdx].notes[nIdx]
        persistence.save(note: updated, for: contact.id)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3: (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
