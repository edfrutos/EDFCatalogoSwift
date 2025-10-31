import SwiftUI

public struct AdminCatalogsListView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
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
                        Task { await loadCatalogs() }
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
                                    NSLog("📚 DEBUG Catálogos: seleccionado -> %@", catalog.name)
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
        .sheet(item: $selectedCatalog) { catalog in
            AdminCatalogContentView(catalogId: catalog.id)
        }
        .onAppear { NSLog("🧭 DEBUG Vista cargada: AdminCatalogsListView") }
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
            await loadCatalogs()
        }
    }
    
    private func loadCatalogs() async {
        isLoading = true
        defer { isLoading = false }
        guard let user = authViewModel.currentUser else {
            NSLog("⚠️ AdminCatalogsListView: no hay usuario autenticado")
            catalogs = []
            return
        }
        do {
            let mongo = MongoService.shared
            let result = try await mongo.getCatalogs(userId: user.id, isAdmin: user.isAdmin)
            catalogs = result.map { cat in
                CatalogItem(
                    id: cat._id.hex,
                    name: cat.name,
                    description: cat.description,
                    itemCount: cat.rows.count
                )
            }
            NSLog("📊 AdminCatalogsListView: cargados %d catálogos", catalogs.count)
        } catch {
            NSLog("❌ Error cargando catálogos: %@", String(describing: error))
            catalogs = []
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

// MARK: - Admin Catalog Content View (carga completa + filas)

struct AdminCatalogContentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    let catalogId: String
    
    @State private var isLoading = true
    @State private var error: String?
    @State private var catalog: Catalog?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(catalog?.name ?? "Catálogo")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .border(Color.gray.opacity(0.3), width: 1)
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Cargando catálogo...").foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else if let error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text(error).foregroundColor(.red)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else if let catalog {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CatalogInfoRowView(label: "Descripción", value: catalog.description)
                        CatalogInfoRowView(label: "Columnas", value: catalog.columns.joined(separator: ", "))
                        CatalogInfoRowView(label: "Filas", value: String(catalog.rows.count))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Filas")
                                .font(.headline)
                            ForEach(Array(catalog.rows.enumerated()), id: \.offset) { idx, row in
                                RowSummaryView(index: idx + 1, row: row)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("Catálogo no encontrado").foregroundColor(.gray)
                    .frame(maxHeight: .infinity)
            }
        }
        .task { await load() }
    }
    
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let user = authViewModel.currentUser else {
            error = "No hay usuario autenticado"
            return
        }
        do {
            let mongo = MongoService.shared
            let list = try await mongo.getCatalogs(userId: user.id, isAdmin: user.isAdmin)
            if let found = list.first(where: { $0._id.hex == catalogId }) {
                catalog = found
            } else {
                error = "No se encontró el catálogo solicitado"
            }
        } catch {
            self.error = String(describing: error)
        }
    }
}

// Resumen simple de fila con enlaces a ficheros
private struct RowSummaryView: View {
    let index: Int
    let row: CatalogRow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fila #\(index)").font(.subheadline).fontWeight(.semibold)
            if !row.data.isEmpty {
                Text(row.data.map { "\($0.key): \($0.value)" }.joined(separator: "; "))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Archivos (mostrar urls si existen)
            VStack(alignment: .leading, spacing: 4) {
                if let img = row.files.image { FileLinkRow(label: "Imagen", url: img) }
                if !row.files.images.isEmpty { FileListRow(label: "Imágenes", urls: row.files.images) }
                if let doc = row.files.document { FileLinkRow(label: "Documento", url: doc) }
                if !row.files.documents.isEmpty { FileListRow(label: "Documentos", urls: row.files.documents) }
                if let mm = row.files.multimedia { FileLinkRow(label: "Multimedia", url: mm) }
                if !row.files.multimediaFiles.isEmpty { FileListRow(label: "Multimedia (varios)", urls: row.files.multimediaFiles) }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(8)
    }
}

private struct FileLinkRow: View {
    let label: String
    let url: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label).font(.caption).fontWeight(.semibold)
            Spacer()
            Button(url) {
                if let u = URL(string: url) { NSWorkspace.shared.open(u) }
            }
            .buttonStyle(.link)
        }
    }
}

private struct FileListRow: View {
    let label: String
    let urls: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).fontWeight(.semibold)
            ForEach(Array(urls.enumerated()), id: \.offset) { idx, u in
                Button("#\(idx + 1): \(u)") {
                    if let url = URL(string: u) { NSWorkspace.shared.open(url) }
                }
                .buttonStyle(.link)
            }
        }
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
