import SwiftUI

public enum NavigationItem: Hashable {
    case catalogs
    case profile
    case admin
}

public struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedItem: NavigationItem? = .catalogs
    
    public init() {}

    public var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private var sidebar: some View {
        List(selection: $selectedItem) {
            NavigationLink(value: NavigationItem.catalogs) {
                Label("Catálogos", systemImage: "folder")
            }

            NavigationLink(value: NavigationItem.profile) {
                Label("Perfil", systemImage: "person")
            }

            if authViewModel.currentUser?.isAdmin ?? false {
                NavigationLink(value: NavigationItem.admin) {
                    Label("Administración", systemImage: "gear")
                }
            }
            
            Divider()
            
            Button {
                Task {
                    authViewModel.signOut()
                }
            } label: {
                Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("EDF Catálogo")
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .catalogs:
            CatalogsView()
        case .profile:
            ProfileView()
        case .admin:
            AdminView()
        case .none:
            Text("Selecciona una opción del menú")
                .foregroundColor(.secondary)
        }
    }
}
