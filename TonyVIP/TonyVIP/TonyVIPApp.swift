import SwiftUI
import SwiftData

@main
struct TonyVIPApp: App {

    // Phase 2: SwiftData + BlazeService injected here.
    // To go live: swap MockBlazeService → RealBlazeService(baseURL:authToken:)
    @StateObject private var store = AppStore(
        blazeService: MockBlazeService(),
        persistence: .shared
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .modelContainer(PersistenceController.shared.container)
                .preferredColorScheme(.dark)
                .onAppear {
                    if store.selectedContact == nil {
                        store.selectedContact = store.contacts.first
                    }
                }
        }
    }
}
