import Foundation
import CryptoKit
import MongoSwift

extension MongoService {
    /// Verifica las credenciales del usuario contra MongoDB (por email o username)
    public func authenticateUser(emailOrUsername: String, password: String) async throws -> User? {
        print("🔍 Autenticando usuario: \(emailOrUsername)")
        
        let users = try await usersCollection()
        
        // Buscar usuario por Email O Username
        let query: BSONDocument = [
            "$or": .array([
                .document(["Email": .string(emailOrUsername)]),
                .document(["Username": .string(emailOrUsername)])
            ])
        ]
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
        let username = userDoc["Username"]?.stringValue ?? userDoc["Email"]?.stringValue?.components(separatedBy: "@").first ?? "usuario"
        let name = userDoc["Name"]?.stringValue ?? "Usuario"
        
        // Convertir Role a isAdmin
        let role = userDoc["Role"]?.stringValue ?? ""
        let isAdmin = (role.lowercased() == "admin")
        
        // Campos opcionales adicionales
        let fullName = userDoc["FullName"]?.stringValue
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
            username: username,
            name: name,
            isAdmin: isAdmin,
            fullName: fullName,
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
        username: String,
        name: String,
        fullName: String?,
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
            "Username": .string(username),
            "Name": .string(name)
        ]
        
        // Agregar campos opcionales solo si no son nil
        if let fullName = fullName, !fullName.isEmpty {
            updateDoc["FullName"] = .string(fullName)
        }
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
        let username = userDoc["Username"]?.stringValue ?? userDoc["Email"]?.stringValue?.components(separatedBy: "@").first ?? "usuario"
        let name = userDoc["Name"]?.stringValue ?? "Usuario"
        
        // Convertir Role a isAdmin
        let role = userDoc["Role"]?.stringValue ?? ""
        let isAdmin = (role.lowercased() == "admin")
        
        // Campos opcionales
        let fullName = userDoc["FullName"]?.stringValue
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
            username: username,
            name: name,
            isAdmin: isAdmin,
            fullName: fullName,
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
    
    /// Crea un nuevo usuario en MongoDB
    public func createUser(username: String, name: String, email: String, password: String) async throws {
        print("📝 Creando nuevo usuario: \(email)")
        
        let users = try await usersCollection()
        
        // Hash de la contraseña con SHA256
        let passwordData = password.data(using: .utf8)!
        let hash = SHA256.hash(data: passwordData)
        let hashData = Data(hash)
        let passwordHash = hashData.base64EncodedString()
        
        let userDoc: BSONDocument = [
            "_id": .objectID(BSONObjectID()),
            "Email": .string(email),
            "Username": .string(username),
            "Name": .string(name),
            "Password": .string(passwordHash),
            "Role": .string("user"),
            "IsActive": .bool(true),
            "CreatedAt": .datetime(Date())
        ]
        
        _ = try await users.insertOne(userDoc)
        print("✅ Usuario creado exitosamente")
    }
    
