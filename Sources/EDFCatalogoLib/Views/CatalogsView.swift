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
}

public struct CatalogsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = CatalogsViewModel()

    @State private var showingCreateSheet = false
    
    public init() {}

    public var body: some View {
        VStack {
            HStack {
                Text("Catálogos").font(.largeTitle).bold()
                Spacer()
                Button {
                    showingCreateSheet = true
                } label: {
                    Label("Nuevo", systemImage: "plus")
                }
                .disabled(authViewModel.currentUser == nil)
            }
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
            } else {
                List(viewModel.catalogs, id: \.id) { catalog in
                    NavigationLink(destination: CatalogDetailView(catalog: catalog)) {
                        VStack(alignment: .leading) {
                            Text(catalog.name).font(.headline)
                            Text(catalog.description).font(.subheadline).foregroundColor(.secondary)
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
    }
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
