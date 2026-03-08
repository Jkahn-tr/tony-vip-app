import SwiftUI

struct ContactDetailView: View {
    @EnvironmentObject var store: AppStore
    let contact: VIPContact
    @State private var selectedTab: DetailTab = .conversation
    @State private var showContextPanel = true

    enum DetailTab: String, CaseIterable {
        case conversation = "Conversation"
        case context      = "Context"
        case notes        = "Notes"
        case rpm          = "RPM"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Contact header
            ContactHeader(contact: contact, showContextPanel: $showContextPanel)

            // Blaze context banner (collapsible)
            if showContextPanel, let ctx = contact.blazeContext {
                BlazeContextBanner(context: ctx, contact: contact)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Tab bar
            TabSelector(selectedTab: $selectedTab)

            Divider()
                .background(Color(hex: "2a2420"))

            // Tab content
            Group {
                switch selectedTab {
                case .conversation:
                    ConversationView(contact: contact)
                case .context:
                    ContactContextTab(contact: contact)
                case .notes:
                    NotesTab(contact: contact)
                case .rpm:
                    RPMTab(contact: contact)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: selectedTab)
        }
        .background(Color(hex: "0c0b09"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.markAllRead(for: contact) }
    }
}

// MARK: - Contact Header

struct ContactHeader: View {
    let contact: VIPContact
    @Binding var showContextPanel: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(contact.avatarColor.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(contact.avatarInitials)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(contact.avatarColor)
                )
                .overlay(Circle().strokeBorder(contact.relationshipHealth.color.opacity(0.6), lineWidth: 2))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    // Tier
                    Text(contact.tier.rawValue)
                        .font(.caption2.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(contact.tier.badgeColor, in: Capsule())
                }

                Text(contact.role)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: contact.relationshipHealth.icon)
                        .font(.caption2)
                    Text(contact.relationshipHealth.rawValue)
                        .font(.caption)
                    if let days = contact.daysSinceContact {
                        Text("· \(days)d ago")
                            .font(.caption)
                    }
                }
                .foregroundStyle(contact.relationshipHealth.color)
            }

            Spacer()

            // Quick actions
            HStack(spacing: 14) {
                QuickActionButton(icon: "phone.fill", color: Color(hex: "10b981")) {}
                QuickActionButton(icon: "video.fill", color: Color(hex: "60a5fa")) {}
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        showContextPanel.toggle()
                    }
                } label: {
                    Image(systemName: "brain.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(showContextPanel ? Color(hex: "f59e0b") : .secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(hex: "151310"))
    }
}

struct QuickActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Blaze Context Banner

struct BlazeContextBanner: View {
    let context: BlazeContext
    let contact: VIPContact
    @State private var showSuggestion = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Blaze summary
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "f59e0b"))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Blaze")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "f59e0b"))
                    Text(context.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Suggested opener
            if let opener = context.suggestedOpener {
                Divider().background(Color(hex: "2a2420"))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Suggested opener")
                        .font(.caption2.bold())
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    Text("\"\(opener)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Pending items
            if !contact.pendingItems.isEmpty {
                Divider().background(Color(hex: "2a2420"))

                HStack(spacing: 8) {
                    ForEach(contact.pendingItems.prefix(2)) { item in
                        Label(item.title, systemImage: item.isUrgent ? "exclamationmark.circle.fill" : "circle")
                            .font(.caption2)
                            .foregroundStyle(item.isUrgent ? Color(hex: "ef4444") : .secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                item.isUrgent
                                    ? Color(hex: "ef4444").opacity(0.1)
                                    : Color(hex: "2a2420"),
                                in: Capsule()
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "1c1914"))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: "f59e0b").opacity(0.3))
                .frame(height: 1)
        }
    }
}

// MARK: - Tab Selector

