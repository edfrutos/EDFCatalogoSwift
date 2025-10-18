import Foundation
import MongoSwift
@preconcurrency import SwiftBSON
// Usa los modelos de Sources/Models/Catalog.swift (NO redefinirlos aquí)

extension MongoService {

    /// Obtiene catálogos (stub: devuelve array vacío hasta conectar a datos reales).
    public func getCatalogs(userId: String, isAdmin: Bool) async throws -> [Catalog] {
        // TODO: Implementación real con MongoDB (find/aggregation).
        // Devuelve [] para no bloquear compilación/ejecución de la UI.
        return []
    }

    /// Crea un catálogo (stub: devuelve objeto en memoria).
    public func createCatalog(
        name: String,
        description: String,
        userId: String,
        columns: [String]
    ) async throws -> Catalog {
        let now = Date()
        let cat = Catalog(
            _id: BSONObjectID(),
            name: name,
            description: description,
            userId: userId,
            columns: columns,
            rows: [],
            legacyRows: nil,
            createdAt: now,
            updatedAt: now
        )

        // TODO: Inserción real
        return cat
    }

    /// Actualiza un catálogo existente (stub: no-op)
    public func updateCatalog(_ catalog: Catalog) async throws {
        // TODO: updateOne real
        _ = catalog
    }

    /// Borra un catálogo por id (stub: no-op)
    public func deleteCatalog(id: BSONObjectID) async throws {
        // TODO: deleteOne real
        _ = id
    }

    // MARK: - Ejemplos de helpers BSON (cuando conectes de verdad)

    /// Ejemplo: transforma una fila en BSONDocument (por si lo necesitas)
    func makeBSON(from row: CatalogRow) -> BSONDocument {
        var dataDoc = BSONDocument()
        for (k, v) in row.data {
            dataDoc[k] = .string(v)
        }

        var filesDoc = BSONDocument()
        filesDoc["image"] = row.files.image.map { .string($0) } ?? .null
        filesDoc["images"] = .array(row.files.images.map { .string($0) })
        filesDoc["document"] = row.files.document.map { .string($0) } ?? .null
        filesDoc["documents"] = .array(row.files.documents.map { .string($0) })
        filesDoc["multimedia"] = row.files.multimedia.map { .string($0) } ?? .null
        filesDoc["multimediaFiles"] = .array(row.files.multimediaFiles.map { .string($0) })

        var doc = BSONDocument()
        doc["_id"] = .objectID(row._id)
        doc["data"] = .document(dataDoc)
        doc["files"] = .document(filesDoc)
        doc["createdAt"] = .datetime(row.createdAt)
        doc["updatedAt"] = .datetime(row.updatedAt)
        return doc
    }
}
