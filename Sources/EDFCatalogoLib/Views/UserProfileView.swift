import SwiftUI
import UniformTypeIdentifiers

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(user: user))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Perfil de Usuario")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Divider()
                
                // Foto de perfil
                ProfileImageSection(viewModel: viewModel)
                
                Divider()
                
                // Información básica
                VStack(alignment: .leading, spacing: 16) {
                    Text("Información Básica")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Email (obligatorio, no editable)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("", text: .constant(viewModel.email))
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                    }
                    
                    // Nombre de usuario (obligatorio)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nombre de Usuario *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Ej: Juan Pérez", text: $viewModel.name)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Información opcional
                VStack(alignment: .leading, spacing: 16) {
                    Text("Información Adicional (Opcional)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
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
                    Button("Cancelar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(viewModel.isSaving ? "Guardando..." : "Guardar Cambios") {
                        Task {
                            await viewModel.saveProfile()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSaving || !viewModel.canSave)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 600, height: 700)
    }
}

// MARK: - Foto de Perfil
struct ProfileImageSection: View {
    @ObservedObject var viewModel: UserProfileViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Foto actual o placeholder
            if let image = viewModel.profileImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 12) {
                Button("Seleccionar Foto") {
                    viewModel.selectProfileImage()
                }
                .buttonStyle(.bordered)
                
                if viewModel.profileImage != nil || viewModel.profileImageUrl != nil {
                    Button("Eliminar") {
                        viewModel.removeProfileImage()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            
            if viewModel.isUploadingImage {
                ProgressView("Subiendo imagen...")
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Cambiar Contraseña
struct ChangePasswordSection: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @State private var showPasswordFields = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cambiar Contraseña")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(showPasswordFields ? "Cancelar" : "Cambiar") {
                    showPasswordFields.toggle()
                    if !showPasswordFields {
                        viewModel.clearPasswordFields()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if showPasswordFields {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contraseña Actual *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("", text: $viewModel.currentPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nueva Contraseña *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Mínimo 6 caracteres", text: $viewModel.newPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirmar Nueva Contraseña *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("", text: $viewModel.confirmPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    if !viewModel.passwordsMatch {
                        Text("⚠️ Las contraseñas no coinciden")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if let passwordError = viewModel.passwordError {
                        Text("❌ \(passwordError)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - ViewModel
@MainActor
class UserProfileViewModel: ObservableObject {
    private let originalUser: User
    
    // Campos obligatorios
    @Published var email: String
    @Published var name: String
    
    // Campos opcionales
    @Published var phone: String
    @Published var company: String
    @Published var address: String
    @Published var occupation: String
    @Published var profileImageUrl: String?
    @Published var profileImage: NSImage?
    
    // Cambio de contraseña
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var passwordError: String?
    
    // Estado
    @Published var isSaving = false
    @Published var isUploadingImage = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private var selectedImageFile: URL?
    
    var canSave: Bool {
        !name.isEmpty && !email.isEmpty
    }
    
    var passwordsMatch: Bool {
        newPassword.isEmpty || newPassword == confirmPassword
    }
    
    init(user: User) {
        self.originalUser = user
        self.email = user.email
        self.name = user.name
        self.phone = user.phone ?? ""
        self.company = user.company ?? ""
        self.address = user.address ?? ""
        self.occupation = user.occupation ?? ""
        self.profileImageUrl = user.profileImageUrl
    }
    
    func updateUser(_ user: User) {
        self.email = user.email
        self.name = user.name
        self.phone = user.phone ?? ""
        self.company = user.company ?? ""
        self.address = user.address ?? ""
        self.occupation = user.occupation ?? ""
        self.profileImageUrl = user.profileImageUrl
    }
    
    func selectProfileImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "Selecciona una foto de perfil"
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.selectedImageFile = url
                if let image = NSImage(contentsOf: url) {
                    self?.profileImage = image
                }
            }
        }
    }
    
    func removeProfileImage() {
        profileImage = nil
        profileImageUrl = nil
        selectedImageFile = nil
    }
    
    func clearPasswordFields() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
        passwordError = nil
    }
    
    func saveProfile() async {
        guard canSave else {
            errorMessage = "Por favor completa todos los campos obligatorios"
            return
        }
        
        isSaving = true
        errorMessage = nil
        successMessage = nil
        passwordError = nil
        
        // Validar cambio de contraseña si se solicitó
        if !currentPassword.isEmpty || !newPassword.isEmpty {
            guard !currentPassword.isEmpty else {
                passwordError = "Debes ingresar tu contraseña actual"
                isSaving = false
                return
            }
            
            guard newPassword.count >= 6 else {
                passwordError = "La nueva contraseña debe tener al menos 6 caracteres"
                isSaving = false
                return
            }
            
            guard passwordsMatch else {
                passwordError = "Las contraseñas no coinciden"
                isSaving = false
                return
            }
        }
        
        // Subir imagen si hay una nueva
        if let imageFile = selectedImageFile {
            isUploadingImage = true
            do {
                let s3Service = S3Service.shared
                let uploadedUrl = try await s3Service.uploadFile(
                    fileUrl: imageFile,
                    userId: originalUser.id,
                    catalogId: "profile",
                    fileType: .image
                )
                profileImageUrl = uploadedUrl
                print("✅ Imagen de perfil subida: \(uploadedUrl)")
            } catch {
                errorMessage = "Error al subir imagen: \(error.localizedDescription)"
                isUploadingImage = false
                isSaving = false
                return
            }
            isUploadingImage = false
        }
        
        // Aquí implementarías la actualización en MongoDB
        // Por ahora solo simulamos
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        successMessage = "✅ Perfil actualizado correctamente"
        isSaving = false
        
        // Limpiar campos de contraseña después de guardar
        if !newPassword.isEmpty {
            clearPasswordFields()
        }
    }
}

// MARK: - Preview
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(user: User.mock(email: "test@example.com"))
    }
}
