import Foundation
import MongoSwift
@preconcurrency import SwiftBSON
// Usa los modelos de Sources/Models/Catalog.swift (NO redefinirlos aquí)

extension MongoService {

    /// Obtiene catálogos desde MongoDB
    public func getCatalogs(userId: String, isAdmin: Bool) async throws -> [Catalog] {
        print("🔍 Obteniendo catálogos para usuario: \(userId), isAdmin: \(isAdmin)")
        
        let catalogs = try await catalogsCollection()
        
        // Si es admin, obtener todos los catálogos
        // Si no, solo los del usuario
        let query: BSONDocument = isAdmin ? [:] : ["Owner": .string(userId)]
        
        print("📝 Query: \(query)")
        
        let cursor = try await catalogs.find(query)
        let results = try await cursor.toArray()
        
        print("📊 Catálogos encontrados: \(results.count)")
        
        var catalogList: [Catalog] = []
        
        for doc in results {
            if let catalog = try? parseCatalogFromDocument(doc) {
                catalogList.append(catalog)
                print("✅ Catálogo parseado: \(catalog.name)")
            } else {
                print("⚠️ No se pudo parsear catálogo: \(doc["_id"] ?? .null)")
            }
        }
        
        return catalogList
    }

    /// Crea un catálogo en MongoDB
    public func createCatalog(
        name: String,
        description: String,
        userId: String,
        columns: [String]
    ) async throws -> Catalog {
        print("📝 Creando catálogo: \(name)")
        
        let catalogs = try await catalogsCollection()
        let now = Date()
        let catalogId = BSONObjectID()
        
        // Crear documento según estructura de MongoDB
        let doc: BSONDocument = [
            "_id": .objectID(catalogId),
            "Name": .string(name),
            "Description": .string(description),
            "Category": .string(""),
            "Fecha": .datetime(now),
            "DocumentoUrl": .string(""),
            "MultimediaUrl": .string(""),
            "ImagenUrl": .string(""),
            "Headers": .array(columns.map { .string($0) }),
            "Rows": .array([]),
            "LegacyRows": .array([]),
            "CreatedBy": .string(userId),
            "Owner": .string(userId),
            "CreatedAt": .datetime(now),
            "UpdatedAt": .datetime(now),
            "Miniatura": .null
        ]
        
        print("📄 Documento a insertar: \(doc)")
        
        let result = try await catalogs.insertOne(doc)
        
        print("✅ Catálogo creado con ID: \(result?.insertedID ?? .null)")
        
        return Catalog(
            _id: catalogId,
            name: name,
            description: description,
            userId: userId,
            columns: columns,
            rows: [],
            legacyRows: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    /// Actualiza un catálogo existente en MongoDB
    public func updateCatalog(_ catalog: Catalog) async throws {
        print("📝 Actualizando catálogo: \(catalog.name)")
        print("📊 Número de filas a guardar: \(catalog.rows.count)")
        
        let catalogs = try await catalogsCollection()
        
        // Convertir filas a BSON
        let rowsBSON: [BSON] = catalog.rows.map { row in
            .document(makeBSONForRow(from: row))
        }
        
        // Crear documento actualizado con TODAS las filas
        let doc: BSONDocument = [
            "Name": .string(catalog.name),
            "Description": .string(catalog.description),
            "Headers": .array(catalog.columns.map { .string($0) }),
            "Rows": .array(rowsBSON),
            "UpdatedAt": .datetime(Date())
        ]
        
        print("📄 Documento a actualizar con \(rowsBSON.count) filas")
        
        let filter: BSONDocument = ["_id": .objectID(catalog._id)]
        let update: BSONDocument = ["$set": .document(doc)]
        
        let result = try await catalogs.updateOne(filter: filter, update: update)
        
        print("✅ Catálogo actualizado. Modificados: \(result?.modifiedCount ?? 0)")
    }

    /// Borra un catálogo por id de MongoDB
    public func deleteCatalog(id: BSONObjectID) async throws {
        print("🗑️ Eliminando catálogo con ID: \(id.hex)")
        
        let catalogs = try await catalogsCollection()
        
        let filter: BSONDocument = ["_id": .objectID(id)]
        
        let result = try await catalogs.deleteOne(filter)
        
        print("✅ Catálogo eliminado. Documentos eliminados: \(result?.deletedCount ?? 0)")
    }

    // MARK: - Helper para parsear catálogos desde MongoDB
    
    /// Parsea un documento de MongoDB a un objeto Catalog
    private func parseCatalogFromDocument(_ doc: BSONDocument) throws -> Catalog {
        guard let catalogId = doc["_id"]?.objectIDValue else {
            throw NSError(domain: "MongoService", code: 1, userInfo: [NSLocalizedDescriptionKey: "ID de catálogo inválido"])
        }
        
        let name = doc["Name"]?.stringValue ?? "Sin nombre"
        let description = doc["Description"]?.stringValue ?? ""
        let owner = doc["Owner"]?.stringValue ?? doc["CreatedBy"]?.stringValue ?? ""
        
        // Parsear Headers (columnas)
        var columns: [String] = []
        if let headersArray = doc["Headers"]?.arrayValue {
            columns = headersArray.compactMap { $0.stringValue }
        }
        
        // Parsear Rows - pasar las columnas para inicializar todos los campos
        var rows: [CatalogRow] = []
        if let rowsArray = doc["Rows"]?.arrayValue {
            for rowBSON in rowsArray {
                if let rowDoc = rowBSON.documentValue,
                   let row = try? parseRowFromDocument(rowDoc, columns: columns) {
                    rows.append(row)
                }
            }
        }
        
        let createdAt = doc["CreatedAt"]?.dateValue ?? Date()
        let updatedAt = doc["UpdatedAt"]?.dateValue ?? Date()
        
        return Catalog(
            _id: catalogId,
            name: name,
            description: description,
            userId: owner,
            columns: columns,
            rows: rows,
            legacyRows: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Parsea una fila desde un documento de MongoDB
    private func parseRowFromDocument(_ doc: BSONDocument, columns: [String]) throws -> CatalogRow {
        // MongoDB usa UUIDs como strings para los _id de las filas
        let originalIdString: String?
        if let idStr = doc["_id"]?.stringValue {
            originalIdString = idStr
        } else if let objId = doc["_id"]?.objectIDValue {
            originalIdString = objId.hex
        } else {
            originalIdString = nil
        }
        
        // Crear un BSONObjectID temporal para uso interno
        let rowId = BSONObjectID()
        
        // Inicializar data con TODAS las columnas (vacías por defecto)
        var data: [String: String] = [:]
        for column in columns {
            data[column] = ""
        }
        
        // Sobrescribir con los valores que existen en MongoDB
        if let dataDoc = doc["Data"]?.documentValue {
            for (key, value) in dataDoc {
                if let stringValue = value.stringValue {
                    data[key] = stringValue
                }
            }
        }
        
        // Parsear Files
        var files = RowFiles()
        if let filesDoc = doc["Files"]?.documentValue {
            files.image = filesDoc["Image"]?.stringValue
            files.document = filesDoc["Document"]?.stringValue
            files.multimedia = filesDoc["Multimedia"]?.stringValue
            
            if let imagesArray = filesDoc["Images"]?.arrayValue {
                files.images = imagesArray.compactMap { $0.stringValue }
            }
            if let docsArray = filesDoc["Documents"]?.arrayValue {
                files.documents = docsArray.compactMap { $0.stringValue }
            }
            if let multimediaArray = filesDoc["MultimediaFiles"]?.arrayValue {
                files.multimediaFiles = multimediaArray.compactMap { $0.stringValue }
            }
        }
        
        let createdAt = doc["CreatedAt"]?.dateValue ?? Date()
        let updatedAt = doc["UpdatedAt"]?.dateValue ?? Date()
        
        return CatalogRow(
            _id: rowId,
            originalId: originalIdString,
            data: data,
            files: files,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // MARK: - Helper para convertir filas a BSON
    
    /// Transforma una fila en BSONDocument para MongoDB (con mayúsculas según estructura de MongoDB)
    private func makeBSONForRow(from row: CatalogRow) -> BSONDocument {
        var dataDoc = BSONDocument()
        for (k, v) in row.data {
            dataDoc[k] = .string(v)
        }

        var filesDoc = BSONDocument()
        filesDoc["Image"] = row.files.image.map { .string($0) } ?? .null
        filesDoc["Images"] = .array(row.files.images.map { .string($0) })
        filesDoc["Document"] = row.files.document.map { .string($0) } ?? .null
        filesDoc["Documents"] = .array(row.files.documents.map { .string($0) })
        filesDoc["Multimedia"] = row.files.multimedia.map { .string($0) } ?? .null
        filesDoc["MultimediaFiles"] = .array(row.files.multimediaFiles.map { .string($0) })
        filesDoc["AdditionalFiles"] = .array([])

        var doc = BSONDocument()
        // Usar el originalId si existe (UUID de MongoDB), si no, generar uno nuevo
        if let originalId = row.originalId {
            doc["_id"] = .string(originalId)
        } else {
            doc["_id"] = .string(UUID().uuidString.lowercased())
        }
        doc["Data"] = .document(dataDoc)
        doc["Files"] = .document(filesDoc)
        doc["CreatedAt"] = .datetime(row.createdAt)
        doc["UpdatedAt"] = .datetime(row.updatedAt)
        return doc
    }
}
