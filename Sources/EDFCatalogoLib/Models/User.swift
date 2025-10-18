import Foundation
@preconcurrency import SwiftBSON

/// Modelo de usuario (única definición en el proyecto).
public struct User: Identifiable, Codable, @unchecked Sendable {
    public var id: String { _id.hex }
    public var _id: BSONObjectID
    public var email: String
    public var name: String
    public var isAdmin: Bool

    public init(_id: BSONObjectID, email: String, name: String, isAdmin: Bool) {
        self._id = _id
        self.email = email
        self.name = name
        self.isAdmin = isAdmin
    }

    // Mock para login de prueba
    public static func mock(email: String) -> User {
        User(_id: BSONObjectID(), email: email, name: "Usuario Demo", isAdmin: true)
    }
}
