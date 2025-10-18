import Foundation
import Security

/// Servicio de Keychain (no-actor) – lo hacemos @MainActor para evitar warnings de concurrencia.
@MainActor
final class KeychainService {
    static let shared = KeychainService()
    private let service = "EDFCatalogoSwift"
    private let tokenKey = "authToken"

    private init() {}

    @discardableResult
    func set(key: String, value: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    func remove(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Token Management
    
    /// Guarda el token de autenticación en el Keychain
    @discardableResult
    func saveToken(_ token: String) -> Bool {
        print("🔑 Guardando token en Keychain")
        let success = set(key: tokenKey, value: token)
        if success {
            print("✅ Token guardado exitosamente")
        } else {
            print("❌ Error al guardar token")
        }
        return success
    }
    
    /// Obtiene el token de autenticación del Keychain
    func getToken() -> String? {
        print("🔑 Obteniendo token del Keychain")
        let token = get(key: tokenKey)
        if token != nil {
            print("✅ Token encontrado")
        } else {
            print("⚠️ No se encontró token")
        }
        return token
    }
    
    /// Elimina el token de autenticación del Keychain
    @discardableResult
    func deleteToken() -> Bool {
        print("🔑 Eliminando token del Keychain")
        let success = remove(key: tokenKey)
        if success {
            print("✅ Token eliminado exitosamente")
        } else {
            print("⚠️ No se pudo eliminar el token (puede que no existiera)")
        }
        return success
    }
}
