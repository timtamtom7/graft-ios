import Cocoa
import SwiftUI

@main
struct GraftMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacGraftView()
                .frame(minWidth: 800, minHeight: 600)
                .darkMode()
        }
    }
}

extension View {
    func darkMode() -> some View {
        self.preferredColorScheme(.dark)
    }
}
