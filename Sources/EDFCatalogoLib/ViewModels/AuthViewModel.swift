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

    /// Login principal. Mantiene la firma (email, password) para no romper llamadas existentes.
    /// Nota: ahora está aislado al MainActor (la clase entera), así que no hace falta `Task { }` ni `MainActor.run`.
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
            print("🔍 Verificando existencia del usuario...")
            let exists = try await mongo.checkUserExists(email: email)
            print("✅ Verificación completada. Usuario existe: \(exists)")
            
            if exists {
                // Sustituye por el usuario real recuperado de tu backend cuando lo tengas
                currentUser = User.mock(email: email)
                isAuthenticated = true
                print("✅ Login exitoso para: \(email)")
            } else {
                currentUser = nil
                isAuthenticated = false
                errorMessage = "Credenciales no válidas."
                print("❌ Credenciales no válidas para: \(email)")
            }
        } catch {
            currentUser = nil
            isAuthenticated = false
            errorMessage = "Error al conectar: \(error.localizedDescription)"
            print("❌ Error en login: \(error)")
            print("❌ Detalles: \(error.localizedDescription)")
        }
    }

    /// Cierre de sesión. No es `async` ni usa `Task` porque la clase está aislada al MainActor.
    public func signOut() {
        print("🔐 Cerrando sesión para: \(currentUser?.email ?? "usuario desconocido")")
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }
}