    /// Guarda token de recuperación de contraseña
    public func savePasswordResetToken(email: String, token: String) async throws {
        print("🔑 Guardando token de recuperación para: \(email)")
        
        let users = try await usersCollection()
        let filter: BSONDocument = ["Email": .string(email)]
        
        // Expira en 1 hora
        let expiresAt = Date().addingTimeInterval(3600)
        
        let update: BSONDocument = [
            "$set": .document([
                "ResetToken": .string(token),
                "ResetTokenExpires": .datetime(expiresAt)
            ])
        ]
        
        let result = try await users.updateOne(filter: filter, update: update)
        
        if let matchedCount = result?.matchedCount, matchedCount > 0 {
            print("✅ Token guardado correctamente")
        } else {
            throw NSError(domain: "MongoService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }
    }
    
    /// Verifica el token de recuperación de contraseña
    public func verifyPasswordResetToken(email: String, token: String) async throws -> Bool {
        print("🔍 Verificando token de recuperación para: \(email)")
        
        let users = try await usersCollection()
        let query: BSONDocument = ["Email": .string(email)]
        
        let cursor = try await users.find(query)
        let results = try await cursor.toArray()
        
        guard let userDoc = results.first else {
            print("❌ Usuario no encontrado")
            return false
        }
        
        guard let storedToken = userDoc["ResetToken"]?.stringValue,
              let expiresAt = userDoc["ResetTokenExpires"]?.dateValue else {
            print("❌ Token no encontrado en el documento")
            return false
        }
        
        // Verificar que el token coincida
        guard storedToken == token else {
            print("❌ Token no coincide")
            return false
        }
        
        // Verificar que no haya expirado
        guard expiresAt > Date() else {
            print("❌ Token expirado")
            return false
        }
        
        print("✅ Token válido")
        return true
    }
    
    /// Actualiza la contraseña de un usuario
    public func updatePassword(email: String, newPassword: String) async throws {
        print("🔑 Actualizando contraseña para: \(email)")
        
        // Hash de la nueva contraseña con SHA256
        let passwordData = newPassword.data(using: .utf8)!
        let hash = SHA256.hash(data: passwordData)
        let hashData = Data(hash)
        let passwordHash = hashData.base64EncodedString()
        
        let users = try await usersCollection()
        let filter: BSONDocument = ["Email": .string(email)]
        let update: BSONDocument = ["$set": ["Password": .string(passwordHash)]]
        
        let result = try await users.updateOne(filter: filter, update: update)
        
        if let matchedCount = result?.matchedCount, matchedCount > 0 {
            print("✅ Contraseña actualizada correctamente")
        } else {
            throw NSError(domain: "MongoService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }
    }
    
    /// Limpia el token de recuperación de contraseña
    public func clearPasswordResetToken(email: String) async throws {
        print("🧽 Limpiando token de recuperación para: \(email)")
        
        let users = try await usersCollection()
        let filter: BSONDocument = ["Email": .string(email)]
        
        let update: BSONDocument = [
            "$unset": .document([
                "ResetToken": "",
                "ResetTokenExpires": ""
            ])
        ]
        
        _ = try await users.updateOne(filter: filter, update: update)
        print("✅ Token limpiado correctamente")
    }
    
    // MARK: - Métodos administrativos
    
    /// Lista todos los usuarios (solo para administradores)
    public func listAllUsers() async throws -> [User] {
        print("📋 Obteniendo lista completa de usuarios")
        
        let users = try await usersCollection()
        let cursor = try await users.find([:]) // Query vacío para obtener todos
        let userDocs = try await cursor.toArray()
        
        var usersList: [User] = []
        
        for userDoc in userDocs {
            let userId = userDoc["_id"]?.objectIDValue ?? BSONObjectID()
            let email = userDoc["Email"]?.stringValue ?? ""
            let username = userDoc["Username"]?.stringValue ?? userDoc["Email"]?.stringValue?.components(separatedBy: "@").first ?? "usuario"
            let name = userDoc["Name"]?.stringValue ?? "Usuario"
            
            // Convertir Role a isAdmin
            let role = userDoc["Role"]?.stringValue ?? ""
            let isAdmin = (role.lowercased() == "admin")
            
            // Campos opcionales
            let fullName = userDoc["FullName"]?.stringValue
            let phone = userDoc["Phone"]?.stringValue
            let company = userDoc["Company"]?.stringValue
            let address = userDoc["Address"]?.stringValue
            let occupation = userDoc["Occupation"]?.stringValue
            let profileImageUrl = userDoc["ProfileImageUrl"]?.stringValue
            let isActive = userDoc["IsActive"]?.boolValue
            let createdAt = userDoc["CreatedAt"]?.dateValue
            let lastLoginAt = userDoc["LastLoginAt"]?.dateValue
            
            let user = User(
                _id: userId,
                email: email,
                username: username,
                name: name,
                isAdmin: isAdmin,
                fullName: fullName,
                phone: phone,
                company: company,
                address: address,
                occupation: occupation,
                profileImageUrl: profileImageUrl,
                isActive: isActive,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt
            )
            
            usersList.append(user)
        }
        
        print("✅ Obtenidos \(usersList.count) usuarios")
        return usersList
    }
    
    /// Actualiza el rol de un usuario (admin/user)
    public func updateUserRole(userId: String, isAdmin: Bool) async throws {
        print("👑 Actualizando rol de usuario: \(userId) - Admin: \(isAdmin)")
        
        let users = try await usersCollection()
        
        guard let objectId = try? BSONObjectID(userId) else {
            throw NSError(domain: "MongoService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID de usuario inválido"])
        }
        
        let filter: BSONDocument = ["_id": .objectID(objectId)]
        let role = isAdmin ? "admin" : "user"
        let update: BSONDocument = ["$set": ["Role": .string(role)]]
        
        let result = try await users.updateOne(filter: filter, update: update)
        
        if let matchedCount = result?.matchedCount, matchedCount > 0 {
            print("✅ Rol actualizado correctamente")
        } else {
            print("⚠️ Usuario no encontrado")
            throw NSError(domain: "MongoService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }
    }
    
    /// Actualiza el estado activo de un usuario
    public func updateUserActiveStatus(userId: String, isActive: Bool) async throws {
        print("🔄 Actualizando estado de usuario: \(userId) - Activo: \(isActive)")
        
        let users = try await usersCollection()
        
        guard let objectId = try? BSONObjectID(userId) else {
            throw NSError(domain: "MongoService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID de usuario inválido"])
        }
        
        let filter: BSONDocument = ["_id": .objectID(objectId)]
        let update: BSONDocument = ["$set": ["IsActive": .bool(isActive)]]
        
        let result = try await users.updateOne(filter: filter, update: update)
        
        if let matchedCount = result?.matchedCount, matchedCount > 0 {
            print("✅ Estado actualizado correctamente")
        } else {
            print("⚠️ Usuario no encontrado")
            throw NSError(domain: "MongoService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }
    }
    
    /// Actualiza información completa de un usuario (para administradores)
    public func updateUserByAdmin(
        userId: String,
        email: String,
        username: String,
        name: String,
        fullName: String?,
        phone: String?,
        company: String?,
        address: String?,
        occupation: String?,
        profileImageUrl: String?,
        isAdmin: Bool,
        isActive: Bool
    ) async throws {
        print("📝 Actualizando usuario completo: \(userId)")
        
        let users = try await usersCollection()
        
        guard let objectId = try? BSONObjectID(userId) else {
            throw NSError(domain: "MongoService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID de usuario inválido"])
        }
        
        let filter: BSONDocument = ["_id": .objectID(objectId)]
        
        var updateDoc: BSONDocument = [
            "Email": .string(email),
            "Username": .string(username),
            "Name": .string(name),
            "Role": .string(isAdmin ? "admin" : "user"),
            "IsActive": .bool(isActive)
        ]
        
        // Agregar campos opcionales solo si no son nil
        if let fullName = fullName, !fullName.isEmpty {
            updateDoc["FullName"] = .string(fullName)
        }
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
            print("✅ Usuario actualizado correctamente")
        } else {
            print("⚠️ Usuario no encontrado")
            throw NSError(domain: "MongoService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }
    }
    
    /// Elimina un usuario por completo (solo para administradores)
    public func deleteUser(userId: String) async throws {
        print("🗑️ Eliminando usuario: \(userId)")
        
        let users = try await usersCollection()
        
        guard let objectId = try? BSONObjectID(userId) else {
            throw NSError(domain: "MongoService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID de usuario inválido"])
        }
        
        let filter: BSONDocument = ["_id": .objectID(objectId)]
        
        let result = try await users.deleteOne(filter)
        
        if let deletedCount = result?.deletedCount, deletedCount > 0 {
            print("✅ Usuario eliminado correctamente")
        } else {
            print("⚠️ Usuario no encontrado")
            throw NSError(domain: "MongoService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }
    }
}
