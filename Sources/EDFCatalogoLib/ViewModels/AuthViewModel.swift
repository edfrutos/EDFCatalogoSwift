import Foundation

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private let mongo = MongoService.shared
    
    public init() {
        print("🔐 AuthViewModel inicializado")
    }

    /// Login principal con validación real de credenciales contra MongoDB
    public func signIn(email: String, password: String) async {
        print("🔐 Iniciando proceso de login para: \(email)")
        isLoading = true
        errorMessage = nil
        defer { 
            isLoading = false
            print("🔐 Proceso de login finalizado. Autenticado: \(isAuthenticated)")
        }

        // Validación básica
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor, introduce email y contraseña"
            print("⚠️ Email o contraseña vacíos")
            return
        }
        
        guard email.contains("@") else {
            errorMessage = "Por favor, introduce un email válido"
            print("⚠️ Email inválido")
            return
        }

        do {
            print("🔍 Autenticando usuario contra MongoDB...")
            
            // Autenticar usuario con credenciales reales
            if let user = try await mongo.authenticateUser(email: email, password: password) {
                currentUser = user
                isAuthenticated = true
                
                // Guardar email en Keychain para persistencia (usamos email como token)
                KeychainService.shared.saveToken(user.email)
                
                print("✅ Login exitoso para: \(email)")
                print("👤 Usuario: \(user.email), Admin: \(user.isAdmin)")
                print("🔑 Email guardado en Keychain para persistencia")
            } else {
                currentUser = nil
                isAuthenticated = false
                errorMessage = "Email o contraseña incorrectos"
                print("❌ Credenciales inválidas para: \(email)")
            }
        } catch {
            currentUser = nil
            isAuthenticated = false
            errorMessage = "Error al conectar con el servidor: \(error.localizedDescription)"
            print("❌ Error en login: \(error)")
            print("❌ Detalles: \(error.localizedDescription)")
        }
    }

    /// Intenta restaurar la sesión desde el Keychain al iniciar la app
    public func restoreSession() async {
        print("🔐 Intentando restaurar sesión...")
        
        guard let userEmail = KeychainService.shared.getToken() else {
            print("⚠️ No hay token guardado")
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        print("🔑 Email encontrado en Keychain: \(userEmail)")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Buscar usuario por email en MongoDB
            print("🔍 Buscando usuario en MongoDB...")
            
            if let user = try await mongo.getUser(email: userEmail) {
                currentUser = user
                isAuthenticated = true
                print("✅ Sesión restaurada exitosamente para: \(user.email)")
                print("👤 Usuario: \(user.name), Admin: \(user.isAdmin)")
            } else {
                // Usuario no encontrado, limpiar token
                print("⚠️ Usuario no encontrado en MongoDB, limpiando token")
                KeychainService.shared.deleteToken()
                isAuthenticated = false
                currentUser = nil
            }
            
        } catch {
            print("❌ Error al restaurar sesión: \(error)")
            print("❌ Detalles: \(error.localizedDescription)")
            // En caso de error, limpiar token
            KeychainService.shared.deleteToken()
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    /// Cierre de sesión
    public func signOut() {
        print("🔐 Cerrando sesión para: \(currentUser?.email ?? "usuario desconocido")")
        
        // Eliminar token del Keychain
        KeychainService.shared.deleteToken()
        
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        
        print("✅ Sesión cerrada correctamente")
    }
}
