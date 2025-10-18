import SwiftUI

public struct AdminView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Panel de Administración")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            Text("Esta sección está disponible solo para administradores")
                .font(.headline)
            
            Text("Aquí podrá gestionar usuarios y configuraciones del sistema")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Funcionalidad en desarrollo")
                .font(.headline)
                .foregroundColor(.orange)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
            .environmentObject(AuthViewModel())
    }
}
