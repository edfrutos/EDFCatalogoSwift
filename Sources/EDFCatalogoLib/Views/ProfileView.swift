import SwiftUI
import UniformTypeIdentifiers

public struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: UserProfileViewModel
    @State private var showingContact = false
    
    public init() {
        // Se inicializará en onAppear cuando tengamos el usuario
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(user: User.mock(email: "temp@temp.com")))
    }
    
    private func setupViewModel() {
        viewModel.onProfileSaved = { [authViewModel] in
            await authViewModel.reloadCurrentUser()
        }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Foto de perfil
                ProfileImageSection(viewModel: viewModel)
                
                Divider()
                
                // Información básica
                VStack(alignment: .leading, spacing: 16) {
                    Text("Información Básica")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("", text: .constant(viewModel.email))
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nombre de Usuario *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Ej: juanp", text: $viewModel.username)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nombre para Mostrar *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Ej: Juan", text: $viewModel.name)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                Divider()
                
                // Información opcional
                VStack(alignment: .leading, spacing: 16) {
                    Text("Información Adicional (Opcional)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nombre y Apellidos Completos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Ej: Juan Pérez García", text: $viewModel.fullName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Teléfono")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Ej: +34 600 000 000", text: $viewModel.phone)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Empresa")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Ej: Mi Empresa S.L.", text: $viewModel.company)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ocupación")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Ej: Desarrollador", text: $viewModel.occupation)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dirección Postal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.address)
                            .frame(height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                Divider()
                
                // Cambiar contraseña
                ChangePasswordSection(viewModel: viewModel)
                
                // Mensajes de error/éxito
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }
                
                // Botones de acción
                HStack(spacing: 16) {
                    Button(viewModel.isSaving ? "Guardando..." : "Guardar Cambios") {
                        Task {
                            await viewModel.saveProfile()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSaving || !viewModel.canSave)
                    
                    Button {
                        showingContact = true
                    } label: {
                        Label("Contactar soporte", systemImage: "envelope")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Perfil")
        .sheet(isPresented: $showingContact) {
            ContactView()
                .environmentObject(authViewModel)
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                viewModel.updateUser(user)
                setupViewModel()
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
