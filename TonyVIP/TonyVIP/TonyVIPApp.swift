import SwiftUI

@main
struct TonyVIPApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Auto-select first contact so the chat screen is visible immediately
                    if store.selectedContact == nil {
                        store.selectedContact = store.contacts.first
                    }
                }
        }
    }
}
