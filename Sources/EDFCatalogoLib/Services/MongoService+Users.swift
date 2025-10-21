import Foundation
import CryptoKit
import MongoSwift

extension MongoService {
    /// Verifica las credenciales del usuario contra MongoDB
    public func authenticateUser(email: String, password: String) async throws -> User? {
        print("🔍 Autenticando usuario: \(email)")
        
        let users = try await usersCollection()
        
        // Buscar usuario por Email (con mayúscula como está en MongoDB)
        let query: BSONDocument = ["Email": .string(email)]
        print("📝 Query: \(query)")
        
        let cursor = try await users.find(query)
        let results = try await cursor.toArray()
        
        print("📊 Resultados encontrados: \(results.count)")
        
        guard let userDoc = results.first else {
            print("❌ Usuario no encontrado")
            return nil
        }
        
        print("📄 Documento encontrado: \(userDoc)")
        
        // Extraer datos del documento (con mayúsculas como están en MongoDB)
        guard let userEmail = userDoc["Email"]?.stringValue else {
            print("❌ Email no encontrado en documento")
            return nil
        }
        
        guard let storedPassword = userDoc["Password"]?.stringValue else {
            print("❌ Password no encontrado en documento")
            return nil
        }
        
        print("🔑 Password almacenado: \(storedPassword.prefix(20))...")
        print("🔑 Password ingresado: \(password)")
        
        // Intentar múltiples métodos de verificación
        var passwordMatch = false
        
        // Método 1: Comparación directa (texto plano)
        if storedPassword == password {
            print("✅ Contraseña coincide (texto plano)")
            passwordMatch = true
        }
        
        // Método 2: SHA256
        if !passwordMatch, let passwordData = password.data(using: .utf8) {
            let hash = SHA256.hash(data: passwordData)
            let hashData = Data(hash)
            let passwordHash = hashData.base64EncodedString()
            
            if storedPassword == passwordHash {
                print("✅ Contraseña coincide (SHA256)")
                passwordMatch = true
            }
        }
        
        // Método 3: SHA512
        if !passwordMatch, let passwordData = password.data(using: .utf8) {
            let hash = SHA512.hash(data: passwordData)
            let hashData = Data(hash)
            let passwordHash = hashData.base64EncodedString()
            
            if storedPassword == passwordHash {
                print("✅ Contraseña coincide (SHA512)")
                passwordMatch = true
            }
        }
        
        // Método 4: SHA384
        if !passwordMatch, let passwordData = password.data(using: .utf8) {
            let hash = SHA384.hash(data: passwordData)
            let hashData = Data(hash)
            let passwordHash = hashData.base64EncodedString()
            
            if storedPassword == passwordHash {
                print("✅ Contraseña coincide (SHA384)")
                passwordMatch = true
            }
        }
        
        // Verificar si algún método coincidió
        guard passwordMatch else {
            print("❌ Contraseña incorrecta - ningún método coincidió")
            print("   Hash almacenado: \(storedPassword)")
            return nil
        }
        
        // Extraer campos opcionales
        let userId = userDoc["_id"]?.objectIDValue ?? BSONObjectID()
        let name = userDoc["Name"]?.stringValue ?? "Usuario"
        
        // Convertir Role a isAdmin
        let role = userDoc["Role"]?.stringValue ?? ""
        let isAdmin = (role.lowercased() == "admin")
        
        // Campos opcionales adicionales
        let phone = userDoc["Phone"]?.stringValue
        let company = userDoc["Company"]?.stringValue
        let address = userDoc["Address"]?.stringValue
        let occupation = userDoc["Occupation"]?.stringValue
        let profileImageUrl = userDoc["ProfileImageUrl"]?.stringValue
        let isActive = userDoc["IsActive"]?.boolValue
        let createdAt = userDoc["CreatedAt"]?.dateValue
        let lastLoginAt = userDoc["LastLoginAt"]?.dateValue
        
        print("✅ Usuario autenticado correctamente")
        print("   Email: \(userEmail)")
        print("   Name: \(name)")
        print("   Role: \(role)")
        print("   IsAdmin: \(isAdmin)")
        
        return User(
            _id: userId,
            email: userEmail,
            name: name,
            isAdmin: isAdmin,
            phone: phone,
            company: company,
            address: address,
            occupation: occupation,
            profileImageUrl: profileImageUrl,
            isActive: isActive,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt
        )
    }
    
