import SwiftUI

@main
struct LedgerApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .tint(T.ink)
                .preferredColorScheme(.light)   // 無印風以紙色為底，固定淺色
        }
    }
}
