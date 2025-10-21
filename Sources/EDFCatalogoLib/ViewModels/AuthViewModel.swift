import Foundation
import os.log

@MainActor
public final class AuthViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.edefrutos.catalogo", category: "Authentication")
    
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private let mongo = MongoService.shared
    
    public init() {
        logger.info("🔐 AuthViewModel inicializado")
    }

    /// Login principal con validación real de credenciales contra MongoDB
    public func signIn(email: String, password: String) async {
        logger.info("🔐 Iniciando proceso de login para: \(email, privacy: .public)")
        isLoading = true
        errorMessage = nil
        defer { 
            isLoading = false
            logger.info("🔐 Proceso de login finalizado. Autenticado: \(self.isAuthenticated, privacy: .public)")
        }

        // Validación básica
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor, introduce email y contraseña"
            logger.warning("⚠️ Email o contraseña vacíos")
            return
        }
        
        guard email.contains("@") else {
            errorMessage = "Por favor, introduce un email válido"
            logger.warning("⚠️ Email inválido")
            return
        }

        do {
            logger.info("🔍 Autenticando usuario contra MongoDB...")
            
            // Autenticar usuario con credenciales reales
            if let user = try await mongo.authenticateUser(email: email, password: password) {
                currentUser = user
                isAuthenticated = true
                
                // Guardar email en Keychain para persistencia (usamos email como token)
                KeychainService.shared.saveToken(user.email)
                
                logger.info("✅ Login exitoso para: \(email, privacy: .public)")
                logger.info("👤 Usuario: \(user.email, privacy: .public), Admin: \(user.isAdmin, privacy: .public)")
                logger.info("🔑 Email guardado en Keychain para persistencia")
            } else {
                currentUser = nil
                isAuthenticated = false
                errorMessage = "Email o contraseña incorrectos"
                logger.warning("❌ Credenciales inválidas para: \(email, privacy: .public)")
            }
        } catch {
            currentUser = nil
            isAuthenticated = false
            errorMessage = "Error al conectar con el servidor: \(error.localizedDescription)"
            logger.error("❌ Error en login: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Intenta restaurar la sesión desde el Keychain al iniciar la app
    public func restoreSession() async {
        logger.info("🔐 Intentando restaurar sesión...")
        
        guard let userEmail = KeychainService.shared.getToken() else {
            logger.warning("⚠️ No hay token guardado")
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        logger.info("🔑 Email encontrado en Keychain: \(userEmail, privacy: .public)")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Buscar usuario por email en MongoDB
            logger.info("🔍 Buscando usuario en MongoDB...")
            
            if let user = try await mongo.getUser(email: userEmail) {
                currentUser = user
                isAuthenticated = true
                logger.info("✅ Sesión restaurada exitosamente para: \(user.email, privacy: .public)")
                logger.info("👤 Usuario: \(user.name, privacy: .public), Admin: \(user.isAdmin, privacy: .public)")
            } else {
                // Usuario no encontrado, limpiar token
                logger.warning("⚠️ Usuario no encontrado en MongoDB, limpiando token")
                KeychainService.shared.deleteToken()
                isAuthenticated = false
                currentUser = nil
            }
            
        } catch {
            logger.error("❌ Error al restaurar sesión: \(error.localizedDescription, privacy: .public)")
            // En caso de error, limpiar token
            KeychainService.shared.deleteToken()
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    /// Recarga el usuario actual desde MongoDB
    public func reloadCurrentUser() async {
        guard let email = currentUser?.email else {
            logger.warning("⚠️ No hay usuario actual para recargar")
            return
        }
        
        logger.info("🔄 Recargando usuario: \(email, privacy: .public)")
        
        do {
            if let user = try await mongo.getUser(email: email) {
                currentUser = user
                logger.info("✅ Usuario recargado exitosamente")
            } else {
                logger.warning("⚠️ Usuario no encontrado al recargar")
            }
        } catch {
            logger.error("❌ Error al recargar usuario: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    /// Cierre de sesión
    public func signOut() {
        logger.info("🔐 Cerrando sesión para: \(self.currentUser?.email ?? "usuario desconocido", privacy: .public)")
        
        // Eliminar token del Keychain
        KeychainService.shared.deleteToken()
        
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        
        logger.info("✅ Sesión cerrada correctamente")
    }
}
