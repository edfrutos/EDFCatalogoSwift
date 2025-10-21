import SwiftUI

public struct AdminUsersListView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var searchText = \"\"
    @State private var showDetails = false
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users
        }
        return viewModel.users.filter { user in
            user.email.localizedCaseInsensitiveContains(searchText) ||
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(\"Gestión de Usuarios\")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(\"Total: \\(viewModel.users.count) usuarios\")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        Task {
                            await viewModel.loadUsers()
                        }
                    }) {
                        Image(systemName: \"arrow.clockwise\")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isLoading)
                }
                
                // Search Bar
                HStack {
                    Image(systemName: \"magnifyingglass\")
                        .foregroundColor(.gray)
                    TextField(\"Buscar por email, nombre o usuario\", text: \$searchText)
                        .textFieldStyle(.roundedBorder)
                    if !searchText.isEmpty {
                        Button(action: { searchText = \"\" }) {
                            Image(systemName: \"xmark.circle.fill\")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Messages
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: \"exclamationmark.circle.fill\")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button(action: { viewModel.errorMessage = nil }) {
                        Image(systemName: \"xmark\")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemRed).opacity(0.1))
                .onAppear {
                    viewModel.clearMessages()
                }
            }
            
            if let success = viewModel.successMessage {
                HStack {
                    Image(systemName: \"checkmark.circle.fill\")
                        .foregroundColor(.green)
                    Text(success)
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                    Button(action: { viewModel.successMessage = nil }) {
                        Image(systemName: \"xmark\")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.systemGreen).opacity(0.1))
                .onAppear {
                    viewModel.clearMessages()
                }
            }
            
            // User List
            if viewModel.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                    Text(\"Cargando usuarios...\")
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else if filteredUsers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: \"person.slash\")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text(searchText.isEmpty ? \"No hay usuarios\" : \"No se encontraron resultados\")
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredUsers) { user in
                            UserListItemView(
                                user: user,
                                onSelect: {
                                    viewModel.selectUser(user)
                                    showDetails = true
                                },
                                onToggleRole: {
                                    Task {
                                        await viewModel.updateUserRole(user, isAdmin: !user.isAdmin)
                                    }
                                },
                                onToggleActive: {
                                    Task {
                                        await viewModel.updateUserActiveStatus(user, isActive: !(user.isActive ?? true))
                                    }
                                },
                                onDelete: {
                                    viewModel.openDeleteConfirmation(for: user)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: \$showDetails) {
            if let user = viewModel.selectedUser {
                AdminUserDetailView(viewModel: viewModel, user: user)
            }
        }
        .alert(\"Eliminar Usuario\", isPresented: \$viewModel.showDeleteConfirmation) {
            Button(\"Cancelar\", role: .cancel) {
                viewModel.closeDeleteConfirmation()
            }
            Button(\"Eliminar\", role: .destructive) {
                if let user = viewModel.userToDelete {
                    Task {
                        await viewModel.deleteUser(user)
                    }
                }
            }
        } message: {
            if let user = viewModel.userToDelete {
                Text(\"¿Deseas eliminar a \\(user.email)? Esta acción no se puede deshacer.\")
            }
        }
        .task {
            await viewModel.loadUsers()
        }
    }
}

// MARK: - User List Item View

struct UserListItemView: View {
    let user: User
    let onSelect: () -> Void
    let onToggleRole: () -> Void
    let onToggleActive: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(user.name.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(user.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if user.isAdmin {
                            Label(\"Admin\", systemImage: \"crown.fill\")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                        if !(user.isActive ?? true) {
                            Label(\"Inactivo\", systemImage: \"circle.slash\")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Actions Menu
                Menu {
                    Button(action: onSelect) {
                        Label(\"Ver Detalles\", systemImage: \"eye\")
                    }
                    
                    Divider()
                    
                    Button(action: onToggleRole) {
                        Label(user.isAdmin ? \"Hacer Usuario\" : \"Hacer Admin\", systemImage: user.isAdmin ? \"person\" : \"crown.fill\")
                    }
                    
                    Button(action: onToggleActive) {
                        Label(user.isActive ?? true ? \"Desactivar\" : \"Activar\", systemImage: user.isActive ?? true ? \"circle.slash\" : \"circle.fill\")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onDelete) {
                        Label(\"Eliminar\", systemImage: \"trash\")
                    }
                } label: {
                    Image(systemName: \"ellipsis.circle\")
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
        }
        .background(Color(.systemBackground))
        .border(Color(.systemGray4), width: 1)
        .cornerRadius(8)
    }
}

#Preview {
    let mockViewModel = AdminViewModel(mongoService: MockMongoService())
    AdminUsersListView(viewModel: mockViewModel)
}
