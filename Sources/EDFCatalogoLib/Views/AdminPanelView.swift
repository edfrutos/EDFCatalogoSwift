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
                    Label("Usuarios", systemImage: "person.3.fill").tag(AdminTab.users)
                    Label("Catálogos", systemImage: "books.vertical.fill").tag(AdminTab.catalogs)
                    Label("Estadísticas", systemImage: "chart.bar.fill").tag(AdminTab.statistics)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.gray.opacity(0.1))
                
                // Content
                Group {
                    switch selectedTab {
                    case .users:
                        AdminUsersListView(viewModel: viewModel)
                            .onAppear { NSLog("🧭 DEBUG Tab: render Usuarios") }
                    case .catalogs:
                        AdminCatalogsListView()
                            .onAppear { NSLog("🧭 DEBUG Tab: render Catálogos") }
                    case .statistics:
                        AdminStatisticsView(viewModel: viewModel)
                    }
                }
            }
            // No forzar pestaña en onAppear; evitar estados inconsistentes de Picker vs contenido
            .onChange(of: selectedTab) { newValue in
                NSLog("🧭 DEBUG Tab cambiado -> %@", String(describing: newValue))
            }
        }
    }
}

// MARK: - Admin Tab Enum

public enum AdminTab: CaseIterable {
    case users
    case catalogs
    case statistics
    
    var label: String {
        switch self {
        case .users:
            return "Usuarios"
        case .catalogs:
            return "Catálogos"
        case .statistics:
            return "Estadísticas"
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
        }
    }
}

// MARK: - Admin Statistics View

struct AdminStatisticsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var catalogs: [Catalog] = []
    @State private var isLoading = false
    @State private var totalRows = 0
    
    var totalUsers: Int { viewModel.users.count }
    var activeUsers: Int { viewModel.users.filter { $0.isActive ?? true }.count }
    var adminUsers: Int { viewModel.users.filter { $0.isAdmin }.count }
    var totalCatalogs: Int { catalogs.count }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Text("Estadísticas Generales")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        Task {
                            await loadStatistics()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }
                
                if isLoading {
                    ProgressView("Cargando estadísticas...")
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            StatisticCardView(
                                title: "Total de Usuarios",
                                value: String(totalUsers),
                                icon: "person.fill",
                                color: .blue
                            )
                            
                            StatisticCardView(
                                title: "Usuarios Activos",
                                value: String(activeUsers),
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            StatisticCardView(
                                title: "Usuarios Inactivos",
                                value: String(totalUsers - activeUsers),
                                icon: "circle.slash.fill",
                                color: .red
                            )
                            
                            StatisticCardView(
                                title: "Administradores",
                                value: String(adminUsers),
                                icon: "crown.fill",
                                color: .orange
                            )
                            
                            StatisticCardView(
                                title: "Total de Catálogos",
                                value: String(totalCatalogs),
                                icon: "books.vertical.fill",
                                color: .purple
                            )
                            
                            StatisticCardView(
                                title: "Total de Filas",
                                value: String(totalRows),
                                icon: "list.bullet.rectangle.fill",
                                color: .indigo
                            )
                        }
                        .padding()
                    }
                }
            }
        }
        .padding()
        .task {
            await loadStatistics()
        }
    }
    
    private func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }
        
        // Cargar usuarios si no están cargados
        if viewModel.users.isEmpty {
            await viewModel.loadUsers()
        }
        
        // Cargar catálogos
        if let user = authViewModel.currentUser {
            do {
                let mongo = MongoService.shared
                catalogs = try await mongo.getCatalogs(userId: user.id, isAdmin: user.isAdmin)
                
                // Calcular total de filas
                totalRows = catalogs.reduce(0) { $0 + $1.rows.count }
            } catch {
                print("⚠️ Error cargando catálogos para estadísticas: \(error.localizedDescription)")
            }
        }
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

