import Foundation
import SwiftUI

// MARK: - VIP Contact

struct VIPContact: Identifiable, Hashable {
    let id: UUID
    var name: String
    var role: String
    var organization: String
    var avatarInitials: String
    var avatarColor: Color
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

struct ContactNote: Identifiable {
    let id: UUID
    var body: String
    var createdAt: Date
    var isPinned: Bool
}

// MARK: - RPM Reference

struct RPMReference: Identifiable {
    let id: UUID
    var projectName: String
    var outcome: String
    var lastUpdated: Date
    var status: RPMStatus
}

enum RPMStatus: String {
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

struct PendingItem: Identifiable {
    let id: UUID
    var title: String
    var dueDate: Date?
    var isUrgent: Bool
}

// MARK: - Blaze Context (AI-generated summary)

struct BlazeContext {
    var summary: String
    var suggestedOpener: String?
    var keyFacts: [String]
    var lastUpdated: Date
}

// MARK: - App Store

class AppStore: ObservableObject {
    @Published var contacts: [VIPContact] = SampleData.contacts
    @Published var messages: [Message] = SampleData.messages
    @Published var selectedContact: VIPContact?
    @Published var searchQuery: String = ""
    @Published var selectedTier: ContactTier? = nil
    @Published var selectedHealth: RelationshipHealth? = nil

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

    func messages(for contact: VIPContact) -> [Message] {
        messages.filter { $0.contactId == contact.id }
                .sorted { $0.sentAt < $1.sentAt }
    }

    func unreadCount(for contact: VIPContact) -> Int {
        messages(for: contact).filter { !$0.isRead && !$0.isFromTony }.count
    }

    func markAllRead(for contact: VIPContact) {
        for i in messages.indices where messages[i].contactId == contact.id {
            messages[i].isRead = true
        }
    }

    func send(text: String, to contact: VIPContact) {
        let msg = Message(
            id: UUID(), contactId: contact.id, body: text,
            isFromTony: true, sentAt: .now, channel: .blaze, isRead: true
        )
        messages.append(msg)
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
