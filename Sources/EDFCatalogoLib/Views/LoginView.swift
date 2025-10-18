import SwiftUI

public struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Text("Iniciar sesión")
                .font(.title2).bold()

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.username)
                .disableAutocorrection(true)

            SecureField("Contraseña", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)

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
                        await authViewModel.signIn(email: email, password: password)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty)
            }
        }
        .padding()
        .frame(maxWidth: 400)
    }
}
