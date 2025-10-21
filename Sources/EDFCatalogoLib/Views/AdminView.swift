import SwiftUI

public struct AdminView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var adminViewModel: AdminViewModel
    
    public init() {
        let mongoService = MongoService.shared
        _adminViewModel = StateObject(wrappedValue: AdminViewModel(mongoService: mongoService))
    }

    public var body: some View {
        if let currentUser = authViewModel.currentUser {
            AdminPanelView(viewModel: adminViewModel, currentUser: currentUser)
        } else {
            VStack {
                Text("Error: No se pudo cargar el usuario")
                    .foregroundColor(.red)
            }
            .padding()
        }
    }
}
