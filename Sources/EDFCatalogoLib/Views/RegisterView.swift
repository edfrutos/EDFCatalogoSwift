import SwiftUI

public struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var message: String?
    @State private var isError: Bool = false
    @State private var isRegistering: Bool = false
    
    public init() {}
    
    private var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    private var isFormValid: Bool {
        !username.isEmpty && !name.isEmpty && !email.isEmpty && password.count >= 6 && passwordsMatch
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Crear cuenta")
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
                    TextField("Nombre de usuario *", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .disabled(isRegistering)
                    
                    TextField("Nombre para mostrar *", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isRegistering)
                    
                    TextField("Email *", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .disabled(isRegistering)
                    
                    SecureFieldWithToggle("Contraseña (mínimo 6 caracteres)", text: $password, isDisabled: isRegistering)
                    
                    SecureFieldWithToggle("Confirmar contraseña", text: $confirmPassword, isDisabled: isRegistering)
                    
                    if !password.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                        Text("⚠️ Las contraseñas no coinciden")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    if let message = message {
                        Text(message)
                            .foregroundColor(isError ? .red : .green)
                            .font(.caption)
                    }
                    
                    if isRegistering {
                        ProgressView("Creando cuenta...")
                            .padding(.top, 8)
                    } else {
                        Button("Registrarse") {
                            Task {
                                await register()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isFormValid)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 450, minHeight: 450)
    }
    
    private func register() async {
        isRegistering = true
        message = nil
        
        let result = await authViewModel.register(username: username, name: name, email: email, password: password)
        
        isRegistering = false
        
        if result {
            isError = false
            message = "✅ Cuenta creada. Iniciando sesión..."
            
            // Cerrar modal después de 1 segundo
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            isError = true
            message = authViewModel.errorMessage ?? "❌ Error al crear la cuenta"
        }
    }
}
