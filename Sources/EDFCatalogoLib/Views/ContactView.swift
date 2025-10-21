import SwiftUI

public struct ContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var statusMessage: String?
    @State private var isError: Bool = false
    @State private var isSending: Bool = false
    
    private let emailService = EmailService.shared
    
    public init() {}
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !subject.isEmpty && !message.isEmpty && email.contains("@")
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Contacto")
                    .font(.title2).bold()
                
                Spacer()
                
                Button("Cerrar") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Nombre", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isSending)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .disabled(isSending)
                    
                    TextField("Asunto", text: $subject)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isSending)
                    
                    Text("Mensaje:")
                        .font(.headline)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                        .border(Color.gray.opacity(0.3), width: 1)
                        .disabled(isSending)
                    
                    if let statusMessage = statusMessage {
                        Text(statusMessage)
                            .foregroundColor(isError ? .red : .green)
                            .font(.caption)
                    }
                    
                    if isSending {
                        ProgressView("Enviando...")
                            .padding(.top, 8)
                    } else {
                        HStack {
                            Button("Enviar mensaje") {
                                Task {
                                    await sendContactEmail()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!isFormValid)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 500)
        .onAppear {
            // Pre-rellenar con datos del usuario autenticado si están disponibles
            if let user = authViewModel.currentUser {
                name = user.name
                email = user.email
            }
        }
    }
    
    private func sendContactEmail() async {
        isSending = true
        statusMessage = nil
        
        do {
            try await emailService.sendContactMessage(from: email, name: name, message: "\(subject)\n\n\(message)")
            
            isSending = false
            isError = false
            statusMessage = "✅ Mensaje enviado correctamente. ¡Gracias por contactarnos!"
            
            // Limpiar formulario después de 2 segundos y cerrar modal
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                clearForm()
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            isSending = false
            isError = true
            statusMessage = "❌ Error al enviar el mensaje. Por favor, inténtalo de nuevo."
        }
    }
    
    private func clearForm() {
        name = ""
        email = ""
        subject = ""
        message = ""
        statusMessage = nil
    }
}
