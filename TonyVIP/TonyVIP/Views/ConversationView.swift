import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var store: AppStore
    let contact: VIPContact
    @State private var draftText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil
    @FocusState private var isComposing: Bool

    private var messages: [Message] { store.messages(for: contact) }

    var body: some View {
        VStack(spacing: 0) {
            // Message thread
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        if messages.isEmpty {
                            EmptyConversationView(contact: contact)
                                .padding(.top, 60)
                        } else {
                            ForEach(messages) { msg in
                                MessageBubbleView(message: msg, contact: contact)
                                    .id(msg.id)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .onAppear {
                    scrollProxy = proxy
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            // Compose bar
            ComposeBar(draftText: $draftText, isFocused: $isComposing) {
                guard !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                store.send(text: draftText, to: contact)
                draftText = ""
            }
        }
        .background(Color(hex: "0c0b09"))
    }
}

// MARK: - Message Bubble

struct MessageBubbleView: View {
    let message: Message
    let contact: VIPContact

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromTony {
                Spacer(minLength: 60)
            } else {
                // Contact avatar
                Circle()
                    .fill(contact.avatarColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(contact.avatarInitials)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(contact.avatarColor)
                    )
            }

            VStack(alignment: message.isFromTony ? .trailing : .leading, spacing: 3) {
                // Bubble
                Text(message.body)
                    .font(.system(size: 15))
                    .foregroundStyle(message.isFromTony ? .black : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromTony
                            ? Color(hex: "f59e0b")
                            : Color(hex: "1c1914"),
                        in: BubbleShape(isFromTony: message.isFromTony)
                    )
                    .fixedSize(horizontal: false, vertical: true)

                // Meta
                HStack(spacing: 4) {
                    if message.isFromTony {
                        Image(systemName: message.channel.icon)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(message.sentAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if !message.isFromTony {
                Spacer(minLength: 60)
            }
        }
    }
}

struct BubbleShape: Shape {
    let isFromTony: Bool
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 18
        let tailR: CGFloat = 6
        var path = Path()
        if isFromTony {
            path.move(to: CGPoint(x: rect.maxX - tailR, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tailR))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - tailR, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: tailR, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(0), endAngle: .degrees(270), clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
            path.addLine(to: CGPoint(x: 0, y: rect.maxY - tailR))
            path.addQuadCurve(to: CGPoint(x: tailR, y: rect.maxY), control: CGPoint(x: 0, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Compose Bar

struct ComposeBar: View {
    @Binding var draftText: String
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Text field
            ZStack(alignment: .leading) {
                if draftText.isEmpty {
                    Text("Message")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                TextField("", text: $draftText, axis: .vertical)
                    .lineLimit(1...5)
                    .focused(isFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .background(Color(hex: "1c1914"), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color(hex: "2a2420")))

            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(draftText.isEmpty ? .tertiary : .black)
                    .frame(width: 34, height: 34)
                    .background(
                        draftText.isEmpty ? Color(hex: "1c1914") : Color(hex: "f59e0b"),
                        in: Circle()
                    )
            }
            .disabled(draftText.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(hex: "0c0b09"))
        .overlay(alignment: .top) {
            Divider().background(Color(hex: "1c1914"))
        }
    }
}

// MARK: - Empty Conversation

struct EmptyConversationView: View {
    let contact: VIPContact
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(contact.avatarColor.opacity(0.15))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(contact.avatarInitials)
                        .font(.title2.bold())
                        .foregroundStyle(contact.avatarColor)
                )
            Text("Start a conversation with \(contact.name.components(separatedBy: " ").first ?? contact.name)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
