import Foundation
import MongoSwift

extension MongoService {
    /// Comprueba si existe un usuario por email (stub). Sustituye por lógica real cuando conectes Mongo.
    public func checkUserExists(email: String) async throws -> Bool {
        // Ejemplo de lógica real (cuando conectes):
        // let users = try await usersCollection()
        // let cursor = try await users.find(["email": .string(email)])
        // return try await cursor.toArray().isEmpty == false

        // Stub mientras tanto
        return email.contains("@")
    }
}
