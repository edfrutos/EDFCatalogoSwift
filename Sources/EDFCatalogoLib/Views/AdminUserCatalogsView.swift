import SwiftUI

public struct AdminUserCatalogsView: View {
    @Environment(\\.dismiss) var dismiss
    
    let userId: String
    @State private var catalogs: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(\"Catálogos del Usuario\")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(\"ID: \\(userId)\")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: \"xmark.circle.fill\")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .border(Color(.systemGray4), width: 1)
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                    Text(\"Cargando catálogos...\")
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: \"exclamationmark.circle.fill\")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(\"Error\")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
                .padding()
            } else if catalogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: \"books.vertical.slash\")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text(\"Sin catálogos\")
                        .foregroundColor(.gray)
                    Text(\"Este usuario no tiene catálogos asignados\")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(catalogs, id: \\.self) { catalog in
                            CatalogItemView(catalogName: catalog)
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await loadCatalogs()
        }
    }
    
    private func loadCatalogs() async {
        isLoading = true
        errorMessage = nil
        
        // Simulación: En una implementación real, esto consultaría a MongoService
        // para obtener los catálogos del usuario especificado
        
        // Por ahora, mostramos un mensaje de que esta funcionalidad está disponible
        await Task.sleep(1_000_000_000) // Simular carga
        
        catalogs = [
            \"Joyería Moderna\",
            \"Anillos de Diamante\",
            \"Colecciones Clásicas\"
        ]
        
        isLoading = false
    }
}

// MARK: - Catalog Item View

struct CatalogItemView: View {
    let catalogName: String
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(catalogName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(\"Catálogo personalizado\")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Menu {
                    Button(action: { showDetails = true }) {
                        Label(\"Ver Detalles\", systemImage: \"eye\")
                    }
                    
                    Button(action: {}) {
                        Label(\"Editar\", systemImage: \"pencil\")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {}) {
                        Label(\"Eliminar\", systemImage: \"trash\")
                    }
                } label: {
                    Image(systemName: \"ellipsis.circle\")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .sheet(isPresented: \$showDetails) {
            CatalogDetailsView(catalogName: catalogName)
        }
    }
}

// MARK: - Catalog Details View

struct CatalogDetailsView: View {
    @Environment(\\.dismiss) var dismiss
    let catalogName: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Text(catalogName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: \"xmark.circle.fill\")
                            .foregroundColor(.gray)
                    }
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(\"Nombre del Catálogo\")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .fontWeight(.semibold)
                            Text(catalogName)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(\"Descripción\")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .fontWeight(.semibold)
                            Text(\"Catálogo de \\(catalogName.lowercased())\")
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(\"Elementos\")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .fontWeight(.semibold)
                            Text(\"0 elementos\")
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text(\"Cerrar\")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {}) {
                        Text(\"Editar\")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

#Preview {
    AdminUserCatalogsView(userId: \"507f1f77bcf86cd799439011\")
}
