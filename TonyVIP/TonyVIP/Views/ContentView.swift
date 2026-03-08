import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationSplitView {
            InboxView()
        } detail: {
            if let contact = store.selectedContact {
                ContactDetailView(contact: contact)
            } else {
                EmptyStateView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color(hex: "f59e0b"))
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(hex: "f59e0b"))
                .shadow(color: Color(hex: "f59e0b").opacity(0.4), radius: 16)
            Text("Select a contact")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text("Blaze will surface everything you need\nbefore you say a word.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0c0b09"))
    }
}
