import SwiftUI

public struct AdminPanelView: View {
    @Environment(\\.dismiss) var dismiss
    @ObservedObject var viewModel: AdminViewModel
    let currentUser: User
    
    @State private var selectedTab: AdminTab = .users
    
    public var body: some View {
        if !currentUser.isAdmin {
            // Acceso denegado
            VStack(spacing: 16) {
                Image(systemName: \"hand.raised.fill\")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text(\"Acceso Denegado\")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(\"No tienes permisos para acceder al panel de administración. Solo los administradores pueden acceder a esta sección.\")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                
                Button(action: { dismiss() }) {
                    Text(\"Cerrar\")
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
                        Text(\"Panel de Administración\")
                            .font(.title2)
                            .fontWeight(.bold)
                        HStack(spacing: 8) {
                            Image(systemName: \"crown.fill\")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(currentUser.name)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: \"xmark.circle.fill\")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .border(Color(.systemGray4), width: 1)
                
                // Tab Navigation
                Picker(\"Tab\", selection: \$selectedTab) {
                    ForEach(AdminTab.allCases, id: \\.self) { tab in
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                            Text(tab.label)
                        }
                        .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(.systemGray6))
                
                // Content
                Group {
                    switch selectedTab {
                    case .users:
                        AdminUsersListView(viewModel: viewModel)
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
    case statistics
    case settings
    
    var label: String {
        switch self {
        case .users:
            return \"Usuarios\"
        case .statistics:
            return \"Estadísticas\"
        case .settings:
            return \"Configuración\"
        }
    }
    
    var icon: String {
        switch self {
        case .users:
            return \"person.3.fill\"
        case .statistics:
            return \"chart.bar.fill\"
        case .settings:
            return \"gear\"
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
                    Text(\"Estadísticas\")
                        .font(.headline)
                    Spacer()
                }
                
                ScrollView {
                    VStack(spacing: 12) {
                        StatisticCardView(
                            title: \"Total de Usuarios\",
                            value: \"0\",
                            icon: \"person.fill\",
                            color: .blue
                        )
                        
                        StatisticCardView(
                            title: \"Usuarios Activos\",
                            value: \"0\",
                            icon: \"checkmark.circle.fill\",
                            color: .green
                        )
                        
                        StatisticCardView(
                            title: \"Administradores\",
                            value: \"1\",
                            icon: \"crown.fill\",
                            color: .orange
                        )
                        
                        StatisticCardView(
                            title: \"Catálogos\",
                            value: \"0\",
                            icon: \"books.vertical.fill\",
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
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Admin Settings View

struct AdminSettingsView: View {
    let currentUser: User
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(\"Información del Administrador\", systemImage: \"person.fill\")
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        InfoSettingRowView(label: \"Email\", value: currentUser.email)
                        InfoSettingRowView(label: \"Usuario\", value: currentUser.username)
                        InfoSettingRowView(label: \"Nombre\", value: currentUser.name)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label(\"Configuración del Sistema\", systemImage: \"gear\")
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        SettingToggleRowView(title: \"Mantenimiento\", isOn: false)
                        SettingToggleRowView(title: \"Modo Seguro\", isOn: true)
                        SettingToggleRowView(title: \"Logs Detallados\", isOn: false)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label(\"Backup\", systemImage: \"externaldrive.badge.checkmark\")
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        Button(action: {}) {
                            Label(\"Hacer Backup Ahora\", systemImage: \"square.and.arrow.down\")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Info Setting Row View

struct InfoSettingRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

// MARK: - Setting Toggle Row View

struct SettingToggleRowView: View {
    let title: String
    @State var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Toggle(\"\", isOn: \$isOn)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

#Preview {
    let mockUser = User(
        _id: BSONObjectID(),
        email: \"admin@example.com\",
        username: \"admin\",
        name: \"Administrador\",
        isAdmin: true
    )
    let mockViewModel = AdminViewModel(mongoService: MockMongoService())
    AdminPanelView(viewModel: mockViewModel, currentUser: mockUser)
}
