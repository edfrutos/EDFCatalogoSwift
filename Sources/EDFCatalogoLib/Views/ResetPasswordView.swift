import SwiftUI

public struct ResetPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let email: String
    
    @State private var resetCode: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var message: String?
    @State private var isError: Bool = false
    @State private var isResetting: Bool = false
    
    public init(email: String) {
        self.email = email
    }
    
    private var passwordsMatch: Bool {
        newPassword == confirmPassword
    }
    
    private var isFormValid: Bool {
        !resetCode.isEmpty && newPassword.count >= 6 && passwordsMatch
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Restablecer contraseña")
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
                    Text("Se ha enviado un código de 6 dígitos a:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(email)
                        .font(.body)
                        .bold()
                        .padding(.bottom, 8)
                    
                    Text("Código de verificación")
                        .font(.headline)
                    
                    TextField("Ingresa el código de 6 dígitos", text: $resetCode)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isResetting)
                        .onChange(of: resetCode) { newValue in
                            // Limitar a 6 caracteres numéricos
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered.count > 6 {
                                resetCode = String(filtered.prefix(6))
                            } else {
                                resetCode = filtered
                            }
                        }
                    
                    Text("Nueva contraseña")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    SecureFieldWithToggle("Mínimo 6 caracteres", text: $newPassword, isDisabled: isResetting)
                    
                    SecureFieldWithToggle("Confirmar contraseña", text: $confirmPassword, isDisabled: isResetting)
                    
                    if !newPassword.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                        Text("⚠️ Las contraseñas no coinciden")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    if let message = message {
                        Text(message)
                            .foregroundColor(isError ? .red : .green)
                            .font(.caption)
                            .padding(.top, 4)
                    }
                    
                    if isResetting {
                        ProgressView("Restableciendo contraseña...")
                            .padding(.top, 8)
                    } else {
                        Button("Restablecer contraseña") {
                            Task {
                                await resetPassword()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isFormValid)
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 450, minHeight: 450)
    }
    
    private func resetPassword() async {
        isResetting = true
        message = nil
        
        let result = await authViewModel.resetPassword(
            email: email,
            token: resetCode,
            newPassword: newPassword
        )
        
        await MainActor.run {
            isResetting = false
            
            if result {
                isError = false
                message = "✅ Contraseña restablecida correctamente"
                
                // Cerrar modal después de 2 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                isError = true
                message = authViewModel.errorMessage ?? "❌ Error al restablecer la contraseña"
            }
        }
    }
}
