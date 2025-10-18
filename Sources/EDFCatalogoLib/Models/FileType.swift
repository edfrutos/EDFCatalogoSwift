import Foundation

/// Tipo de archivo manejado por la app.
/// ¡Defínelo una sola vez en todo el proyecto!
public enum FileType: String, Codable, Sendable {
    case image
    case document
    case multimedia
    case pdf
}
