import Foundation
@preconcurrency import SwiftBSON

/// Modelo de usuario completo
public struct User: Identifiable, Codable, @unchecked Sendable {
    public var id: String { _id.hex }
    public var _id: BSONObjectID
    
    // Campos obligatorios
    public var email: String
    public var name: String
    public var isAdmin: Bool
    
    // Campos opcionales
    public var phone: String?
    public var company: String?
    public var address: String?
    public var occupation: String?
    public var profileImageUrl: String?
    public var isActive: Bool?
    public var createdAt: Date?
    public var lastLoginAt: Date?

    public init(
        _id: BSONObjectID,
        email: String,
        name: String,
        isAdmin: Bool,
        phone: String? = nil,
        company: String? = nil,
        address: String? = nil,
        occupation: String? = nil,
        profileImageUrl: String? = nil,
        isActive: Bool? = true,
        createdAt: Date? = nil,
        lastLoginAt: Date? = nil
    ) {
        self._id = _id
        self.email = email
        self.name = name
        self.isAdmin = isAdmin
        self.phone = phone
        self.company = company
        self.address = address
        self.occupation = occupation
        self.profileImageUrl = profileImageUrl
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }

    // Mock para login de prueba
    public static func mock(email: String) -> User {
        User(_id: BSONObjectID(), email: email, name: "Usuario Demo", isAdmin: true)
    }
}
