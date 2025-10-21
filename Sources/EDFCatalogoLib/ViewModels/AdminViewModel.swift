import Foundation

@MainActor
public class AdminViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var selectedUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    @Published var editingUser: User?
    @Published var showEditForm = false
    @Published var showDeleteConfirmation = false
    @Published var userToDelete: User?
    
    private let mongoService: MongoService
    
    public init(mongoService: MongoService) {
        self.mongoService = mongoService
    }
    
    // MARK: - Métodos públicos
    
    /// Carga la lista completa de usuarios
    public func loadUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            users = try await mongoService.listAllUsers()
            print("✅ Usuarios cargados: \(users.count)")
        } catch {
            errorMessage = "Error al cargar usuarios: \(error.localizedDescription)"
            print("❌ Error: \(errorMessage ?? "")")
        }
        
        isLoading = false
    }
    
    /// Selecciona un usuario
    public func selectUser(_ user: User) {
        selectedUser = user
        editingUser = user
    }
    
    /// Abre el formulario de edición
    public func openEditForm() {
        showEditForm = true
    }
    
    /// Cierra el formulario de edición
    public func closeEditForm() {
        showEditForm = false
        editingUser = nil
    }
    
    /// Abre el diálogo de confirmación de eliminación
    public func openDeleteConfirmation(for user: User) {
        userToDelete = user
        showDeleteConfirmation = true
    }
    
    /// Cierra el diálogo de confirmación
    public func closeDeleteConfirmation() {
        showDeleteConfirmation = false
        userToDelete = nil
    }
    
    /// Actualiza la información completa de un usuario
    public func updateUser(_ user: User) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await mongoService.updateUserByAdmin(
                userId: user.id,
                email: user.email,
                username: user.username,
                name: user.name,
                fullName: user.fullName,
                phone: user.phone,
                company: user.company,
                address: user.address,
                occupation: user.occupation,
                profileImageUrl: user.profileImageUrl,
                isAdmin: user.isAdmin,
                isActive: user.isActive ?? true
            )
            
            successMessage = "Usuario actualizado correctamente"
            
            // Actualizar la lista
            await loadUsers()
            closeEditForm()
            
        } catch {
            errorMessage = "Error al actualizar usuario: \(error.localizedDescription)"
            print("❌ Error: \(errorMessage ?? "")")
        }
        
        isLoading = false
    }
    
    /// Cambia el rol de un usuario
    public func updateUserRole(_ user: User, isAdmin: Bool) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await mongoService.updateUserRole(userId: user.id, isAdmin: isAdmin)
            
            successMessage = "Rol actualizado correctamente"
            
            // Actualizar la lista
            await loadUsers()
            
            if selectedUser?.id == user.id {
                selectedUser = nil
            }
            
        } catch {
            errorMessage = "Error al actualizar rol: \(error.localizedDescription)"
            print("❌ Error: \(errorMessage ?? "")")
        }
        
        isLoading = false
    }
    
    /// Cambia el estado activo de un usuario
    public func updateUserActiveStatus(_ user: User, isActive: Bool) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await mongoService.updateUserActiveStatus(userId: user.id, isActive: isActive)
            
            successMessage = isActive ? "Usuario activado" : "Usuario desactivado"
            
            // Actualizar la lista
            await loadUsers()
            
            if selectedUser?.id == user.id {
                selectedUser = nil
            }
            
        } catch {
            errorMessage = "Error al actualizar estado: \(error.localizedDescription)"
            print("❌ Error: \(errorMessage ?? "")")
        }
        
        isLoading = false
    }
    
    /// Elimina un usuario
    public func deleteUser(_ user: User) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await mongoService.deleteUser(userId: user.id)
            
            successMessage = "Usuario eliminado correctamente"
            
            // Actualizar la lista
            await loadUsers()
            closeDeleteConfirmation()
            
            if selectedUser?.id == user.id {
                selectedUser = nil
            }
            
        } catch {
            errorMessage = "Error al eliminar usuario: \(error.localizedDescription)"
            print("❌ Error: \(errorMessage ?? "")")
        }
        
        isLoading = false
    }
    
    /// Limpia los mensajes después de un tiempo
    public func clearMessages() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.errorMessage = nil
            self.successMessage = nil
        }
    }
}
