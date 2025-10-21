import SwiftUI

public struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var message: String?
    @State private var isError: Bool = false
    @State private var isSending: Bool = false
    @State private var showingResetPassword = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Recuperar contraseña")
                    .font(.title2).bold()
                
                Spacer()
                
                Button("Cerrar") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Ingresa tu email y te enviaremos un código para restablecer tu contraseña")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    .disabled(isSending)
                
                if let message = message {
                    Text(message)
                        .foregroundColor(isError ? .red : .green)
                        .font(.caption)
                }
                
                if isSending {
                    ProgressView("Enviando...")
                        .padding(.top, 8)
                } else {
                    Button("Enviar código") {
                        Task {
                            await sendResetEmail()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty)
                }
            }
            .padding()
            
            Spacer()
        }
        .frame(minWidth: 400, minHeight: 300)
        .sheet(isPresented: $showingResetPassword) {
            ResetPasswordView(email: email)
                .environmentObject(authViewModel)
        }
    }
    
    private func sendResetEmail() async {
        isSending = true
        message = nil
        
        let result = await authViewModel.requestPasswordReset(email: email)
        
        await MainActor.run {
            isSending = false
            
            if result {
                isError = false
                message = "✅ Código enviado. Revisa tu email."
                
                // Abrir modal de reseteo después de 1 segundo
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showingResetPassword = true
                }
            } else {
                isError = true
                message = "❌ Error al enviar el código. Verifica el email."
            }
        }
    }
}
