import SwiftUI

public struct AdminUserDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AdminViewModel
    
    let user: User
    
    @State private var editingEmail: String = ""
    @State private var editingUsername: String = ""
    @State private var editingName: String = ""
    @State private var editingFullName: String = ""
    @State private var editingPhone: String = ""
    @State private var editingCompany: String = ""
    @State private var editingAddress: String = ""
    @State private var editingOccupation: String = ""
    @State private var editingIsAdmin: Bool = false
    @State private var editingIsActive: Bool = true
    
    @State private var isEditing = false
    
    var hasChanges: Bool {
        editingEmail != user.email ||
        editingUsername != user.username ||
        editingName != user.name ||
        editingFullName != (user.fullName ?? "") ||
        editingPhone != (user.phone ?? "") ||
        editingCompany != (user.company ?? "") ||
        editingAddress != (user.address ?? "") ||
        editingOccupation != (user.occupation ?? "") ||
        editingIsAdmin != user.isAdmin ||
        editingIsActive != (user.isActive ?? true)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detalles del Usuario")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.gray)
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
            
            ScrollView {
                VStack(spacing: 16) {
                    // User Avatar
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Text(String(user.name.prefix(1)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    
                    // Tabs
                    Picker("Tab", selection: $isEditing) {
                        Text("Ver").tag(false)
                        Text("Editar").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if isEditing {
                        // Edit Form
                        VStack(spacing: 16) {
                            // Rol
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Rol", systemImage: "crown.fill")
                                    .fontWeight(.semibold)
                                
                                Picker("Rol", selection: $editingIsAdmin) {
                                    Text("Usuario Normal").tag(false)
                                    Text("Administrador").tag(true)
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Estado Activo
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Estado", systemImage: "circle.fill")
                                    .fontWeight(.semibold)
                                
                                Toggle("Usuario Activo", isOn: $editingIsActive)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Email", systemImage: "envelope.fill")
                                    .fontWeight(.semibold)
                                TextField("Email", text: $editingEmail)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Username
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Usuario", systemImage: "person.fill")
                                    .fontWeight(.semibold)
                                TextField("Usuario", text: $editingUsername)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Nombre para mostrar
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Nombre para mostrar", systemImage: "text.justify")
                                    .fontWeight(.semibold)
                                TextField("Nombre", text: $editingName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Nombre completo
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Nombre completo", systemImage: "person.text.rectangle")
                                    .fontWeight(.semibold)
                                TextField("Nombre y apellidos", text: $editingFullName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Teléfono
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Teléfono", systemImage: "phone.fill")
                                    .fontWeight(.semibold)
                                TextField("Teléfono", text: $editingPhone)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Empresa
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Empresa", systemImage: "building.2.fill")
                                    .fontWeight(.semibold)
                                TextField("Empresa", text: $editingCompany)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Dirección
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Dirección", systemImage: "location.fill")
                                    .fontWeight(.semibold)
                                TextField("Dirección", text: $editingAddress)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Profesión
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Profesión", systemImage: "briefcase.fill")
                                    .fontWeight(.semibold)
                                TextField("Profesión", text: $editingOccupation)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    initializeEditingFields()
                                }) {
                                    Text("Cancelar")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: {
                                    saveChanges()
                                }) {
                                    Text("Guardar")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!hasChanges || viewModel.isLoading)
                            }
                        }
                        .padding()
                    } else {
                        // View Mode
                        VStack(spacing: 16) {
                            InfoRowView(label: "Rol", value: user.isAdmin ? "👑 Administrador" : "👤 Usuario Normal")
                            InfoRowView(label: "Estado", value: (user.isActive ?? true) ? "✅ Activo" : "❌ Inactivo")
                            Divider()
                            InfoRowView(label: "Email", value: user.email)
                            InfoRowView(label: "Usuario", value: user.username)
                            InfoRowView(label: "Nombre", value: user.name)
                            if let fullName = user.fullName, !fullName.isEmpty {
                                InfoRowView(label: "Nombre Completo", value: fullName)
                            }
                            if let phone = user.phone, !phone.isEmpty {
                                InfoRowView(label: "Teléfono", value: phone)
                            }
                            if let company = user.company, !company.isEmpty {
                                InfoRowView(label: "Empresa", value: company)
                            }
                            if let address = user.address, !address.isEmpty {
                                InfoRowView(label: "Dirección", value: address)
                            }
                            if let occupation = user.occupation, !occupation.isEmpty {
                                InfoRowView(label: "Profesión", value: occupation)
                            }
                            if let createdAt = user.createdAt {
                                InfoRowView(label: "Creado el", value: createdAt.formatted(date: .numeric, time: .shortened))
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            initializeEditingFields()
        }
    }
    
    private func initializeEditingFields() {
        editingEmail = user.email
        editingUsername = user.username
        editingName = user.name
        editingFullName = user.fullName ?? ""
        editingPhone = user.phone ?? ""
        editingCompany = user.company ?? ""
        editingAddress = user.address ?? ""
        editingOccupation = user.occupation ?? ""
        editingIsAdmin = user.isAdmin
        editingIsActive = user.isActive ?? true
    }
    
    private func saveChanges() {
        var editedUser = user
        editedUser.email = editingEmail
        editedUser.username = editingUsername
        editedUser.name = editingName
        editedUser.fullName = editingFullName.isEmpty ? nil : editingFullName
        editedUser.phone = editingPhone.isEmpty ? nil : editingPhone
        editedUser.company = editingCompany.isEmpty ? nil : editingCompany
        editedUser.address = editingAddress.isEmpty ? nil : editingAddress
        editedUser.occupation = editingOccupation.isEmpty ? nil : editingOccupation
        editedUser.isAdmin = editingIsAdmin
        editedUser.isActive = editingIsActive
        
        Task {
            await viewModel.updateUser(editedUser)
            dismiss()
        }
    }
}

// MARK: - Info Row View

struct InfoRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .fontWeight(.semibold)
            Text(value)
                .font(.body)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
