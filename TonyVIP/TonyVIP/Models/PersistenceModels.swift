import Foundation
import SwiftData

// MARK: - PersistenceModels
//
// SwiftData @Model classes mirror the struct types used in the UI layer.
// The UI continues using the value-type structs (clean, fast, Hashable).
// These classes are the persistence layer only — read/write via PersistenceController.
//
// Strategy: offline-first.
// 1. App launches → load from SwiftData.
// 2. If store is empty → seed from SampleData.
// 3. All sends and note edits write-through to SwiftData.
// 4. CloudKit sync wires in automatically once the CloudKit container is configured.

// MARK: - PersistedMessage

@Model
final class PersistedMessage {
    @Attribute(.unique) var id: UUID
    var contactId: UUID
    var body: String
    var isFromTony: Bool
    var sentAt: Date
    var channelRaw: String   // MessageChannel.rawValue
    var isRead: Bool

    init(from message: Message) {
        self.id = message.id
        self.contactId = message.contactId
        self.body = message.body
        self.isFromTony = message.isFromTony
        self.sentAt = message.sentAt
        self.channelRaw = message.channel.rawValue
        self.isRead = message.isRead
    }

    func toStruct() -> Message {
        Message(
            id: id,
            contactId: contactId,
            body: body,
            isFromTony: isFromTony,
            sentAt: sentAt,
            channel: MessageChannel(rawValue: channelRaw) ?? .blaze,
            isRead: isRead
        )
    }
}

// MARK: - PersistedNote

@Model
final class PersistedNote {
    @Attribute(.unique) var id: UUID
    var contactId: UUID
    var body: String
    var createdAt: Date
    var isPinned: Bool

    init(contactId: UUID, from note: ContactNote) {
        self.id = note.id
        self.contactId = contactId
        self.body = note.body
        self.createdAt = note.createdAt
        self.isPinned = note.isPinned
    }

    func toStruct() -> ContactNote {
        ContactNote(id: id, body: body, createdAt: createdAt, isPinned: isPinned)
    }
}

// MARK: - PersistedRelationshipHealth

@Model
final class PersistedHealthRecord {
    @Attribute(.unique) var contactId: UUID
    var healthRaw: String          // RelationshipHealth.rawValue
    var daysSinceContact: Int?
    var updatedAt: Date

    init(contactId: UUID, health: RelationshipHealth, days: Int?) {
        self.contactId = contactId
        self.healthRaw = health.rawValue
        self.daysSinceContact = days
        self.updatedAt = .now
    }

    var health: RelationshipHealth {
        RelationshipHealth(rawValue: healthRaw) ?? .good
    }
}

// MARK: - PersistenceController

@MainActor
final class PersistenceController {

    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            PersistedMessage.self,
            PersistedNote.self,
            PersistedHealthRecord.self,
        ])

        // Use CloudKit container for cross-device sync.
        // To enable: set cloudKitContainerIdentifier to your iCloud container ID.
        // For local-only development, use ModelConfiguration(schema:) without CloudKit.
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // Uncomment for CloudKit sync:
            // cloudKitDatabase: .automatic
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var context: ModelContext { container.mainContext }

    // MARK: - Messages

    func allMessages() -> [Message] {
        let descriptor = FetchDescriptor<PersistedMessage>(
            sortBy: [SortDescriptor(\.sentAt)]
        )
        return (try? context.fetch(descriptor))?.map { $0.toStruct() } ?? []
    }

    func save(message: Message) {
        // Upsert — delete existing if present, then insert fresh.
        let id = message.id
        let descriptor = FetchDescriptor<PersistedMessage>(
            predicate: #Predicate { $0.id == id }
        )
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
        context.insert(PersistedMessage(from: message))
        try? context.save()
    }

    func markRead(messageId: UUID) {
        let descriptor = FetchDescriptor<PersistedMessage>(
            predicate: #Predicate { $0.id == messageId }
        )
        guard let record = try? context.fetch(descriptor).first else { return }
        record.isRead = true
        try? context.save()
    }

    // MARK: - Notes

    func notes(for contactId: UUID) -> [ContactNote] {
        let descriptor = FetchDescriptor<PersistedNote>(
            predicate: #Predicate { $0.contactId == contactId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.map { $0.toStruct() } ?? []
    }

    func save(note: ContactNote, for contactId: UUID) {
        let id = note.id
        let descriptor = FetchDescriptor<PersistedNote>(
            predicate: #Predicate { $0.id == id }
        )
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
        context.insert(PersistedNote(contactId: contactId, from: note))
        try? context.save()
    }

    func deleteNote(id: UUID) {
        let descriptor = FetchDescriptor<PersistedNote>(
            predicate: #Predicate { $0.id == id }
        )
        if let record = try? context.fetch(descriptor).first {
            context.delete(record)
            try? context.save()
        }
    }

    // MARK: - Health Records

    func saveHealth(_ health: RelationshipHealth, days: Int?, for contactId: UUID) {
        let descriptor = FetchDescriptor<PersistedHealthRecord>(
            predicate: #Predicate { $0.contactId == contactId }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.healthRaw = health.rawValue
            existing.daysSinceContact = days
            existing.updatedAt = .now
        } else {
            context.insert(PersistedHealthRecord(contactId: contactId, health: health, days: days))
        }
        try? context.save()
    }

    func health(for contactId: UUID) -> RelationshipHealth? {
        let descriptor = FetchDescriptor<PersistedHealthRecord>(
            predicate: #Predicate { $0.contactId == contactId }
        )
        return (try? context.fetch(descriptor).first)?.health
    }

    // MARK: - Seed

    /// Call once on first launch — populates SwiftData with SampleData messages and notes.
    func seedIfEmpty() {
        let descriptor = FetchDescriptor<PersistedMessage>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for message in SampleData.messages {
            context.insert(PersistedMessage(from: message))
        }

        for contact in SampleData.contacts {
            for note in contact.notes {
                context.insert(PersistedNote(contactId: contact.id, from: note))
            }
            context.insert(PersistedHealthRecord(
                contactId: contact.id,
                health: contact.relationshipHealth,
                days: contact.daysSinceContact
            ))
        }

        try? context.save()
    }
}
