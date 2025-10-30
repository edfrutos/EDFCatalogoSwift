import SwiftUI

public struct AdminCatalogsListView: View {
    @State private var catalogs: [CatalogItem] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedCatalog: CatalogItem?
    @State private var showDetails = false
    @State private var showDeleteAlert = false
    @State private var catalogToDelete: CatalogItem?
    
    var filteredCatalogs: [CatalogItem] {
        if searchText.isEmpty {
            return catalogs
        }
        return catalogs.filter { catalog in
            catalog.name.localizedCaseInsensitiveContains(searchText) ||
            catalog.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gestión de Catálogos")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Total: \(catalogs.count) catálogos")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        loadCatalogs()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar por nombre o descripción", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            
            // Content
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Cargando catálogos...")
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else if filteredCatalogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text(searchText.isEmpty ? "Sin catálogos" : "No se encontraron resultados")
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredCatalogs) { catalog in
                            CatalogAdminItemView(
                                catalog: catalog,
                                onSelect: {
                                    selectedCatalog = catalog
                                    showDetails = true
                                },
                                onEdit: {
                                    selectedCatalog = catalog
                                    showDetails = true
                                },
                                onDelete: {
                                    catalogToDelete = catalog
                                    showDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showDetails) {
            if let catalog = selectedCatalog {
                AdminCatalogDetailView(catalog: catalog)
            }
        }
        .alert("Eliminar Catálogo", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                if let catalog = catalogToDelete {
                    deleteCatalog(catalog)
                }
            }
        } message: {
            if let catalog = catalogToDelete {
                Text("¿Deseas eliminar el catálogo '\(catalog.name)'? Esta acción no se puede deshacer.")
            }
        }
        .task {
            do {
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch { }
            loadCatalogs()
        }
    }
    
    private func loadCatalogs() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            catalogs = [
                CatalogItem(id: "1", name: "Joyería Moderna", description: "Colección de joyería contemporánea", itemCount: 45),
                CatalogItem(id: "2", name: "Anillos de Diamante", description: "Anillos con diamantes certificados", itemCount: 23),
                CatalogItem(id: "3", name: "Colecciones Clásicas", description: "Diseños clásicos y atemporales", itemCount: 67),
                CatalogItem(id: "4", name: "Pulseras y Brazaletes", description: "Variedad de pulseras y brazaletes", itemCount: 34),
                CatalogItem(id: "5", name: "Collares y Colgantes", description: "Collares y colgantes personalizados", itemCount: 56)
            ]
            isLoading = false
        }
    }
    
    private func deleteCatalog(_ catalog: CatalogItem) {
        catalogs.removeAll { $0.id == catalog.id }
        catalogToDelete = nil
    }
}

// MARK: - Catalog Item Model

struct CatalogItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let itemCount: Int
}

// MARK: - Catalog Admin Item View

struct CatalogAdminItemView: View {
    let catalog: CatalogItem
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(catalog.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(catalog.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(catalog.itemCount) elementos")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Actions Menu
                Menu {
                    Button(action: onSelect) {
                        Label("Ver", systemImage: "eye")
                    }
                    
                    Button(action: onEdit) {
                        Label("Editar", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
        }
        .background(Color.white)
        .border(Color.gray.opacity(0.3), width: 1)
        .cornerRadius(8)
    }
}

// MARK: - Catalog Detail View

struct AdminCatalogDetailView: View {
    @Environment(\.dismiss) var dismiss
    let catalog: CatalogItem
    
    @State private var isEditing = false
    @State private var editingName = ""
    @State private var editingDescription = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detalles del Catálogo")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(catalog.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .border(Color.gray.opacity(0.3), width: 1)
                
            ScrollView {
                VStack(spacing: 16) {
                    // Icon
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    // Tabs
                    Picker("Tab", selection: $isEditing) {
                        Text("Ver").tag(false)
                        Text("Editar").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if isEditing {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Nombre", systemImage: "textformat")
                                    .fontWeight(.semibold)
                                TextField("Nombre del catálogo", text: $editingName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Descripción", systemImage: "text.justify")
                                    .fontWeight(.semibold)
                                TextField("Descripción", text: $editingDescription)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            HStack(spacing: 12) {
                                Button(action: { isEditing = false }) {
                                    Text("Cancelar")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: { isEditing = false }) {
                                    Text("Guardar")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                    } else {
                        VStack(spacing: 16) {
                            CatalogInfoRowView(label: "Nombre", value: catalog.name)
                            CatalogInfoRowView(label: "Descripción", value: catalog.description)
                            CatalogInfoRowView(label: "Elementos", value: "\(catalog.itemCount)")
                            CatalogInfoRowView(label: "ID", value: catalog.id)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            editingName = catalog.name
            editingDescription = catalog.description
        }
    }
}

// MARK: - Catalog Info Row

struct CatalogInfoRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .fontWeight(.semibold)
            Text(value)
                .font(.body)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
