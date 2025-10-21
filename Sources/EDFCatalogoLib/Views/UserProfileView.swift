import SwiftUI
import UniformTypeIdentifiers
import CryptoKit
import os.log

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    let onProfileSaved: (() async -> Void)?
    
    init(user: User, onProfileSaved: (() async -> Void)? = nil) {
        let vm = UserProfileViewModel(user: user)
        vm.onProfileSaved = onProfileSaved
        _viewModel = StateObject(wrappedValue: vm)
        self.onProfileSaved = onProfileSaved
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header fijo
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
                
            // Contenido scrollable
            ScrollView {
                VStack(spacing: 24) {
                    // Foto de perfil
                    ProfileImageSection(viewModel: viewModel)
                        .padding(.top, 16)
                
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
                        TextField("Ej: juanp", text: $viewModel.username)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                    }
                    
                    // Nombre para mostrar (obligatorio)
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
                
                // Espaciado al final del scroll
                Color.clear.frame(height: 20)
                }
            }
            
            Divider()
            
            // Botones de acción fijos
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 600, idealWidth: 650, maxWidth: 800, minHeight: 600, idealHeight: 750, maxHeight: .infinity)
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
                        SecureFieldWithToggle("", text: $viewModel.currentPassword)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nueva Contraseña *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureFieldWithToggle("Mínimo 6 caracteres", text: $viewModel.newPassword)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirmar Nueva Contraseña *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureFieldWithToggle("", text: $viewModel.confirmPassword)
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
    private let logger = Logger(subsystem: "com.edefrutos.catalogo", category: "UserProfile")
    private let originalUser: User
    var onProfileSaved: (() async -> Void)?
    
    // Campos obligatorios
    @Published var email: String
    @Published var username: String
    @Published var name: String
    
    // Campos opcionales
    @Published var fullName: String
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
        !username.isEmpty && !name.isEmpty && !email.isEmpty
    }
    
    var passwordsMatch: Bool {
        newPassword.isEmpty || newPassword == confirmPassword
    }
    
    init(user: User) {
        self.originalUser = user
        self.email = user.email
        self.username = user.username
        self.name = user.name
        self.fullName = user.fullName ?? ""
        self.phone = user.phone ?? ""
        self.company = user.company ?? ""
        self.address = user.address ?? ""
        self.occupation = user.occupation ?? ""
        self.profileImageUrl = user.profileImageUrl
        
        // Cargar imagen desde URL si existe
        if let imageUrlString = user.profileImageUrl,
           let imageUrl = URL(string: imageUrlString) {
            Task {
                await self.loadProfileImage(from: imageUrl)
            }
        }
    }
    
    func updateUser(_ user: User) {
        self.email = user.email
        self.username = user.username
        self.name = user.name
        self.fullName = user.fullName ?? ""
        self.phone = user.phone ?? ""
        self.company = user.company ?? ""
        self.address = user.address ?? ""
        self.occupation = user.occupation ?? ""
        
        // Cargar nueva imagen si cambió la URL
        if self.profileImageUrl != user.profileImageUrl {
            self.profileImageUrl = user.profileImageUrl
            if let imageUrlString = user.profileImageUrl,
               let imageUrl = URL(string: imageUrlString) {
                Task {
                    await self.loadProfileImage(from: imageUrl)
                }
            } else {
                self.profileImage = nil
            }
        }
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
    
    func loadProfileImage(from url: URL) async {
        logger.info("🖼️ Cargando imagen de perfil desde: \(url.absoluteString, privacy: .public)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = NSImage(data: data) {
                await MainActor.run {
                    self.profileImage = image
                    logger.info("✅ Imagen de perfil cargada correctamente")
                }
            } else {
                logger.warning("⚠️ No se pudo crear NSImage desde los datos descargados")
            }
        } catch {
            logger.error("❌ Error al cargar imagen de perfil: \(error.localizedDescription, privacy: .public)")
        }
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
            logger.info("📎 Imagen seleccionada para subir: \(imageFile.path, privacy: .public)")
            isUploadingImage = true
            do {
                let s3Service = S3Service.shared
                logger.info("📤 Iniciando subida a S3...")
                logger.info("   - Usuario ID: \(self.originalUser.id, privacy: .public)")
                logger.info("   - Archivo: \(imageFile.lastPathComponent, privacy: .public)")
                let uploadedUrl = try await s3Service.uploadFile(
                    fileUrl: imageFile,
                    userId: originalUser.id,
                    catalogId: "profile",
                    fileType: .image
                )
                profileImageUrl = uploadedUrl
                logger.info("✅ Imagen de perfil subida: \(uploadedUrl, privacy: .public)")
            } catch {
                logger.error("❌ Error al subir imagen: \(error.localizedDescription, privacy: .public)")
                errorMessage = "Error al subir imagen: \(error.localizedDescription)"
                isUploadingImage = false
                isSaving = false
                return
            }
            isUploadingImage = false
        } else {
            logger.warning("⚠️ No hay imagen seleccionada para subir")
        }
        
        // Actualizar perfil en MongoDB
        do {
            let mongoService = MongoService.shared
            
            logger.info("💾 Actualizando perfil en MongoDB...")
            logger.info("   - Email: \(self.email, privacy: .public)")
            logger.info("   - Username: \(self.username, privacy: .public)")
            logger.info("   - Nombre: \(self.name, privacy: .public)")
            logger.info("   - ProfileImageUrl: \(self.profileImageUrl ?? "nil", privacy: .public)")
            
            try await mongoService.updateUserProfile(
                email: email,
                username: username,
                name: name,
                fullName: fullName.isEmpty ? nil : fullName,
                phone: phone.isEmpty ? nil : phone,
                company: company.isEmpty ? nil : company,
                address: address.isEmpty ? nil : address,
                occupation: occupation.isEmpty ? nil : occupation,
                profileImageUrl: profileImageUrl
            )
            
            // Actualizar contraseña si se solicitó
            if !newPassword.isEmpty {
                // Verificar contraseña actual
                let authResult = try await mongoService.authenticateUser(emailOrUsername: email, password: currentPassword)
                
                guard authResult != nil else {
                    passwordError = "Contraseña actual incorrecta"
                    isSaving = false
                    return
                }
                
                // Generar hash SHA256 de la nueva contraseña
                if let passwordData = newPassword.data(using: .utf8) {
                    let hash = SHA256.hash(data: passwordData)
                    let hashData = Data(hash)
                    let newPasswordHash = hashData.base64EncodedString()
                    
                    try await mongoService.updateUserPassword(email: email, newPasswordHash: newPasswordHash)
                    logger.info("✅ Contraseña actualizada")
                }
            }
            
            successMessage = "✅ Perfil actualizado correctamente"
            isSaving = false
            
            // Limpiar campos de contraseña después de guardar
            if !newPassword.isEmpty {
                clearPasswordFields()
            }
            
            // Notificar que el perfil se guardó exitosamente
            await onProfileSaved?()
            
        } catch {
            errorMessage = "Error al guardar: \(error.localizedDescription)"
            isSaving = false
        }
    }
}

// MARK: - Preview
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(user: User.mock(email: "test@example.com"))
    }
}
