import SwiftUI

struct InboxView: View {
    @EnvironmentObject var store: AppStore
    @State private var showFilters = false

    var body: some View {
        List(store.filteredContacts, selection: $store.selectedContact) { contact in
            ContactRowView(contact: contact)
                .listRowBackground(
                    store.selectedContact?.id == contact.id
                        ? Color(hex: "1c1914")
                        : Color(hex: "0c0b09")
                )
                .listRowSeparatorTint(Color(hex: "2a2420"))
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color(hex: "0c0b09"))
        .navigationTitle("VIP Contacts")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $store.searchQuery, prompt: "Search contacts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showFilters.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle\(store.selectedTier != nil || store.selectedHealth != nil ? ".fill" : "")")
                        .foregroundStyle(
                            (store.selectedTier != nil || store.selectedHealth != nil)
                                ? Color(hex: "f59e0b") : .secondary
                        )
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet()
                .presentationDetents([.medium])
        }
        .overlay {
            if store.filteredContacts.isEmpty {
                ContentUnavailableView.search(text: store.searchQuery)
            }
        }
    }
}

// MARK: - Contact Row

struct ContactRowView: View {
    @EnvironmentObject var store: AppStore
    let contact: VIPContact

    private var unread: Int { store.unreadCount(for: contact) }
    private var lastMessage: Message? { store.messages(for: contact).last }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(contact.avatarColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(contact.avatarInitials)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(contact.avatarColor)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(contact.relationshipHealth.color.opacity(0.5), lineWidth: 2)
                    )

                // Health indicator dot
                Circle()
                    .fill(contact.relationshipHealth.color)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(Color(hex: "0c0b09"), lineWidth: 1.5))
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(contact.name)
                        .font(.system(size: 15, weight: unread > 0 ? .semibold : .regular))
                        .foregroundStyle(.primary)

                    // Tier badge
                    if contact.tier == .inner {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "f59e0b"))
                    }

                    Spacer()

                    // Time
                    if let last = lastMessage {
                        Text(last.sentAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(contact.role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack {
                    if let msg = lastMessage {
                        Text(msg.isFromTony ? "You: \(msg.body)" : msg.body)
                            .font(.caption)
                            .foregroundStyle(unread > 0 ? .primary : .tertiary)
                            .lineLimit(1)
                    } else if let pending = contact.pendingItems.first(where: { $0.isUrgent }) {
                        Label(pending.title, systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "ef4444"))
                            .lineLimit(1)
                    }

                    Spacer()

                    if unread > 0 {
                        Text("\(unread)")
                            .font(.caption2.bold())
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "f59e0b"), in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Tier") {
                    ForEach(ContactTier.allCases, id: \.self) { tier in
                        Button {
                            store.selectedTier = store.selectedTier == tier ? nil : tier
                        } label: {
                            HStack {
                                Circle()
                                    .fill(tier.badgeColor)
                                    .frame(width: 10, height: 10)
                                Text(tier.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if store.selectedTier == tier {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color(hex: "f59e0b"))
                                }
                            }
                        }
                    }
                }

                Section("Relationship Health") {
                    ForEach(RelationshipHealth.allCases, id: \.self) { health in
                        Button {
                            store.selectedHealth = store.selectedHealth == health ? nil : health
                        } label: {
                            HStack {
                                Image(systemName: health.icon)
                                    .foregroundStyle(health.color)
                                    .frame(width: 20)
                                Text(health.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if store.selectedHealth == health {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color(hex: "f59e0b"))
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Clear All Filters", role: .destructive) {
                        store.selectedTier = nil
                        store.selectedHealth = nil
                        dismiss()
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "f59e0b"))
                }
            }
        }
        .presentationBackground(Color(hex: "151310"))
    }
}
