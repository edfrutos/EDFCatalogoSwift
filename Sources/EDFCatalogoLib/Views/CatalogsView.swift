import SwiftUI

@MainActor
public final class CatalogsViewModel: ObservableObject {
    @Published var catalogs: [Catalog] = []
    @Published var isLoading = false
    @Published var error: String?

    private let mongoService = MongoService.shared

    public init() {}
    
    public func loadCatalogs(userId: String, isAdmin: Bool) {
        isLoading = true
        error = nil
        Task {
            do {
                let loadedCatalogs = try await mongoService.getCatalogs(userId: userId, isAdmin: isAdmin)
                self.catalogs = loadedCatalogs
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.error = "No se pudieron cargar los catálogos."
            }
        }
    }

    public func createCatalog(name: String, description: String, userId: String, columns: [String]) {
        isLoading = true
        error = nil
        Task {
            do {
                let newCatalog = try await mongoService.createCatalog(
                    name: name,
                    description: description,
                    userId: userId,
                    columns: columns
                )
                self.catalogs.append(newCatalog)
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.error = "No se pudo crear el catálogo."
            }
        }
    }
    
    public func updateCatalog(at index: Int, name: String, description: String, columns: [String]) {
        guard index >= 0 && index < catalogs.count else { return }
        
        isLoading = true
        error = nil
        
        var updatedCatalog = catalogs[index]
        updatedCatalog.name = name
        updatedCatalog.description = description
        updatedCatalog.columns = columns
        updatedCatalog.updatedAt = Date()
        
        Task {
            do {
                try await mongoService.updateCatalog(updatedCatalog)
                self.catalogs[index] = updatedCatalog
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.error = "No se pudo actualizar el catálogo."
            }
        }
    }
    
    public func deleteCatalog(at index: Int) {
        guard index >= 0 && index < catalogs.count else { return }
        
        let catalogId = catalogs[index]._id
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await mongoService.deleteCatalog(id: catalogId)
                self.catalogs.remove(at: index)
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.error = "No se pudo eliminar el catálogo."
            }
        }
    }
}

