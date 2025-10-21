import SwiftUI

public struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var emailOrUsername: String = ""
    @State private var password: String = ""
    @State private var showingForgotPassword = false
    @State private var showingRegister = false
    @State private var showingContact = false
    
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Text("Iniciar sesión")
                .font(.title2).bold()

            TextField("Email o nombre de usuario", text: $emailOrUsername)
                .textFieldStyle(.roundedBorder)
                .textContentType(.username)
                .disableAutocorrection(true)

            SecureFieldWithToggle("Contraseña", text: $password)

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Button("Entrar") {
                    Task {
                        await authViewModel.signIn(emailOrUsername: emailOrUsername, password: password)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(emailOrUsername.isEmpty || password.isEmpty)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Links
                HStack(spacing: 16) {
                    Button("¿Olvidaste tu contraseña?") {
                        showingForgotPassword = true
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    
                    Text("|")
                        .foregroundColor(.gray)
                    
                    Button("Regístrate") {
                        showingRegister = true
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                
                Button {
                    showingContact = true
                } label: {
                    Label("Contacto", systemImage: "envelope")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: 400)
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingContact) {
            ContactView()
                .environmentObject(authViewModel)
        }
    }
}