struct TabSelector: View {
    @Binding var selectedTab: ContactDetailView.DetailTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContactDetailView.DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedTab == tab ? Color(hex: "f59e0b") : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(alignment: .bottom) {
                            if selectedTab == tab {
                                Rectangle()
                                    .fill(Color(hex: "f59e0b"))
                                    .frame(height: 2)
                            }
                        }
                }
            }
        }
        .background(Color(hex: "151310"))
    }
}

// MARK: - Context Tab

struct ContactContextTab: View {
    let contact: VIPContact

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Key facts
                if let ctx = contact.blazeContext, !ctx.keyFacts.isEmpty {
                    ContextSection(title: "Key Facts", icon: "key.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(ctx.keyFacts, id: \.self) { fact in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(Color(hex: "f59e0b"))
                                        .frame(width: 5, height: 5)
                                        .offset(y: 5)
                                    Text(fact)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // Contact info
                ContextSection(title: "Contact Info", icon: "person.fill") {
                    VStack(spacing: 0) {
                        if let phone = contact.phone {
                            ContactInfoRow(icon: "phone.fill", label: "Phone", value: phone)
                        }
                        if let email = contact.email {
                            ContactInfoRow(icon: "envelope.fill", label: "Email", value: email)
                        }
                        ContactInfoRow(icon: "building.2.fill", label: "Organization", value: contact.organization)
                    }
                }

                // Tags
                if !contact.tags.isEmpty {
                    ContextSection(title: "Tags", icon: "tag.fill") {
                        FlowLayout(spacing: 8) {
                            ForEach(contact.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(hex: "1c1914"), in: Capsule())
                                    .overlay(Capsule().strokeBorder(Color(hex: "2a2420")))
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: "0c0b09"))
    }
}

struct ContactInfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().background(Color(hex: "2a2420"))
        }
    }
}

struct ContextSection<Content: View>: View {
    let title: String; let icon: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            content()
        }
        .padding(14)
        .background(Color(hex: "151310"), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Notes Tab

struct NotesTab: View {
    let contact: VIPContact

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(contact.notes.sorted { $0.isPinned && !$1.isPinned }) { note in
                    NoteCard(note: note)
                }
            }
            .padding(16)
        }
        .background(Color(hex: "0c0b09"))
    }
}

struct NoteCard: View {
    let note: ContactNote
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if note.isPinned {
                Label("Pinned", systemImage: "pin.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(Color(hex: "f59e0b"))
            }
            Text(note.body)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text(note.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "151310"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            note.isPinned
                ? RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "f59e0b").opacity(0.3))
                : nil
        )
    }
}

// MARK: - RPM Tab

struct RPMTab: View {
    let contact: VIPContact
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if contact.rpmProjects.isEmpty {
                    ContentUnavailableView(
                        "No RPM Projects",
                        systemImage: "target",
                        description: Text("Link an RPM project to this contact")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(contact.rpmProjects) { ref in
                        RPMCard(ref: ref)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: "0c0b09"))
    }
}

struct RPMCard: View {
    let ref: RPMReference
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(ref.projectName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(ref.status.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(ref.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ref.status.color.opacity(0.15), in: Capsule())
            }
            Text(ref.outcome)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Updated \(ref.lastUpdated, style: .relative)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(hex: "151310"), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: rows.map { $0.map { $0.height }.max() ?? 0 }.reduce(0, +) + CGFloat(rows.count - 1) * spacing)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += (row.map { $0.height }.max() ?? 0) + spacing
        }
    }
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[(view: LayoutSubview, size: CGSize, height: CGFloat)]] {
        var rows: [[(view: LayoutSubview, size: CGSize, height: CGFloat)]] = [[]]
        var x: CGFloat = 0
        let width = proposal.width ?? 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: width, height: nil))
            if x + size.width > width && !rows[rows.count - 1].isEmpty { rows.append([]); x = 0 }
            rows[rows.count - 1].append((view, size, size.height))
            x += size.width + spacing
        }
        return rows
    }
}
