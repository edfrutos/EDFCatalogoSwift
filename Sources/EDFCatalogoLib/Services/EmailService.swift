import Foundation

public actor EmailService {
    public static let shared = EmailService()
    
    private let apiKey: String
    private let apiURL = "https://api.brevo.com/v3/smtp/email"
    
    public init() {
        var env = ProcessInfo.processInfo.environment
        
        // Buscar .env
        let possiblePaths = [
            "\(FileManager.default.currentDirectoryPath)/.env",
            "\(Bundle.main.resourcePath ?? "")/.env",
            "\(NSHomeDirectory())/edefrutos2025.xyz/httpdocs/.env",
            "/Users/edefrutos/__Proyectos/EDFCatalogoSwift/.env"
        ]
        
        for path in possiblePaths {
            if let text = try? String(contentsOfFile: path, encoding: .utf8) {
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
        
        self.apiKey = env["BREVO_API_KEY"] ?? ""
        
        if apiKey.isEmpty {
            print("⚠️ EmailService: No se encontró BREVO_API_KEY")
        } else {
            print("✅ EmailService inicializado")
        }
    }
    
    public func sendPasswordResetEmail(to email: String, resetToken: String) async throws {
        let subject = "Recuperación de contraseña - EDF Catálogo"
        let htmlContent = """
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
            <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                <h2 style="color: #333;">Recuperación de contraseña</h2>
                <p>Has solicitado recuperar tu contraseña para EDF Catálogo.</p>
                <p>Tu token de recuperación es:</p>
                <div style="background-color: #f0f0f0; padding: 15px; border-radius: 5px; font-family: monospace; font-size: 18px; text-align: center; margin: 20px 0;">
                    <strong>\(resetToken)</strong>
                </div>
                <p>Copia este código e introdúcelo en la aplicación para restablecer tu contraseña.</p>
                <p style="color: #666; font-size: 14px; margin-top: 30px;">Este token es válido por 1 hora.</p>
                <p style="color: #999; font-size: 12px; margin-top: 20px;">Si no solicitaste este cambio, ignora este mensaje.</p>
            </div>
        </body>
        </html>
        """
        
        try await sendEmail(
            to: email,
            subject: subject,
            htmlContent: htmlContent
        )
    }
    
    public func sendWelcomeEmail(to email: String, name: String) async throws {
        let subject = "Bienvenido a EDF Catálogo"
        let htmlContent = """
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
            <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                <h2 style="color: #333;">¡Bienvenido, \(name)!</h2>
                <p>Tu cuenta en EDF Catálogo ha sido creada exitosamente.</p>
                <p>Ya puedes comenzar a crear y gestionar tus catálogos.</p>
                <p style="color: #666; font-size: 14px; margin-top: 30px;">Gracias por confiar en nosotros.</p>
            </div>
        </body>
        </html>
        """
        
        try await sendEmail(
            to: email,
            subject: subject,
            htmlContent: htmlContent
        )
    }
    
    public func sendContactMessage(from: String, name: String, message: String) async throws {
        let adminEmail = "edfrutos@gmail.com"
        
        let subject = "Nuevo mensaje de contacto - \(name)"
        let htmlContent = """
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Nuevo mensaje de contacto</h2>
            <p><strong>De:</strong> \(name) (\(from))</p>
            <p><strong>Mensaje:</strong></p>
            <div style="background-color: #f5f5f5; padding: 15px; border-left: 4px solid #007bff; margin: 10px 0;">
                \(message.replacingOccurrences(of: "\n", with: "<br>"))
            </div>
        </body>
        </html>
        """
        
        try await sendEmail(
            to: adminEmail,
            subject: subject,
            htmlContent: htmlContent,
            replyTo: from
        )
    }
    
    private func sendEmail(
        to: String,
        subject: String,
        htmlContent: String,
        replyTo: String? = nil
    ) async throws {
        guard !apiKey.isEmpty else {
            throw EmailError.missingAPIKey
        }
        
        guard let url = URL(string: apiURL) else {
            throw EmailError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        var emailData: [String: Any] = [
            "sender": ["name": "EDF Catálogo", "email": "noreply@edefrutos2025.xyz"],
            "to": [["email": to]],
            "subject": subject,
            "htmlContent": htmlContent
        ]
        
        if let replyTo = replyTo {
            emailData["replyTo"] = ["email": replyTo]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmailError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Error al enviar email: \(errorMessage)")
            throw EmailError.sendFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        print("✅ Email enviado exitosamente a \(to)")
    }
}

public enum EmailError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case sendFailed(statusCode: Int, message: String)
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No se encontró la clave API de Brevo"
        case .invalidURL:
            return "URL de API inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .sendFailed(let statusCode, let message):
            return "Error al enviar email (código \(statusCode)): \(message)"
        }
    }
}
