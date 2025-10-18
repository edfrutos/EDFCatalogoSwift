import Foundation
import MongoSwift
import NIO

public actor MongoService: Sendable {
    public static let shared = MongoService()

    private var client: MongoClient?
    private var db: MongoDatabase?
    private var group: EventLoopGroup?
    private var isConnecting: Bool = false

    private init() {}

    // Conectar si hace falta con timeout y mejor manejo de errores
    private func connectIfNeeded() async throws {
        // Si ya está conectado, retornar
        if client != nil { return }
        
        // Si ya está conectando, esperar
        if isConnecting {
            // Esperar un poco y reintentar
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            return try await connectIfNeeded()
        }
        
        isConnecting = true
        defer { isConnecting = false }

        // Intentar primero MONGO_URI, luego MONGODB_URI como fallback
        let uri = ProcessInfo.processInfo.environment["MONGO_URI"] 
            ?? ProcessInfo.processInfo.environment["MONGODB_URI"] 
            ?? "mongodb://localhost:27017"
        
        // Intentar primero MONGO_DB, luego MONGODB_DB como fallback
        let dbName = ProcessInfo.processInfo.environment["MONGO_DB"]
            ?? ProcessInfo.processInfo.environment["MONGODB_DB"] 
            ?? "edf_catalogotablas"

        print("🔌 Intentando conectar a MongoDB...")
        print("📍 URI: \(uri.replacingOccurrences(of: #"mongodb\+srv://[^:]+:[^@]+"#, with: "mongodb+srv://***:***", options: .regularExpression))")
        print("🗄️  Base de datos: \(dbName)")

        do {
            let g = MultiThreadedEventLoopGroup(numberOfThreads: 2)
            self.group = g
            
            // Crear cliente con timeout
            self.client = try MongoClient(uri, using: g)
            self.db = client!.db(dbName)
            
            print("✅ Conexión a MongoDB establecida correctamente")
        } catch {
            print("❌ Error al conectar a MongoDB: \(error.localizedDescription)")
            group = nil
            client = nil
            db = nil
            throw NSError(
                domain: "MongoService",
                code: 1002,
                userInfo: [
                    NSLocalizedDescriptionKey: "No se pudo conectar a MongoDB. Verifica tu conexión y las credenciales en el archivo .env",
                    NSLocalizedFailureReasonErrorKey: error.localizedDescription
                ]
            )
        }
    }

    // Cerrar conexión sin bloquear hilo en async
    public func disconnect() async {
        print("🔌 Cerrando conexión a MongoDB...")
        if let g = group {
            await withCheckedContinuation { cont in
                g.shutdownGracefully { _ in cont.resume() }
            }
        }
        group = nil
        client = nil
        db = nil
        isConnecting = false
        print("✅ Conexión a MongoDB cerrada")
    }

    // MARK: - Helpers visibles desde extensiones del mismo módulo

    func database() async throws -> MongoDatabase {
        try await connectIfNeeded()
        guard let db else {
            throw NSError(domain: "MongoService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "DB no inicializada"])
        }
        return db
    }

    public func catalogsCollection() async throws -> MongoCollection<BSONDocument> {
        let db = try await database()
        return db.collection("catalogs")
    }

    public func usersCollection() async throws -> MongoCollection<BSONDocument> {
        let db = try await database()
        return db.collection("users")
    }
}
