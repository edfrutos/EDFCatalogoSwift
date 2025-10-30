import SwiftUI

public struct AdminPanelView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AdminViewModel
    let currentUser: User
    
    @State private var selectedTab: AdminTab = .users
    
    public var body: some View {
        if !currentUser.isAdmin {
            // Acceso denegado
            VStack(spacing: 16) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Acceso Denegado")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("No tienes permisos para acceder al panel de administración. Solo los administradores pueden acceder a esta sección.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                
                Button(action: { dismiss() }) {
                    Text("Cerrar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .center)
        } else {
            // Panel de administración
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Panel de Administración")
                            .font(.title2)
                            .fontWeight(.bold)
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(currentUser.name)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .border(Color.gray.opacity(0.3), width: 1)
                
                // Tab Navigation
                Picker("Tab", selection: $selectedTab) {
                    ForEach(AdminTab.allCases, id: \.self) { tab in
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                            Text(tab.label)
                        }
                        .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.gray.opacity(0.1))
                
                // Content
                Group {
                    switch selectedTab {
                    case .users:
                        AdminUsersListView(viewModel: viewModel)
                    case .catalogs:
                        AdminCatalogsListView()
                    case .statistics:
                        AdminStatisticsView(currentUser: currentUser)
                    case .settings:
                        AdminSettingsView(currentUser: currentUser)
                    }
                }
            }
        }
    }
}

// MARK: - Admin Tab Enum

public enum AdminTab: CaseIterable {
    case users
    case catalogs
    case statistics
    case settings
    
    var label: String {
        switch self {
        case .users:
            return "Usuarios"
        case .catalogs:
            return "Catálogos"
        case .statistics:
            return "Estadísticas"
        case .settings:
            return "Configuración"
        }
    }
    
    var icon: String {
        switch self {
        case .users:
            return "person.3.fill"
        case .catalogs:
            return "books.vertical.fill"
        case .statistics:
            return "chart.bar.fill"
        case .settings:
            return "gear"
        }
    }
}

// MARK: - Admin Statistics View

struct AdminStatisticsView: View {
    let currentUser: User
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Text("Estadísticas")
                        .font(.headline)
                    Spacer()
                }
                
                ScrollView {
                    VStack(spacing: 12) {
                        StatisticCardView(
                            title: "Total de Usuarios",
                            value: "0",
                            icon: "person.fill",
                            color: .blue
                        )
                        
                        StatisticCardView(
                            title: "Usuarios Activos",
                            value: "0",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatisticCardView(
                            title: "Administradores",
                            value: "1",
                            icon: "crown.fill",
                            color: .orange
                        )
                        
                        StatisticCardView(
                            title: "Catálogos",
                            value: "0",
                            icon: "books.vertical.fill",
                            color: .purple
                        )
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
}

// MARK: - Statistic Card View

struct StatisticCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Admin Settings View

struct AdminSettingsView: View {
    let currentUser: User
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Información del Administrador", systemImage: "person.fill")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .fontWeight(.semibold)
                        Text(currentUser.email)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Usuario")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .fontWeight(.semibold)
                        Text(currentUser.username)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .fontWeight(.semibold)
                        Text(currentUser.name)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
    }
}
