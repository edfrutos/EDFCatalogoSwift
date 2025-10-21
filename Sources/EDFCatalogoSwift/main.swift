import SwiftUI
import EDFCatalogoLib

@main
struct EDFCatalogoApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onAppear {
                    // Activar la aplicación al aparecer
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Asegurar que la ventana principal esté al frente y activa
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Hacer que la primera ventana sea key y visible
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
