import Foundation
@preconcurrency import SwiftBSON // para rebajar avisos Sendable con SwiftBSON

// MARK: - Modelos principales

public struct Catalog: Identifiable, Codable, @unchecked Sendable {
    public var id: String { _id.hex }
    public var _id: BSONObjectID
    public var name: String
    public var description: String
    public var userId: String
    public var columns: [String]
    public var rows: [CatalogRow]
    public var legacyRows: [[String:String]]?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        _id: BSONObjectID = BSONObjectID(),
        name: String,
        description: String,
        userId: String,
        columns: [String],
        rows: [CatalogRow] = [],
        legacyRows: [[String:String]]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self._id = _id
        self.name = name
        self.description = description
        self.userId = userId
        self.columns = columns
        self.rows = rows
        self.legacyRows = legacyRows
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CatalogRow: Identifiable, Codable, @unchecked Sendable {
    public var id: String { _id.hex }
    public var _id: BSONObjectID
    public var data: [String:String]
    public var files: RowFiles
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        _id: BSONObjectID = BSONObjectID(),
        data: [String:String],
        files: RowFiles = RowFiles(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self._id = _id
        self.data = data
        self.files = files
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Archivos asociados a una fila (S3)

public struct RowFiles: Codable, @unchecked Sendable {
    public var image: String?
    public var images: [String]
    public var document: String?
    public var documents: [String]
    public var multimedia: String?
    public var multimediaFiles: [String]

    public init(
        image: String? = nil,
        images: [String] = [],
        document: String? = nil,
        documents: [String] = [],
        multimedia: String? = nil,
        multimediaFiles: [String] = []
    ) {
        self.image = image
        self.images = images
        self.document = document
        self.documents = documents
        self.multimedia = multimedia
        self.multimediaFiles = multimediaFiles
    }
}
