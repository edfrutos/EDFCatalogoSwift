import Foundation

public actor S3Service: Sendable {
    public static let shared = S3Service()

    // Cargamos primero de entorno; si no hay, miramos .env
    private let accessKey: String
    private let secretKey: String
    private let region: String
    private let bucketName: String
    private let useS3: Bool

    private init() {
        var env = ProcessInfo.processInfo.environment

        // Merge con .env si existe
        if let envURL = URL(string: "file://\(FileManager.default.currentDirectoryPath)/.env"),
           let text = try? String(contentsOf: envURL) {
            for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
                let line = raw.trimmingCharacters(in: .whitespaces)
                guard !line.isEmpty, !line.hasPrefix("#"), let eq = line.firstIndex(of: "=") else { continue }
                let k = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
                let v = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
                if !k.isEmpty { env[k] = v }
            }
        }

        self.accessKey  = env["AWS_ACCESS_KEY_ID"] ?? ""
        self.secretKey  = env["AWS_SECRET_ACCESS_KEY"] ?? ""
        self.region     = env["AWS_REGION"] ?? "eu-central-1"
        self.bucketName = env["S3_BUCKET_NAME"] ?? "edf-catalogo-tablas"
        self.useS3      = (env["USE_S3"] ?? "false").lowercased() == "true"
    }

    public func generatePresignedUrl(for key: String, expirationInSeconds: Int = 3600) async throws -> URL {
        let normalizedKey = normalizeKey(key)

        // Modo “simulación” cuando USE_S3=false
        if !useS3 {
            if normalizedKey.lowercased().hasSuffix(".pdf") {
                return URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!
            }
            if ["jpg","jpeg","png","gif","webp"].contains((normalizedKey as NSString).pathExtension.lowercased()) {
                return URL(string: "https://via.placeholder.com/1200x800.png?text=Imagen+de+Prueba")!
            }
            return URL(string: "https://example.com/\(normalizedKey)")!
        }

        guard let url = URL(string: "https://\(bucketName).s3.\(region).amazonaws.com/\(normalizedKey)") else {
            throw NSError(domain: "S3Service", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Clave S3 inválida: \(normalizedKey)"])
        }
        return url
    }

    public func uploadFile(fileUrl: URL, key: String) async throws -> String {
        let normalizedKey = normalizeKey(key)
        return "https://\(bucketName).s3.\(region).amazonaws.com/\(normalizedKey)"
    }

    public func deleteFile(key: String) async throws {
        _ = normalizeKey(key)
    }

    public nonisolated func getFileType(for url: String) -> FileType {
        if let u = URL(string: url) {
            let ext = u.pathExtension.lowercased()
            if ["jpg","jpeg","png","gif","bmp","webp"].contains(ext) { return .image }
            if ["pdf"].contains(ext) { return .pdf }
            if ["doc","docx","xls","xlsx","ppt","pptx","txt","rtf","csv","json"].contains(ext) { return .document }
            if ["mp4","mov","avi","wmv","webm","mp3","wav","ogg","flac","m4a"].contains(ext) { return .multimedia }
        }
        let l = url.lowercased()
        if l.contains("image") || l.contains("foto") { return .image }
        if l.contains("video") || l.contains("audio") || l.contains("multimedia") { return .multimedia }
        if l.contains("pdf") { return .pdf }
        return .document
    }

    // MARK: - Helpers

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