public struct CatalogsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = CatalogsViewModel()

    @State private var showingCreateSheet = false
    @State private var catalogToEdit: CatalogEditData?
    @State private var catalogToDelete: Int?
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    @State private var showingUserProfile = false
    
    public init() {}
    
    // Catálogos filtrados por búsqueda
    private var filteredCatalogs: [Catalog] {
        if searchText.isEmpty {
            return viewModel.catalogs
        } else {
            return viewModel.catalogs.filter { catalog in
                catalog.name.localizedCaseInsensitiveContains(searchText) ||
                catalog.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    public var body: some View {
        NavigationStack {
            VStack {
            HStack {
                Text("Catálogos").font(.largeTitle).bold()
                Spacer()
                
                // Botón de perfil de usuario
                if let user = authViewModel.currentUser {
                    Button {
                        showingUserProfile = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle")
                            Text(user.name)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Button {
                    showingCreateSheet = true
                } label: {
                    Label("Nuevo", systemImage: "plus")
                }
                .disabled(authViewModel.currentUser == nil)
            }
            .padding(.horizontal)
            
            // Campo de búsqueda
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Buscar catálogos...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)

            if viewModel.isLoading {
                ProgressView("Cargando…").padding()
            } else if let error = viewModel.error {
                VStack(spacing: 8) {
                    Text(error).foregroundColor(.red)
                    Button("Reintentar") {
                        if let user = authViewModel.currentUser {
                            viewModel.loadCatalogs(userId: user.id, isAdmin: user.isAdmin)
                        }
                    }
                }.padding()
            } else if filteredCatalogs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: searchText.isEmpty ? "folder" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No hay catálogos" : "No se encontraron catálogos")
                        .font(.headline)
                    if !searchText.isEmpty {
                        Text("Intenta con otros términos de búsqueda")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredCatalogs.indices, id: \.self) { filteredIndex in
                        let catalog = filteredCatalogs[filteredIndex]
                        // Encontrar el índice real en el array original
                        if let originalIndex = viewModel.catalogs.firstIndex(where: { $0.id == catalog.id }) {
                            HStack {
                                NavigationLink(destination: CatalogDetailView(catalog: catalog)) {
                                    VStack(alignment: .leading) {
                                        Text(catalog.name).font(.headline)
                                        Text(catalog.description).font(.subheadline).foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Botones de acción
                                HStack(spacing: 8) {
                                    Button(action: {
                                        catalogToEdit = CatalogEditData(
                                            index: originalIndex,
                                            catalog: catalog
                                        )
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        catalogToDelete = originalIndex
                                        showingDeleteAlert = true
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            }
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                viewModel.loadCatalogs(userId: user.id, isAdmin: user.isAdmin)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateCatalogView { name, description, columns in
                if let user = authViewModel.currentUser {
                    viewModel.createCatalog(
                        name: name,
                        description: description,
                        userId: user.id,
                        columns: columns
                    )
                }
            }
        }
        .sheet(item: $catalogToEdit) { editData in
            EditCatalogView(
                catalog: editData.catalog
            ) { name, description, columns in
                viewModel.updateCatalog(
                    at: editData.index,
                    name: name,
                    description: description,
                    columns: columns
                )
            }
        }
        .alert("Eliminar Catálogo", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) {
                catalogToDelete = nil
            }
            Button("Eliminar", role: .destructive) {
                if let index = catalogToDelete {
                    viewModel.deleteCatalog(at: index)
                }
                catalogToDelete = nil
            }
        } message: {
            if let index = catalogToDelete {
                Text("¿Estás seguro de que quieres eliminar '\(viewModel.catalogs[index].name)'? Esta acción no se puede deshacer.")
            }
        }
        .sheet(isPresented: $showingUserProfile) {
            if let user = authViewModel.currentUser {
                UserProfileView(user: user) {
                    await authViewModel.reloadCurrentUser()
                }
            }
        }
    }
}

// Estructura auxiliar para el sheet de edición
struct CatalogEditData: Identifiable {
    let id = UUID()
    let index: Int
    let catalog: Catalog
}

/// Sencilla vista para crear
public struct CreateCatalogView: View {
    var onCreate: (_ name: String, _ description: String, _ columns: [String]) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @State private var name = ""
    @State private var description = ""
    @State private var columnsText = ""
    
    public init(onCreate: @escaping (_ name: String, _ description: String, _ columns: [String]) -> Void) {
        self.onCreate = onCreate
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nuevo catálogo").font(.title2).bold()

            TextField("Nombre", text: $name)
            TextField("Descripción", text: $description)
            TextField("Columnas separadas por comas", text: $columnsText)

            HStack {
                Spacer()
                Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                Button("Crear") {
                    let columns = columnsText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    onCreate(name, description, columns)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 420)
    }
}

/// Vista para editar catálogo
public struct EditCatalogView: View {
    var onSave: (_ name: String, _ description: String, _ columns: [String]) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @State private var name: String
    @State private var description: String
    @State private var columnsText: String
    
    public init(catalog: Catalog, onSave: @escaping (_ name: String, _ description: String, _ columns: [String]) -> Void) {
        self.onSave = onSave
        _name = State(initialValue: catalog.name)
        _description = State(initialValue: catalog.description)
        _columnsText = State(initialValue: catalog.columns.joined(separator: ", "))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Editar catálogo").font(.title2).bold()

            TextField("Nombre", text: $name)
            TextField("Descripción", text: $description)
            TextField("Columnas separadas por comas", text: $columnsText)

            HStack {
                Spacer()
                Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                Button("Guardar") {
                    let columns = columnsText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    onSave(name, description, columns)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 420)
    }
}
