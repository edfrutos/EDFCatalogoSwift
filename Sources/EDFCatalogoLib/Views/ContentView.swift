import SwiftUI

public struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    public init() {}

    public var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainView()
            } else {
                LoginView()
            }
        }
    }
}
