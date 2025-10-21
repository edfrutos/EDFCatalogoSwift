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
    public func signIn(emailOrUsername: String, password: String) async {
        logger.info("🔐 Iniciando proceso de login para: \(emailOrUsername, privacy: .public)")
        isLoading = true
        errorMessage = nil
        defer { 
            isLoading = false
            logger.info("🔐 Proceso de login finalizado. Autenticado: \(self.isAuthenticated, privacy: .public)")
        }

        // Validación básica
        guard !emailOrUsername.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor, introduce usuario/email y contraseña"
            logger.warning("⚠️ Usuario o contraseña vacíos")
            return
        }

        do {
            logger.info("🔍 Autenticando usuario contra MongoDB...")
            
            // Autenticar usuario con credenciales reales (email o username)
            if let user = try await mongo.authenticateUser(emailOrUsername: emailOrUsername, password: password) {
                currentUser = user
                isAuthenticated = true
                
                // Guardar email en Keychain para persistencia (usamos email como token)
                KeychainService.shared.saveToken(user.email)
                
                logger.info("✅ Login exitoso para: \(emailOrUsername, privacy: .public)")
                logger.info("👤 Usuario: \(user.username, privacy: .public) (\(user.email, privacy: .public)), Admin: \(user.isAdmin, privacy: .public)")
                logger.info("🔑 Email guardado en Keychain para persistencia")
            } else {
                currentUser = nil
                isAuthenticated = false
                errorMessage = "Usuario/email o contraseña incorrectos"
                logger.warning("❌ Credenciales inválidas para: \(emailOrUsername, privacy: .public)")
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
    
    /// Registro de nuevo usuario
    public func register(username: String, name: String, email: String, password: String) async -> Bool {
        logger.info("📝 Iniciando proceso de registro para: \(email, privacy: .public)")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Verificar si el usuario ya existe
            if try await mongo.checkUserExists(email: email) {
                errorMessage = "Ya existe una cuenta con este email"
                logger.warning("⚠️ Usuario ya existe: \(email, privacy: .public)")
                return false
            }
            
            // Crear usuario en MongoDB
            try await mongo.createUser(username: username, name: name, email: email, password: password)
            
            // Enviar email de bienvenida
            Task {
                try? await EmailService.shared.sendWelcomeEmail(to: email, name: name)
            }
            
            // Iniciar sesión automáticamente
            await signIn(emailOrUsername: email, password: password)
            
            logger.info("✅ Registro exitoso para: \(email, privacy: .public)")
            return true
            
        } catch {
            errorMessage = "Error al crear la cuenta: \(error.localizedDescription)"
            logger.error("❌ Error en registro: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
    
    /// Solicitar recuperación de contraseña
    public func requestPasswordReset(email: String) async -> Bool {
        logger.info("🔑 Solicitando recuperación de contraseña para: \(email, privacy: .public)")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Verificar que el usuario existe
            guard try await mongo.checkUserExists(email: email) else {
                errorMessage = "No existe una cuenta con este email"
                logger.warning("⚠️ Usuario no encontrado: \(email, privacy: .public)")
                return false
            }
            
            // Generar token de recuperación (6 dígitos)
            let resetToken = String(format: "%06d", Int.random(in: 0...999999))
            
            // Guardar token en MongoDB con expiración de 1 hora
            try await mongo.savePasswordResetToken(email: email, token: resetToken)
            
            // Enviar email con el token
            try await EmailService.shared.sendPasswordResetEmail(to: email, resetToken: resetToken)
            
            logger.info("✅ Email de recuperación enviado a: \(email, privacy: .public)")
            return true
            
        } catch {
            errorMessage = "Error al enviar el email: \(error.localizedDescription)"
            logger.error("❌ Error en recuperación: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
    
    /// Restablecer contraseña con token
    public func resetPassword(email: String, token: String, newPassword: String) async -> Bool {
        logger.info("🔑 Restableciendo contraseña para: \(email, privacy: .public)")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Verificar el token
            guard try await mongo.verifyPasswordResetToken(email: email, token: token) else {
                errorMessage = "Código inválido o expirado"
                logger.warning("⚠️ Token inválido para: \(email, privacy: .public)")
                return false
            }
            
            // Actualizar contraseña
            try await mongo.updatePassword(email: email, newPassword: newPassword)
            
            // Limpiar token de recuperación
            try? await mongo.clearPasswordResetToken(email: email)
            
            logger.info("✅ Contraseña restablecida exitosamente para: \(email, privacy: .public)")
            return true
            
        } catch {
            errorMessage = "Error al restablecer la contraseña: \(error.localizedDescription)"
            logger.error("❌ Error al restablecer contraseña: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
