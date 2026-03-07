import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @StateObject private var store = MemoryStore()

    var body: some View {
        if hasSeenWelcome {
            HomeView(store: store)
        } else {
            WelcomeView {
                hasSeenWelcome = true
            }
        }
    }
}
