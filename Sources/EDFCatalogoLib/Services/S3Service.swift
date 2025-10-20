import Foundation
import AWSS3
import ClientRuntime
import AWSClientRuntime

public actor S3Service: Sendable {
    public static let shared = S3Service()

    // Configuración de AWS
    private let accessKey: String
    private let secretKey: String
    private let region: String
    private let bucketName: String
    private let useS3: Bool
    
    // Cliente AWS S3
    private var s3Client: S3Client?
    
    // Límites de tamaño de archivo (en bytes)
    private let maxImageSize: Int = 20 * 1024 * 1024      // 20 MB
    private let maxDocumentSize: Int = 50 * 1024 * 1024   // 50 MB
    private let maxMultimediaSize: Int = 300 * 1024 * 1024 // 300 MB

    private init() {
        var env = ProcessInfo.processInfo.environment

        // Buscar .env en múltiples ubicaciones
        let possiblePaths = [
            "\(FileManager.default.currentDirectoryPath)/.env",
            "\(NSHomeDirectory())/edefrutos2025.xyz/httpdocs/.env",
            "/Users/edefrutos/__Proyectos/EDFCatalogoSwift/.env"
        ]
        
        for path in possiblePaths {
            if let text = try? String(contentsOfFile: path, encoding: .utf8) {
                print("📄 Cargando .env desde: \(path)")
                for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
                    let line = raw.trimmingCharacters(in: .whitespaces)
                    guard !line.isEmpty, !line.hasPrefix("#"), let eq = line.firstIndex(of: "=") else { continue }
                    let k = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
                    let v = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
                    if !k.isEmpty { env[k] = v }
                }
                break
            }
        }

        self.accessKey  = env["AWS_ACCESS_KEY_ID"] ?? ""
        self.secretKey  = env["AWS_SECRET_ACCESS_KEY"] ?? ""
        self.region     = env["AWS_REGION"] ?? "eu-central-1"
        self.bucketName = env["S3_BUCKET_NAME"] ?? "edf-catalogo-tablas"
        self.useS3      = (env["USE_S3"] ?? "false").lowercased() == "true"
        
        print("🔧 S3Service inicializado:")
        print("  - Bucket: \(bucketName)")
        print("  - Region: \(region)")
        print("  - USE_S3: \(useS3)")
        
        // Inicializar cliente S3 si tenemos credenciales
        if !accessKey.isEmpty && !secretKey.isEmpty {
            do {
                let config = try S3Client.S3ClientConfiguration(region: region)
                self.s3Client = S3Client(config: config)
                print("✅ Cliente S3 inicializado (usará credenciales de variables de entorno)")
            } catch {
                print("❌ Error inicializando cliente S3: \(error)")
            }
        } else {
            print("⚠️ No se encontraron credenciales AWS, funcionando en modo simulación")
        }
    }

    // MARK: - Subida de Archivos
    
    /// Sube un archivo local a S3
    /// - Parameters:
    ///   - fileUrl: URL local del archivo a subir
    ///   - userId: ID del usuario propietario
    ///   - catalogId: ID del catálogo
    ///   - fileType: Tipo de archivo (image, document, multimedia)
    /// - Returns: URL pública del archivo en S3
    public func uploadFile(
        fileUrl: URL,
        userId: String,
        catalogId: String,
        fileType: FileType
    ) async throws -> String {
        print("📤 Iniciando subida de archivo:")
        print("  - Archivo: \(fileUrl.lastPathComponent)")
        print("  - Tipo: \(fileType.rawValue)")
        print("  - Usuario: \(userId)")
        print("  - Catálogo: \(catalogId)")
        
        // Validar que el archivo existe
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            throw S3Error.fileNotFound(fileUrl.path)
        }
        
        // Obtener tamaño del archivo
        let fileSize = try getFileSize(url: fileUrl)
        print("  - Tamaño: \(formatBytes(fileSize))")
        
        // Validar tamaño según tipo
        try validateFileSize(size: fileSize, type: fileType)
        
        // Generar key único para S3
        let s3Key = generateS3Key(
            userId: userId,
            catalogId: catalogId,
            fileType: fileType,
            originalFileName: fileUrl.lastPathComponent
        )
        
        print("  - S3 Key: \(s3Key)")
        
        // Si USE_S3 está desactivado, simular subida
        if !useS3 {
            print("⚠️ USE_S3=false - Simulando subida")
            return simulateUpload(s3Key: s3Key, fileType: fileType)
        }
        
        // Subir archivo real a S3
        return try await uploadToS3(fileUrl: fileUrl, s3Key: s3Key)
    }
    
    /// Sube el archivo real a S3 usando AWS SDK
    private func uploadToS3(fileUrl: URL, s3Key: String) async throws -> String {
        guard let client = s3Client else {
            throw S3Error.uploadFailed("Cliente S3 no inicializado")
        }
        
        do {
            // Leer el archivo
            let fileData = try Data(contentsOf: fileUrl)
            
            // Detectar Content-Type
            let contentType = detectContentType(fileUrl: fileUrl)
            print("  - Content-Type: \(contentType)")
            
            // Crear el request de subida
            let putObjectRequest = PutObjectInput(
                body: .data(fileData),
                bucket: bucketName,
                contentType: contentType,
                key: s3Key
            )
            
            // Subir archivo
            print("📤 Subiendo a S3...")
            _ = try await client.putObject(input: putObjectRequest)
            
            // Generar URL pública
            let s3Url = "https://\(bucketName).s3.\(region).amazonaws.com/\(s3Key)"
            print("✅ Archivo subido exitosamente: \(s3Url)")
            return s3Url
            
        } catch {
            print("❌ Error al subir archivo: \(error)")
            throw S3Error.uploadFailed(error.localizedDescription)
        }
    }
    
    /// Detecta el Content-Type basado en la extensión del archivo
    private func detectContentType(fileUrl: URL) -> String {
        let ext = fileUrl.pathExtension.lowercased()
        
        switch ext {
        // Imágenes
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "svg": return "image/svg+xml"
        case "bmp": return "image/bmp"
        case "tiff", "tif": return "image/tiff"
            
        // Documentos
        case "pdf": return "application/pdf"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls": return "application/vnd.ms-excel"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt": return "application/vnd.ms-powerpoint"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "txt": return "text/plain"
        case "rtf": return "application/rtf"
        case "csv": return "text/csv"
        case "json": return "application/json"
        case "md": return "text/markdown"
            
        // Multimedia
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        case "wmv": return "video/x-ms-wmv"
        case "webm": return "video/webm"
        case "mkv": return "video/x-matroska"
        case "flv": return "video/x-flv"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "ogg": return "audio/ogg"
        case "flac": return "audio/flac"
        case "m4a": return "audio/mp4"
        case "aac": return "audio/aac"
            
        default: return "application/octet-stream"
        }
    }
    
    /// Simula la subida cuando USE_S3=false
    private func simulateUpload(s3Key: String, fileType: FileType) -> String {
        // Retornar URLs de ejemplo según el tipo
        switch fileType {
        case .image:
            return "https://via.placeholder.com/800x600.png?text=Imagen+Subida"
        case .pdf, .document:
            return "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
        case .multimedia:
            return "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4"
        }
    }

    // MARK: - Generación de URLs
    
    public func generatePresignedUrl(for key: String, expirationInSeconds: Int = 3600) async throws -> URL {
        let normalizedKey = normalizeKey(key)
        
        print("🔑 Generando URL pre-firmada:")
        print("  - Key: \(normalizedKey)")
        print("  - Expiración: \(expirationInSeconds)s")

        // Modo "simulación" cuando USE_S3=false o no hay cliente
        guard useS3, let client = s3Client else {
            print("⚠️ Modo simulación - devolviendo URL pública")
            if normalizedKey.lowercased().hasSuffix(".pdf") {
                return URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!
            }
            if ["jpg","jpeg","png","gif","webp"].contains((normalizedKey as NSString).pathExtension.lowercased()) {
                return URL(string: "https://via.placeholder.com/1200x800.png?text=Imagen+de+Prueba")!
            }
            // Devolver URL pública (que fallará si el bucket es privado)
            guard let url = URL(string: "https://\(bucketName).s3.\(region).amazonaws.com/\(normalizedKey)") else {
                throw S3Error.invalidKey(normalizedKey)
            }
            return url
        }
        
        // NOTA: La generación completa de URLs pre-firmadas con firma AWS v4
        // requiere implementación compleja de HMAC-SHA256.
        // Por ahora, devolvemos la URL directa.
        // SOLUCIÓN: Configurar el bucket S3 con política de acceso público de lectura
        // o implementar un backend que genere las URLs pre-firmadas.
        
        guard let url = URL(string: "https://\(bucketName).s3.\(region).amazonaws.com/\(normalizedKey)") else {
            throw S3Error.invalidKey(normalizedKey)
        }
        
        print("⚠️ Devolviendo URL directa (requiere bucket con acceso público)")
        print("  - URL: \(url.absoluteString.prefix(80))...")
        return url
    }


    // MARK: - Eliminación de Archivos
    
    public func deleteFile(key: String) async throws {
        let normalizedKey = normalizeKey(key)
        print("🗑️ Eliminando archivo: \(normalizedKey)")
        
        if !useS3 {
            print("⚠️ USE_S3=false - Simulando eliminación")
            return
        }
        
        // TODO: Implementar eliminación real con AWS SDK
        print("✅ Archivo eliminado (simulado)")
    }

    // MARK: - Utilidades
    
    /// Determina el tipo de archivo basándose en la extensión
    public nonisolated func getFileType(for url: String) -> FileType {
        if let u = URL(string: url) {
            let ext = u.pathExtension.lowercased()
            if ["jpg","jpeg","png","gif","bmp","webp","tiff","svg"].contains(ext) { return .image }
            if ["pdf"].contains(ext) { return .pdf }
            if ["doc","docx","xls","xlsx","ppt","pptx","txt","rtf","csv","json","md"].contains(ext) { return .document }
            if ["mp4","mov","avi","wmv","webm","mkv","flv","mp3","wav","ogg","flac","m4a","aac"].contains(ext) { return .multimedia }
        }
        let l = url.lowercased()
        if l.contains("image") || l.contains("foto") { return .image }
        if l.contains("video") || l.contains("audio") || l.contains("multimedia") { return .multimedia }
        if l.contains("pdf") { return .pdf }
        return .document
    }
    
    /// Genera una key única para S3
    private func generateS3Key(
        userId: String,
        catalogId: String,
        fileType: FileType,
        originalFileName: String
    ) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.lowercased().prefix(8)
        let sanitizedName = sanitizeFileName(originalFileName)
        
        let folder: String
        switch fileType {
        case .image:
            folder = "images"
        case .pdf, .document:
            folder = "documents"
        case .multimedia:
            folder = "multimedia"
        }
        
        return "uploads/\(userId)/\(catalogId)/\(folder)/\(timestamp)_\(uuid)_\(sanitizedName)"
    }
    
    /// Sanitiza el nombre del archivo
    private func sanitizeFileName(_ fileName: String) -> String {
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        
        // Remover caracteres especiales y espacios
        let sanitized = name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "", options: .regularExpression)
            .lowercased()
        
        return ext.isEmpty ? sanitized : "\(sanitized).\(ext)"
    }
    
    /// Obtiene el tamaño de un archivo
    private func getFileSize(url: URL) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? Int else {
            throw S3Error.cannotDetermineFileSize
        }
        return fileSize
    }
    
    /// Valida el tamaño del archivo según su tipo
    private func validateFileSize(size: Int, type: FileType) throws {
        let maxSize: Int
        let typeName: String
        
        switch type {
        case .image:
            maxSize = maxImageSize
            typeName = "imagen"
        case .pdf, .document:
            maxSize = maxDocumentSize
            typeName = "documento"
        case .multimedia:
            maxSize = maxMultimediaSize
            typeName = "multimedia"
        }
        
        if size > maxSize {
            throw S3Error.fileTooLarge(
                size: size,
                maxSize: maxSize,
                type: typeName
            )
        }
    }
    
    /// Formatea bytes a formato legible
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Normaliza una key de S3
    private func normalizeKey(_ key: String) -> String {
        var k = key
        if k.hasPrefix("http") {
            if let url = URL(string: k), let host = url.host, host.contains(bucketName) {
                k = String(url.path.dropFirst())
            } else {
                return k // URL externa
            }
        }
        if k.hasPrefix("/") { k.removeFirst() }
        if !k.hasPrefix("uploads/") && !k.hasPrefix("images/") && !k.hasPrefix("documents/") && !k.hasPrefix("public/") {
            k = "uploads/\(k)"
        }
        return k
    }
}

// MARK: - Errores

public enum S3Error: LocalizedError {
    case fileNotFound(String)
    case invalidKey(String)
    case cannotDetermineFileSize
    case fileTooLarge(size: Int, maxSize: Int, type: String)
    case uploadFailed(String)
    case deleteFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Archivo no encontrado: \(path)"
        case .invalidKey(let key):
            return "Clave S3 inválida: \(key)"
        case .cannotDetermineFileSize:
            return "No se pudo determinar el tamaño del archivo"
        case .fileTooLarge(let size, let maxSize, let type):
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useMB, .useGB]
            formatter.countStyle = .file
            let sizeStr = formatter.string(fromByteCount: Int64(size))
            let maxSizeStr = formatter.string(fromByteCount: Int64(maxSize))
            return "El archivo de \(type) es demasiado grande (\(sizeStr)). El tamaño máximo permitido es \(maxSizeStr)."
        case .uploadFailed(let reason):
            return "Error al subir archivo: \(reason)"
        case .deleteFailed(let reason):
            return "Error al eliminar archivo: \(reason)"
        }
    }
}