    /// Actualiza el perfil de usuario en MongoDB
    public func updateUserProfile(
        email: String,
        name: String,
        phone: String?,
        company: String?,
        address: String?,
        occupation: String?,
        profileImageUrl: String?
    ) async throws {
        print("💾 Actualizando perfil de usuario: \(email)")
        
        let users = try await usersCollection()
        let filter: BSONDocument = ["Email": .string(email)]
        
        var updateDoc: BSONDocument = [
            "Name": .string(name)
        ]
        
        // Agregar campos opcionales solo si no son nil
        if let phone = phone, !phone.isEmpty {
            updateDoc["Phone"] = .string(phone)
        }
        if let company = company, !company.isEmpty {
            updateDoc["Company"] = .string(company)
        }
        if let address = address, !address.isEmpty {
            updateDoc["Address"] = .string(address)
        }
        if let occupation = occupation, !occupation.isEmpty {
            updateDoc["Occupation"] = .string(occupation)
        }
        if let profileImageUrl = profileImageUrl, !profileImageUrl.isEmpty {
            updateDoc["ProfileImageUrl"] = .string(profileImageUrl)
        }
        
        let update: BSONDocument = ["$set": .document(updateDoc)]
        
        let result = try await users.updateOne(filter: filter, update: update)
        
        if let matchedCount = result?.matchedCount, matchedCount > 0 {
            print("✅ Perfil actualizado correctamente")
        } else {
            print("⚠️ Usuario no encontrado")
            throw NSError(domain: "MongoService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }
    }
    
    /// Actualiza la contraseña de un usuario
    public func updateUserPassword(email: String, newPasswordHash: String) async throws {
        print("🔑 Actualizando contraseña para: \(email)")
        
        let users = try await usersCollection()
        let filter: BSONDocument = ["Email": .string(email)]
        let update: BSONDocument = ["$set": ["Password": .string(newPasswordHash)]]
        
        let result = try await users.updateOne(filter: filter, update: update)
        
        if let matchedCount = result?.matchedCount, matchedCount > 0 {
            print("✅ Contraseña actualizada correctamente")
        } else {
            print("⚠️ Usuario no encontrado")
            throw NSError(domain: "MongoService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }
    }
    
    /// Comprueba si existe un usuario por email
    public func checkUserExists(email: String) async throws -> Bool {
        print("🔍 Verificando existencia de usuario: \(email)")
        
        let users = try await usersCollection()
        // Usar Email con mayúscula como está en MongoDB
        let query: BSONDocument = ["Email": .string(email)]
        
        let cursor = try await users.find(query)
        let results = try await cursor.toArray()
        
        let exists = !results.isEmpty
        print(exists ? "✅ Usuario existe" : "❌ Usuario no existe")
        
        return exists
    }
    
    /// Obtiene un usuario por email
    public func getUser(email: String) async throws -> User? {
        print("🔍 Obteniendo usuario: \(email)")
        
        let users = try await usersCollection()
        // Usar Email con mayúscula como está en MongoDB
        let query: BSONDocument = ["Email": .string(email)]
        
        let cursor = try await users.find(query)
        let results = try await cursor.toArray()
        
        guard let userDoc = results.first else {
            print("❌ Usuario no encontrado")
            return nil
        }
        
        let userId = userDoc["_id"]?.objectIDValue ?? BSONObjectID()
        let userEmail = userDoc["Email"]?.stringValue ?? email
        let name = userDoc["Name"]?.stringValue ?? "Usuario"
        
        // Convertir Role a isAdmin
        let role = userDoc["Role"]?.stringValue ?? ""
        let isAdmin = (role.lowercased() == "admin")
        
        // Campos opcionales
        let phone = userDoc["Phone"]?.stringValue
        let company = userDoc["Company"]?.stringValue
        let address = userDoc["Address"]?.stringValue
        let occupation = userDoc["Occupation"]?.stringValue
        let profileImageUrl = userDoc["ProfileImageUrl"]?.stringValue
        let isActive = userDoc["IsActive"]?.boolValue
        let createdAt = userDoc["CreatedAt"]?.dateValue
        let lastLoginAt = userDoc["LastLoginAt"]?.dateValue
        
        print("✅ Usuario obtenido correctamente")
        
        return User(
            _id: userId,
            email: userEmail,
            name: name,
            isAdmin: isAdmin,
            phone: phone,
            company: company,
            address: address,
            occupation: occupation,
            profileImageUrl: profileImageUrl,
            isActive: isActive,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt
        )
    }
}
