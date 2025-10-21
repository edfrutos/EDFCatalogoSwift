import SwiftUI
import Foundation
import PDFKit
import AVKit
import AVFoundation
import UniformTypeIdentifiers
@preconcurrency import SwiftBSON

// MARK: - ViewModel

@MainActor
public class CatalogDetailViewModel: ObservableObject {
    @Published var catalog: Catalog
    @Published var rows: [CatalogRow] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isEditing: Bool = false
    @Published var showingAddRowSheet: Bool = false

    private let mongoService = MongoService.shared
    private let catalogId: BSONObjectID

    public init(catalog: Catalog) {
        self.catalog = catalog
        self.catalogId = catalog._id
        loadRows()
    }
    
    /// Recarga el catálogo completo desde MongoDB
    public func reloadCatalog() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Obtener el catálogo actualizado desde MongoDB
                let catalogs = try await mongoService.catalogsCollection()
                let filter: BSONDocument = ["_id": .objectID(catalogId)]
                
                if let doc = try await catalogs.findOne(filter),
                   let updatedCatalog = try? parseCatalogFromDocument(doc) {
                    await MainActor.run {
                        self.catalog = updatedCatalog
                        self.rows = updatedCatalog.rows
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "No se pudo recargar el catálogo"
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Parsea un documento de MongoDB a un objeto Catalog
    private func parseCatalogFromDocument(_ doc: BSONDocument) throws -> Catalog {
        guard let catalogId = doc["_id"]?.objectIDValue else {
            throw NSError(domain: "CatalogDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ID de catálogo inválido"])
        }
        
        let name = doc["Name"]?.stringValue ?? "Sin nombre"
        let description = doc["Description"]?.stringValue ?? ""
        let owner = doc["Owner"]?.stringValue ?? doc["CreatedBy"]?.stringValue ?? ""
        
        var columns: [String] = []
        if let headersArray = doc["Headers"]?.arrayValue {
            columns = headersArray.compactMap { $0.stringValue }
        }
        
        var rows: [CatalogRow] = []
        if let rowsArray = doc["Rows"]?.arrayValue {
            for rowBSON in rowsArray {
                if let rowDoc = rowBSON.documentValue,
                   let row = try? parseRowFromDocument(rowDoc) {
                    rows.append(row)
                }
            }
        }
        
        let createdAt = doc["CreatedAt"]?.dateValue ?? Date()
        let updatedAt = doc["UpdatedAt"]?.dateValue ?? Date()
        
        return Catalog(
            _id: catalogId,
            name: name,
            description: description,
            userId: owner,
            columns: columns,
            rows: rows,
            legacyRows: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Parsea una fila desde un documento de MongoDB
    private func parseRowFromDocument(_ doc: BSONDocument) throws -> CatalogRow {
        let originalIdString: String?
        if let idStr = doc["_id"]?.stringValue {
            originalIdString = idStr
        } else if let objId = doc["_id"]?.objectIDValue {
            originalIdString = objId.hex
        } else {
            originalIdString = nil
        }
        
        let rowId = BSONObjectID()
        
        var data: [String: String] = [:]
        if let dataDoc = doc["Data"]?.documentValue {
            for (key, value) in dataDoc {
                if let stringValue = value.stringValue {
                    data[key] = stringValue
                }
            }
        }
        
        var files = RowFiles()
        if let filesDoc = doc["Files"]?.documentValue {
            files.image = filesDoc["Image"]?.stringValue
            files.document = filesDoc["Document"]?.stringValue
            files.multimedia = filesDoc["Multimedia"]?.stringValue
            
            if let imagesArray = filesDoc["Images"]?.arrayValue {
                files.images = imagesArray.compactMap { $0.stringValue }
            }
            if let docsArray = filesDoc["Documents"]?.arrayValue {
                files.documents = docsArray.compactMap { $0.stringValue }
            }
            if let multimediaArray = filesDoc["MultimediaFiles"]?.arrayValue {
                files.multimediaFiles = multimediaArray.compactMap { $0.stringValue }
            }
        }
        
        let createdAt = doc["CreatedAt"]?.dateValue ?? Date()
        let updatedAt = doc["UpdatedAt"]?.dateValue ?? Date()
        
        return CatalogRow(
            _id: rowId,
            originalId: originalIdString,
            data: data,
            files: files,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func loadRows() {
        isLoading = true
        errorMessage = nil

        // 1) Cargamos lo que venga en el catálogo
        rows = catalog.rows

        // 2) Si no hay filas pero sí legacyRows, las convertimos
        if rows.isEmpty, let legacyRows = catalog.legacyRows {
            rows = legacyRows.map { legacyRow in
                CatalogRow(
                    _id: BSONObjectID(),
                    data: legacyRow,
                    files: RowFiles(),
                    createdAt: Date(),
                    updatedAt: Date()
                )
            }
        }

        // 3) Fallback: datos de ejemplo si sigue vacío
        if rows.isEmpty {
            loadSampleRows()
        }

        isLoading = false
    }

    private func loadSampleRows() {
        let now = Date()

        guard !catalog.columns.isEmpty else { return }

        rows = [
            createSampleRow(index: 1, now: now),
            createSampleRow(index: 2, now: now),
            createSampleRow(index: 3, now: now)
        ]
    }

    private func createSampleRow(index: Int, now: Date) -> CatalogRow {
        var data: [String: String] = [:]
        for column in catalog.columns {
            data[column] = "Ejemplo \(index) - \(column)"
        }

        let files = RowFiles(
            image: index % 2 == 0 ? "https://edf-catalogo-tablas.s3.eu-central-1.amazonaws.com/uploads/images/test-image.jpg" : nil,
            images: [],
            document: index % 3 == 0 ? "https://edf-catalogo-tablas.s3.eu-central-1.amazonaws.com/uploads/documents/sample.pdf" : nil,
            documents: [],
            multimedia: index % 4 == 0 ? "https://edf-catalogo-tablas.s3.eu-central-1.amazonaws.com/uploads/multimedia/sample.mp4" : nil,
            multimediaFiles: []
        )

        return CatalogRow(
            _id: BSONObjectID(),
            data: data,
            files: files,
            createdAt: now,
            updatedAt: now
        )
    }

    public func addRow(data: [String: String], files: RowFiles) {
        let now = Date()
        // Generar un UUID nuevo para la fila (formato MongoDB)
        let newUUID = UUID().uuidString.lowercased()
        let newRow = CatalogRow(
            _id: BSONObjectID(),
            originalId: newUUID,
            data: data,
            files: files,
            createdAt: now,
            updatedAt: now
        )

        rows.append(newRow)
        persistCatalogChanges()
    }

    public func updateRow(at index: Int, data: [String: String], files: RowFiles) {
        guard index >= 0 && index < rows.count else { return }

        var updatedRow = rows[index]
        updatedRow.data = data
        updatedRow.files = files
        updatedRow.updatedAt = Date()
        // Preservar el originalId
        // (ya está en updatedRow, no hace falta reasignarlo)

        rows[index] = updatedRow
        persistCatalogChanges()
    }

    public func deleteRow(at index: Int) {
        guard index >= 0 && index < rows.count else { return }
        rows.remove(at: index)
        persistCatalogChanges()
    }
    
    public func moveRow(from source: IndexSet, to destination: Int) {
        rows.move(fromOffsets: source, toOffset: destination)
        persistCatalogChanges()
    }

    public func persistCatalogChanges() {
        var updatedCatalog = catalog
        updatedCatalog.rows = rows
        updatedCatalog.updatedAt = Date()
        catalog = updatedCatalog

        Task {
            do {
                try await mongoService.updateCatalog(updatedCatalog)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Vista principal

public struct CatalogDetailView: View {
    @StateObject private var viewModel: CatalogDetailViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedRowIndex: Int?
    @State private var selectedFile: SelectedFile?

    public init(catalog: Catalog) {
        _viewModel = StateObject(wrappedValue: CatalogDetailViewModel(catalog: catalog))
    }

    public var body: some View {
        VStack {
            // Header
            HStack {
                Text(viewModel.catalog.name)
                    .font(.largeTitle).fontWeight(.bold)

                Spacer()

                Button(viewModel.isEditing ? "Terminar edición" : "Editar") {
                    if viewModel.isEditing {
                        // Al salir del modo edición, guardar cambios
                        viewModel.persistCatalogChanges()
                    }
                    viewModel.isEditing.toggle()
                }
                .buttonStyle(.borderedProminent)

                if viewModel.isEditing {
                    Button(action: { viewModel.showingAddRowSheet = true }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()

            // Descripción
            Text(viewModel.catalog.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Cabecera columnas
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.catalog.columns, id: \.self) { column in
                        Text(column)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Text("Archivos")
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            // Contenido
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("Error al cargar filas").font(.headline).foregroundColor(.red)
                    Text(errorMessage).font(.subheadline).foregroundColor(.secondary)
                    Button("Reintentar") { viewModel.loadRows() }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.rows.isEmpty {
                VStack {
                    Text("No hay filas disponibles").font(.headline)
                    Text("Añada nuevas filas para comenzar")
                        .font(.subheadline).foregroundColor(.secondary)
                    Button("Añadir fila") { viewModel.showingAddRowSheet = true }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if viewModel.isEditing {
                    // Modo edición: Lista con reordenamiento
                    List {
                        ForEach(viewModel.rows.indices, id: \.self) { index in
                            CatalogRowView(
                                row: viewModel.rows[index],
                                columns: viewModel.catalog.columns,
                                catalogId: viewModel.catalog.id,
                                isEditing: viewModel.isEditing,
                                onEdit: { viewModel.updateRow(at: index, data: $0, files: $1) },
                                onDelete: { viewModel.deleteRow(at: index) },
                                onFileSelected: { url, name in
                                    print("👁 DEBUG - onFileSelected callback llamado (modo edición):")
                                    print("  URL recibida: \(url)")
                                    print("  Nombre recibido: \(name)")
                                    selectedFile = SelectedFile(url: url, fileName: name)
                                    print("  selectedFile creado: url=\(url), name=\(name)")
                                }
                            )
                            .listRowBackground(index % 2 == 0 ? Color.blue.opacity(0.05) : Color.clear)
                        }
                        .onMove(perform: viewModel.moveRow)
                    }
                    .listStyle(.plain)
                } else {
                    // Modo visualización: ScrollView normal
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.rows.indices, id: \.self) { index in
                                CatalogRowView(
                                    row: viewModel.rows[index],
                                    columns: viewModel.catalog.columns,
                                    catalogId: viewModel.catalog.id,
                                    isEditing: viewModel.isEditing,
                                    onEdit: { viewModel.updateRow(at: index, data: $0, files: $1) },
                                    onDelete: { viewModel.deleteRow(at: index) },
                                    onFileSelected: { url, name in
                                        print("👁 DEBUG - onFileSelected callback llamado (modo visualización):")
                                        print("  URL recibida: \(url)")
                                        print("  Nombre recibido: \(name)")
                                        selectedFile = SelectedFile(url: url, fileName: name)
                                        print("  selectedFile creado: url=\(url), name=\(name)")
                                    }
                                )
                                .padding(.horizontal, 16)
                                .background(index % 2 == 0 ? Color.blue.opacity(0.05) : Color.clear)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .onAppear {
            // Recargar datos desde MongoDB al aparecer la vista
            viewModel.reloadCatalog()
        }
        .sheet(isPresented: $viewModel.showingAddRowSheet) {
            AddRowView(
                columns: viewModel.catalog.columns,
                catalogId: viewModel.catalog.id,
                onSave: { data, files in
                    viewModel.addRow(data: data, files: files)
                }
            )
            .environmentObject(authViewModel)
        }
        .sheet(item: $selectedFile) { file in
            FileViewerView(
                url: file.url,
                fileName: file.fileName
            )
        }
    }
}

// MARK: - Wrapper para datos de edición
struct EditableRowData: Identifiable {
    let id = UUID()
    let data: [String: String]
}

// MARK: - Wrapper para archivo seleccionado
struct SelectedFile: Identifiable {
    let id = UUID()
    let url: String
    let fileName: String
}

// MARK: - Fila

struct CatalogRowView: View {
    let row: CatalogRow
    let columns: [String]
    let catalogId: String
    let isEditing: Bool
    let onEdit: ([String: String], RowFiles) -> Void
    let onDelete: () -> Void
    let onFileSelected: (String, String) -> Void
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var dataToEdit: EditableRowData?
    @State private var isExpanded = false
    
    // Título de la fila: fecha + segundo campo (primera columna del usuario)
    private var rowTitle: String {
        var title = ""
        
        // Agregar fecha si existe
        if let fecha = row.data["_fecha"], !fecha.isEmpty {
            title = fecha
        }
        
        // Obtener la segunda columna (primera del usuario) si existe
        if columns.count >= 1,
           let firstUserValue = row.data[columns[0]],
           !firstUserValue.isEmpty {
            if !title.isEmpty {
                title += " - "
            }
            title += firstUserValue
        }
        
        // Fallback: ID corto de la fila
        if title.isEmpty {
            return "Fila \(row.id.prefix(8))"
        }
        
        return title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabecera de fila
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { isExpanded.toggle() }
                }) {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.blue)
                        Text(rowTitle)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Contador de archivos
                let totalFiles = getTotalFiles()
                if totalFiles > 0 {
                    HStack {
                        Image(systemName: "paperclip")
                        Text("\(totalFiles)")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }

                if isEditing {
                    HStack(spacing: 8) {
                        Button(action: {
                            // Inicializar dataToEdit con TODAS las columnas
                            var fullData: [String: String] = [:]
                            for column in columns {
                                fullData[column] = row.data[column] ?? ""
                            }
                            print("🔍 DEBUG - Datos antes de editar:")
                            print("  Columnas: \(columns)")
                            print("  row.data: \(row.data)")
                            print("  fullData: \(fullData)")
                            dataToEdit = EditableRowData(data: fullData)
                        }) {
                            Image(systemName: "pencil").foregroundColor(.blue)
                        }

                        Button(action: onDelete) {
                            Image(systemName: "trash").foregroundColor(.red)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            .cornerRadius(8)
            .shadow(radius: 2)

            // Contenido expandido
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Datos
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Datos de la fila").font(.headline)
                        
                        // Mostrar fecha primero si existe
                        if let fecha = row.data["_fecha"], !fecha.isEmpty {
                            HStack {
                                Text("Fecha")
                                    .fontWeight(.semibold)
                                    .frame(width: 120, alignment: .leading)
                                Text(fecha)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        ForEach(columns, id: \.self) { column in
                            HStack {
                                Text(column)
                                    .fontWeight(.semibold)
                                    .frame(width: 120, alignment: .leading)
                                Text(row.data[column] ?? "")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)

                    // Archivos
                    if hasFiles {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Archivos asociados").font(.headline)

                            if let image = row.files.image {
                                FileItemView(url: image, type: "Imagen principal") {
                                    let fileName = URL(string: image)?.lastPathComponent ?? "Imagen principal"
                                    print("📝 DEBUG - Imagen seleccionada:")
                                    print("  URL: \(image)")
                                    print("  Nombre: \(fileName)")
                                    onFileSelected(image, fileName)
                                }
                            }

                            if let document = row.files.document {
                                FileItemView(url: document, type: "Documento principal") {
                                    let fileName = URL(string: document)?.lastPathComponent ?? "Documento principal"
                                    print("📝 DEBUG - Documento seleccionado:")
                                    print("  URL: \(document)")
                                    print("  Nombre: \(fileName)")
                                    onFileSelected(document, fileName)
                                }
                            }

                            if let multimedia = row.files.multimedia {
                                FileItemView(url: multimedia, type: "Multimedia principal") {
                                    let fileName = URL(string: multimedia)?.lastPathComponent ?? "Multimedia principal"
                                    print("📝 DEBUG - Multimedia seleccionado:")
                                    print("  URL: \(multimedia)")
                                    print("  Nombre: \(fileName)")
                                    onFileSelected(multimedia, fileName)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    } else {
                        Text("No hay archivos asociados")
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .sheet(item: $dataToEdit) { editableData in
            EditRowView(
                data: editableData.data,
                files: row.files,
                columns: columns,
                catalogId: catalogId
            ) { updatedData, updatedFiles in
                onEdit(updatedData, updatedFiles)
                dataToEdit = nil
            }
            .environmentObject(authViewModel)
        }
    }

    private func getTotalFiles() -> Int {
        (row.files.image != nil ? 1 : 0) +
        (row.files.document != nil ? 1 : 0) +
        (row.files.multimedia != nil ? 1 : 0) +
        row.files.images.count +
        row.files.documents.count +
        row.files.multimediaFiles.count
    }

    private var hasFiles: Bool {
        row.files.image != nil ||
        row.files.document != nil ||
        row.files.multimedia != nil ||
        !row.files.images.isEmpty ||
        !row.files.documents.isEmpty ||
        !row.files.multimediaFiles.isEmpty
    }
}

// MARK: - Ítem de archivo

struct FileItemView: View {
    let url: String
    let type: String
    let onSelect: () -> Void

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.blue)

            Text(fileName)
                .lineLimit(1)

            Spacer()

            Button("Ver") { onSelect() }
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }

    private var fileName: String {
        if let u = URL(string: url) { return u.lastPathComponent }
        return url
    }

    private var iconName: String {
        let lower = fileName.lowercased()
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") {
            return "photo"
        } else if lower.hasSuffix(".pdf") {
            return "doc.richtext"
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") || lower.hasSuffix(".avi") {
            return "play.rectangle"
        } else {
            return "doc"
        }
    }
}

// MARK: - Alta / edición de fila

struct AddRowView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    let columns: [String]
    let catalogId: String
    let onSave: ([String: String], RowFiles) -> Void

    @State private var data: [String: String] = [:]
    @State private var selectedDate: Date = Date() // Fecha por defecto: hoy
    @State private var imageUrl: String = ""
    @State private var documentUrl: String = ""
    @State private var multimediaUrl: String = ""
    @State private var showValidationError = false
    
    // Arrays para múltiples archivos
    @State private var additionalImages: [String] = []
    @State private var additionalDocuments: [String] = []
    @State private var additionalMultimedia: [String] = []
    
    // Estados para archivos seleccionados
    @State private var selectedImageFile: URL?
    @State private var selectedDocumentFile: URL?
    @State private var selectedMultimediaFile: URL?
    
    // Estados de subida
    @State private var isUploadingImage = false
    @State private var isUploadingDocument = false
    @State private var isUploadingMultimedia = false
    @State private var uploadError: String?

    init(columns: [String], catalogId: String, onSave: @escaping ([String: String], RowFiles) -> Void) {
        self.columns = columns
        self.catalogId = catalogId
        self.onSave = onSave

        var initialData: [String: String] = [:]
        for column in columns { initialData[column] = "" }
        _data = State(initialValue: initialData)
    }
    
    private var hasRequiredData: Bool {
        // Al menos un campo debe tener datos
        return data.values.contains(where: { !$0.isEmpty })
    }
    
    private var isUploading: Bool {
        isUploadingImage || isUploadingDocument || isUploadingMultimedia
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header - siempre visible
            HStack {
                Text("Añadir Nueva Fila").font(.headline)
                Spacer()
                Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.plain)
                    .disabled(isUploading)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()

            // Contenido con scroll
            ScrollView {
                Form {
                Section(header: Text("Datos")) {
                    // Campo de fecha (primera columna lógica)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fecha")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    // Columnas del usuario
                    ForEach(columns, id: \.self) { column in
                        TextField(column, text: Binding(
                            get: { data[column] ?? "" },
                            set: { data[column] = $0 }
                        ))
                        .disabled(isUploading)
                    }
                }

                Section(header: Text("Archivos (opcional)")) {
                    // Imagen
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Imagen principal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FileSelectionRow(
                            title: "Subir desde archivo",
                            selectedFile: $selectedImageFile,
                            existingUrl: $imageUrl,
                            isUploading: isUploadingImage,
                            fileType: .image,
                            onSelect: { selectFile(for: .image) }
                        )
                        
                        Text("O ingresa una URL externa:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("https://ejemplo.com/imagen.jpg", text: $imageUrl)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isUploadingImage || selectedImageFile != nil)
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    // Documento
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Documento principal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FileSelectionRow(
                            title: "Subir desde archivo",
                            selectedFile: $selectedDocumentFile,
                            existingUrl: $documentUrl,
                            isUploading: isUploadingDocument,
                            fileType: .document,
                            onSelect: { selectFile(for: .document) }
                        )
                        
                        Text("O ingresa una URL externa:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("https://ejemplo.com/documento.pdf", text: $documentUrl)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isUploadingDocument || selectedDocumentFile != nil)
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    // Multimedia
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Multimedia principal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FileSelectionRow(
                            title: "Subir desde archivo",
                            selectedFile: $selectedMultimediaFile,
                            existingUrl: $multimediaUrl,
                            isUploading: isUploadingMultimedia,
                            fileType: .multimedia,
                            onSelect: { selectFile(for: .multimedia) }
                        )
                        
                        Text("O ingresa una URL externa:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("https://ejemplo.com/video.mp4", text: $multimediaUrl)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isUploadingMultimedia || selectedMultimediaFile != nil)
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Múltiples imágenes adicionales
                    MultipleFilesSection(
                        title: "Imágenes adicionales",
                        fileType: .image,
                        urls: $additionalImages,
                        onSelectFile: { selectFile(for: .image) },
                        isUploading: isUploadingImage
                    )
                    
                    Divider()
                    
                    // Múltiples documentos adicionales
                    MultipleFilesSection(
                        title: "Documentos adicionales",
                        fileType: .document,
                        urls: $additionalDocuments,
                        onSelectFile: { selectFile(for: .document) },
                        isUploading: isUploadingDocument
                    )
                    
                    Divider()
                    
                    // Múltiples archivos multimedia adicionales
                    MultipleFilesSection(
                        title: "Archivos multimedia adicionales",
                        fileType: .multimedia,
                        urls: $additionalMultimedia,
                        onSelectFile: { selectFile(for: .multimedia) },
                        isUploading: isUploadingMultimedia
                    )
                }
                
                if let uploadError = uploadError {
                    Section {
                        Text("❌ Error: \(uploadError)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if showValidationError {
                    Section {
                        Text("⚠️ Debes completar al menos un campo de datos")
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
                }
                .padding()
            }
            
            Divider()
            
            // Footer - siempre visible
            HStack {
                Spacer()
                Button("Guardar") {
                    Task {
                        await uploadFilesAndSave()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isUploading || !hasRequiredData)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 550, idealWidth: 600, maxWidth: 700, minHeight: 500, idealHeight: 700, maxHeight: 900)
    }
    
    // MARK: - Funciones de selección y subida de archivos
    
    private func selectFile(for fileType: FileType) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        // Configurar tipos permitidos según el tipo de archivo
        switch fileType {
        case .image:
            panel.allowedContentTypes = [.png, .jpeg, .gif, .bmp, .tiff, .heic]
            panel.message = "Selecciona una imagen (máx. 20MB)"
        case .document:
            panel.allowedContentTypes = [.plainText, .rtf, .html, 
                                        UTType(filenameExtension: "doc")!,
                                        UTType(filenameExtension: "docx")!,
                                        UTType(filenameExtension: "xls")!,
                                        UTType(filenameExtension: "xlsx")!]
            panel.message = "Selecciona un documento (máx. 50MB)"
        case .pdf:
            panel.allowedContentTypes = [.pdf]
            panel.message = "Selecciona un PDF (máx. 50MB)"
        case .multimedia:
            panel.allowedContentTypes = [.movie, .audio, .mpeg4Movie, .quickTimeMovie,
                                        UTType(filenameExtension: "mp3")!,
                                        UTType(filenameExtension: "wav")!,
                                        UTType(filenameExtension: "avi")!]
            panel.message = "Selecciona un archivo multimedia (máx. 300MB)"
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Validar tamaño del archivo
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    
                    let maxSize: Int64
                    switch fileType {
                    case .image: maxSize = 20 * 1024 * 1024 // 20MB
                    case .document: maxSize = 50 * 1024 * 1024 // 50MB
                    case .pdf: maxSize = 50 * 1024 * 1024 // 50MB
                    case .multimedia: maxSize = 300 * 1024 * 1024 // 300MB
                    }
                    
                    if fileSize > maxSize {
                        let maxSizeMB = maxSize / (1024 * 1024)
                        self.uploadError = "El archivo excede el tamaño máximo de \(maxSizeMB)MB"
                        return
                    }
                    
                    // Guardar el archivo seleccionado
                    switch fileType {
                    case .image:
                        self.selectedImageFile = url
                        self.uploadError = nil
                    case .document, .pdf:
                        self.selectedDocumentFile = url
                        self.uploadError = nil
                    case .multimedia:
                        self.selectedMultimediaFile = url
                        self.uploadError = nil
                    }
                } catch {
                    self.uploadError = "Error al validar el archivo: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func uploadFilesAndSave() async {
        // Validar que hay datos
        guard hasRequiredData else {
            showValidationError = true
            return
        }
        
        // Limpiar error previo
        uploadError = nil
        
        // Agregar fecha al data
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "es_ES")
        data["_fecha"] = dateFormatter.string(from: selectedDate)
        
        // Subir archivos si están seleccionados
        var finalImageUrl = imageUrl
        var finalDocumentUrl = documentUrl
        var finalMultimediaUrl = multimediaUrl
        
        // Obtener userId del usuario autenticado
        guard let userId = authViewModel.currentUser?.id else {
            uploadError = "Error: Usuario no autenticado"
            return
        }
        
        // Subir imagen si está seleccionada
        if let imageFile = selectedImageFile {
            isUploadingImage = true
            do {
                finalImageUrl = try await S3Service.shared.uploadFile(
                    fileUrl: imageFile,
                    userId: userId,
                    catalogId: catalogId,
                    fileType: .image
                )
            } catch {
                uploadError = "Error al subir imagen: \(error.localizedDescription)"
                isUploadingImage = false
                return
            }
            isUploadingImage = false
        }
        
        // Subir documento si está seleccionado
        if let documentFile = selectedDocumentFile {
            isUploadingDocument = true
            do {
                finalDocumentUrl = try await S3Service.shared.uploadFile(
                    fileUrl: documentFile,
                    userId: userId,
                    catalogId: catalogId,
                    fileType: .document
                )
            } catch {
                uploadError = "Error al subir documento: \(error.localizedDescription)"
                isUploadingDocument = false
                return
            }
            isUploadingDocument = false
        }
        
        // Subir multimedia si está seleccionado
        if let multimediaFile = selectedMultimediaFile {
            isUploadingMultimedia = true
            do {
                finalMultimediaUrl = try await S3Service.shared.uploadFile(
                    fileUrl: multimediaFile,
                    userId: userId,
                    catalogId: catalogId,
                    fileType: .multimedia
                )
            } catch {
                uploadError = "Error al subir multimedia: \(error.localizedDescription)"
                isUploadingMultimedia = false
                return
            }
            isUploadingMultimedia = false
        }
        
        // Crear objeto RowFiles con las URLs finales
        let files = RowFiles(
            image: finalImageUrl.isEmpty ? nil : finalImageUrl,
            images: additionalImages,
            document: finalDocumentUrl.isEmpty ? nil : finalDocumentUrl,
            documents: additionalDocuments,
            multimedia: finalMultimediaUrl.isEmpty ? nil : finalMultimediaUrl,
            multimediaFiles: additionalMultimedia
        )
        
        // Guardar los datos
        onSave(data, files)
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditRowView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var data: [String: String]
    @State private var selectedDate: Date = Date()
    @State private var imageUrl: String
    @State private var documentUrl: String
    @State private var multimediaUrl: String
    
    // Arrays para múltiples archivos
    @State private var additionalImages: [String] = []
    @State private var additionalDocuments: [String] = []
    @State private var additionalMultimedia: [String] = []
    
    // Estados para archivos seleccionados
    @State private var selectedImageFile: URL?
    @State private var selectedDocumentFile: URL?
    @State private var selectedMultimediaFile: URL?
    
    // Estados de subida
    @State private var isUploadingImage = false
    @State private var isUploadingDocument = false
    @State private var isUploadingMultimedia = false
    @State private var uploadError: String?
    
    // Computed property para saber si hay subida en progreso
    private var isUploading: Bool {
        isUploadingImage || isUploadingDocument || isUploadingMultimedia
    }

    let columns: [String]
    let catalogId: String
    let onSave: ([String: String], RowFiles) -> Void
    
    // Helper para parsear fecha del string
    static func parseFecha(_ fechaStr: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "es_ES")
        return dateFormatter.date(from: fechaStr)
    }

    init(data: [String: String], files: RowFiles, columns: [String], catalogId: String, onSave: @escaping ([String: String], RowFiles) -> Void) {
        print("🔍 DEBUG - EditRowView init:")
        print("  data recibido: \(data)")
        print("  columns: \(columns)")
        print("  files.image: \(files.image ?? "nil")")
        print("  files.document: \(files.document ?? "nil")")
        print("  files.multimedia: \(files.multimedia ?? "nil")")

        _data = State(initialValue: data)
        
        // Cargar fecha si existe, sino usar hoy
        if let fechaStr = data["_fecha"],
           let fecha = EditRowView.parseFecha(fechaStr) {
            _selectedDate = State(initialValue: fecha)
        } else {
            _selectedDate = State(initialValue: Date())
        }
        
        _imageUrl = State(initialValue: files.image ?? "")
        _documentUrl = State(initialValue: files.document ?? "")
        _multimediaUrl = State(initialValue: files.multimedia ?? "")
        _additionalImages = State(initialValue: files.images)
        _additionalDocuments = State(initialValue: files.documents)
        _additionalMultimedia = State(initialValue: files.multimediaFiles)
        self.columns = columns
        self.catalogId = catalogId
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header - siempre visible
            HStack {
                Text("Editar Fila").font(.headline)
                Spacer()
                Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Contenido con scroll
            ScrollView {
                Form {
                Section(header: Text("Datos")) {
                    // Campo de fecha (primera columna lógica)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fecha")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    // Columnas del usuario
                    ForEach(columns, id: \.self) { column in
                        TextField(column, text: Binding(
                            get: { data[column] ?? "" },
                            set: { data[column] = $0 }
                        ))
                        .disabled(isUploading)
                    }
                }

                Section(header: Text("Archivos (opcional)")) {
                    // Imagen
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Imagen principal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FileSelectionRow(
                            title: "Subir desde archivo",
                            selectedFile: $selectedImageFile,
                            existingUrl: $imageUrl,
                            isUploading: isUploadingImage,
                            fileType: .image,
                            onSelect: { selectFile(for: .image) }
                        )
                        
                        Text("O ingresa una URL externa:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("https://ejemplo.com/imagen.jpg", text: $imageUrl)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isUploadingImage || selectedImageFile != nil)
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    // Documento
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Documento principal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FileSelectionRow(
                            title: "Subir desde archivo",
                            selectedFile: $selectedDocumentFile,
                            existingUrl: $documentUrl,
                            isUploading: isUploadingDocument,
                            fileType: .document,
                            onSelect: { selectFile(for: .document) }
                        )
                        
                        Text("O ingresa una URL externa:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("https://ejemplo.com/documento.pdf", text: $documentUrl)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isUploadingDocument || selectedDocumentFile != nil)
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    // Multimedia
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Multimedia principal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FileSelectionRow(
                            title: "Subir desde archivo",
                            selectedFile: $selectedMultimediaFile,
                            existingUrl: $multimediaUrl,
                            isUploading: isUploadingMultimedia,
                            fileType: .multimedia,
                            onSelect: { selectFile(for: .multimedia) }
                        )
                        
                        Text("O ingresa una URL externa:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("https://ejemplo.com/video.mp4", text: $multimediaUrl)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isUploadingMultimedia || selectedMultimediaFile != nil)
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Múltiples imágenes adicionales
                    MultipleFilesSection(
                        title: "Imágenes adicionales",
                        fileType: .image,
                        urls: $additionalImages,
                        onSelectFile: { selectFile(for: .image) },
                        isUploading: isUploadingImage
                    )
                    
                    Divider()
                    
                    // Múltiples documentos adicionales
                    MultipleFilesSection(
                        title: "Documentos adicionales",
                        fileType: .document,
                        urls: $additionalDocuments,
                        onSelectFile: { selectFile(for: .document) },
                        isUploading: isUploadingDocument
                    )
                    
                    Divider()
                    
                    // Múltiples archivos multimedia adicionales
                    MultipleFilesSection(
                        title: "Archivos multimedia adicionales",
                        fileType: .multimedia,
                        urls: $additionalMultimedia,
                        onSelectFile: { selectFile(for: .multimedia) },
                        isUploading: isUploadingMultimedia
                    )
                }
                }
                .padding()
            }
            
            Divider()
            
            // Footer - siempre visible
            HStack {
                Spacer()
                Button(isUploading ? "Subiendo..." : "Guardar") {
                    Task {
                        await uploadFilesAndSave()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isUploading)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 550, idealWidth: 600, maxWidth: 700, minHeight: 500, idealHeight: 700, maxHeight: 900)
    }
    
    // MARK: - Funciones de selección de archivos
    
    private func selectFile(for fileType: FileType) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        // Configurar filtros según el tipo de archivo
        switch fileType {
        case .image:
            panel.allowedContentTypes = [.png, .jpeg, .gif, .bmp, .tiff, .heic]
            panel.message = "Selecciona una imagen (máx. 20MB)"
        case .document:
            panel.allowedContentTypes = [.plainText, .rtf, .html, .pdf]
            panel.message = "Selecciona un documento (máx. 50MB)"
        case .pdf:
            panel.allowedContentTypes = [.pdf]
            panel.message = "Selecciona un PDF (máx. 50MB)"
        case .multimedia:
            panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .avi, .mpeg, .mp3, .wav]
            panel.message = "Selecciona un archivo multimedia (máx. 300MB)"
        }
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            // Validar tamaño del archivo
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                let maxSize: Int64
                
                switch fileType {
                case .image:
                    maxSize = 20 * 1024 * 1024 // 20MB
                case .document, .pdf:
                    maxSize = 50 * 1024 * 1024 // 50MB
                case .multimedia:
                    maxSize = 300 * 1024 * 1024 // 300MB
                }
                
                if fileSize > maxSize {
                    uploadError = "El archivo excede el tamaño máximo permitido"
                    return
                }
                
                // Asignar el archivo seleccionado
                switch fileType {
                case .image:
                    selectedImageFile = url
                case .document, .pdf:
                    selectedDocumentFile = url
                case .multimedia:
                    selectedMultimediaFile = url
                }
                
                uploadError = nil
            } catch {
                uploadError = "Error al validar el archivo: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Función de subida de archivos
    
    private func uploadFilesAndSave() async {
        print("🔐 Obteniendo usuario actual para subida de archivos")
        guard let userId = authViewModel.currentUser?.id else {
            uploadError = "Error: Usuario no autenticado"
            return
        }
        
        print("👤 Usuario ID: \(userId)")
        
        // Actualizar fecha en data
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "es_ES")
        data["_fecha"] = dateFormatter.string(from: selectedDate)
        
        var finalImageUrl = imageUrl
        var finalDocumentUrl = documentUrl
        var finalMultimediaUrl = multimediaUrl
        
        // Subir imagen si hay una seleccionada
        if let imageFile = selectedImageFile {
            print("📤 Iniciando subida de imagen...")
            isUploadingImage = true
            do {
                let url = try await S3Service.shared.uploadFile(
                    fileUrl: imageFile,
                    userId: userId,
                    catalogId: catalogId,
                    fileType: .image
                )
                finalImageUrl = url
                print("✅ Imagen subida exitosamente: \(url)")
            } catch {
                uploadError = "Error al subir imagen: \(error.localizedDescription)"
                isUploadingImage = false
                return
            }
            isUploadingImage = false
        }
        
        // Subir documento si hay uno seleccionado
        if let documentFile = selectedDocumentFile {
            print("📤 Iniciando subida de documento...")
            isUploadingDocument = true
            do {
                let url = try await S3Service.shared.uploadFile(
                    fileUrl: documentFile,
                    userId: userId,
                    catalogId: catalogId,
                    fileType: .document
                )
                finalDocumentUrl = url
                print("✅ Documento subido exitosamente: \(url)")
            } catch {
                uploadError = "Error al subir documento: \(error.localizedDescription)"
                isUploadingDocument = false
                return
            }
            isUploadingDocument = false
        }
        
        // Subir multimedia si hay uno seleccionado
        if let multimediaFile = selectedMultimediaFile {
            print("📤 Iniciando subida de multimedia...")
            isUploadingMultimedia = true
            do {
                let url = try await S3Service.shared.uploadFile(
                    fileUrl: multimediaFile,
                    userId: userId,
                    catalogId: catalogId,
                    fileType: .multimedia
                )
                finalMultimediaUrl = url
                print("✅ Multimedia subido exitosamente: \(url)")
            } catch {
                uploadError = "Error al subir multimedia: \(error.localizedDescription)"
                isUploadingMultimedia = false
                return
            }
            isUploadingMultimedia = false
        }
        
        // Crear objeto RowFiles con las URLs finales
        let files = RowFiles(
            image: finalImageUrl.isEmpty ? nil : finalImageUrl,
            images: additionalImages,
            document: finalDocumentUrl.isEmpty ? nil : finalDocumentUrl,
            documents: additionalDocuments,
            multimedia: finalMultimediaUrl.isEmpty ? nil : finalMultimediaUrl,
            multimediaFiles: additionalMultimedia
        )
        
        print("💾 Guardando fila en MongoDB...")
        onSave(data, files)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Visor de archivo (sin dependencia de FileType global)

struct FileViewerView: View {
    let url: String
    let fileName: String
    @Environment(\.presentationMode) var presentationMode
    
    @State private var presignedUrl: URL?
    @State private var urlError: String?
    @State private var isLoadingPresigned = false

    // Deducción local del "tipo" por extensión — evita ambigüedad con FileType
    private enum LocalFileKind { case image, pdf, video, text, other }

    private var kind: LocalFileKind {
        let lower = fileName.lowercased()
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") {
            return .image
        } else if lower.hasSuffix(".pdf") {
            return .pdf
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") || lower.hasSuffix(".avi") {
            return .video
        } else if lower.hasSuffix(".txt") || lower.hasSuffix(".md") || lower.hasSuffix(".rtf") || lower.hasSuffix(".json") || lower.hasSuffix(".xml") || lower.hasSuffix(".csv") || lower.hasSuffix(".html") || lower.hasSuffix(".htm") {
            return .text
        } else {
            return .other
        }
    }

    private var resolvedURL: URL? {
        // Usar la URL pre-firmada si está disponible, sino la original
        return presignedUrl ?? URL(string: url)
    }

    var body: some View {
        let _ = print("📺 DEBUG - FileViewerView body renderizado:")
        let _ = print("  URL: \(url)")
        let _ = print("  fileName: \(fileName)")
        
        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("Visor de Archivo")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button("Cerrar") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // ScrollView para el contenido
            ScrollView {
                VStack(spacing: 15) {
                    // Icono y metadata - más compacto
                    HStack(spacing: 15) {
                        Image(systemName: fileTypeIcon)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fileName)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(fileTypeDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Divider()

                    // Vista previa
                    Group {
                        if isLoadingPresigned {
                            VStack {
                                ProgressView()
                                Text("Cargando archivo...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(minHeight: 200)
                        } else if let error = urlError {
                            VStack {
                                Text("⚠️ \(error)")
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(minHeight: 200)
                        } else {
                            switch kind {
                            case .image:
                                if let u = resolvedURL {
                                    if #available(macOS 12.0, *) {
                                        AsyncImage(url: u) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView("Descargando imagen...")
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(maxHeight: 500)
                                            case .failure(_):
                                                VStack {
                                                    Text("🔒 Imagen en bucket privado")
                                                        .font(.subheadline)
                                                    Text("Usa 'Abrir externamente' para verla")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        .frame(minHeight: 200)
                                    } else {
                                        Text("Vista previa no disponible en esta versión de macOS")
                                    }
                                } else {
                                    Text("URL inválida")
                                }
                            
                            case .pdf:
                                if let u = resolvedURL {
                                    VStack(spacing: 10) {
                                        PDFKitView(url: u)
                                            .frame(height: 400)
                                        Button {
                                            openPDFViewer(url: u)
                                        } label: {
                                            Label("Abrir en visor PDF completo", systemImage: "doc.richtext")
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                } else {
                                    VStack {
                                        Text("📝 Archivo PDF")
                                            .font(.subheadline)
                                        Text("URL inválida")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    .frame(minHeight: 200)
                                }
                            
                            case .video:
                                if let u = resolvedURL {
                                    VStack(spacing: 10) {
                                        VideoPlayerView(url: u)
                                            .frame(height: 500)
                                            .cornerRadius(10)
                                        Text("🎥 Reproductor de video")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    VStack {
                                        Text("🎥 Archivo de video")
                                            .font(.subheadline)
                                        Text("URL inválida")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    .frame(minHeight: 200)
                                }
                            
                            case .text:
                                if let u = resolvedURL {
                                    VStack(spacing: 10) {
                                        Text("📄 Documento de texto")
                                            .font(.headline)
                                        Button {
                                            openTextViewer(url: u)
                                        } label: {
                                            Label("Abrir en visor de texto", systemImage: "doc.text")
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                    .frame(minHeight: 200)
                                } else {
                                    Text("URL inválida")
                                        .frame(minHeight: 200)
                                }
                            
                            case .other:
                                VStack {
                                    Text("📄 Archivo")
                                        .font(.subheadline)
                                    Text("Usa 'Abrir externamente' para verlo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(minHeight: 200)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }

            // Footer - SIEMPRE VISIBLE
            Divider()
            HStack {
                Button("Descargar") { downloadFile() }
                    .buttonStyle(.bordered)

                Spacer()

                Button("Abrir externamente") { openExternally() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 900, height: 800)
        .onAppear {
            loadPresignedUrl()
        }
    }
    
    private func loadPresignedUrl() {
        isLoadingPresigned = true
        
        Task {@MainActor in
            do {
                print("🔑 Solicitando URL pre-firmada para: \(url)")
                let s3Service = S3Service.shared
                let signed = try await s3Service.generatePresignedUrl(for: url, expirationInSeconds: 3600)
                
                print("✅ URL pre-firmada recibida")
                self.presignedUrl = signed
                self.isLoadingPresigned = false
            } catch {
                print("❌ Error: \(error)")
                // Fallback a URL directa
                if let directUrl = URL(string: url) {
                    self.presignedUrl = directUrl
                } else {
                    self.urlError = "URL inválida: \(url)"
                }
                self.isLoadingPresigned = false
            }
        }
    }

    private var fileTypeIcon: String {
        let lower = fileName.lowercased()
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") {
            return "photo"
        } else if lower.hasSuffix(".pdf") {
            return "doc.richtext"
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") || lower.hasSuffix(".avi") {
            return "play.rectangle"
        } else {
            return "doc"
        }
    }

    private var fileTypeDescription: String {
        let lower = fileName.lowercased()
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") {
            return "Imagen"
        } else if lower.hasSuffix(".pdf") {
            return "PDF"
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") || lower.hasSuffix(".avi") {
            return "Archivo multimedia"
        } else {
            return "Documento"
        }
    }

    private func downloadFile() {
        // Abrir URL directamente en el navegador
        if let urlObj = URL(string: url) {
            print("👁 Abriendo URL para descargar: \(url)")
            NSWorkspace.shared.open(urlObj)
        } else {
            print("❌ URL inválida para descargar: \(url)")
        }
    }

    private func openExternally() {
        // Abrir URL directamente en el navegador
        if let urlObj = URL(string: url) {
            print("👁 Abriendo URL externamente: \(url)")
            NSWorkspace.shared.open(urlObj)
        } else {
            print("❌ URL inválida para abrir: \(url)")
        }
    }
    
    private func openPDFViewer(url: URL) {
        let pdfViewer = PDFViewerView(url: url, fileName: fileName)
        let hostingController = NSHostingController(rootView: pdfViewer)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Visor PDF - \(fileName)"
        window.setContentSize(NSSize(width: 900, height: 700))
        window.makeKeyAndOrderFront(nil)
    }
    
    private func openTextViewer(url: URL) {
        let textViewer = TextDocumentView(url: url, fileName: fileName)
        let hostingController = NSHostingController(rootView: textViewer)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Visor de Texto - \(fileName)"
        window.setContentSize(NSSize(width: 800, height: 600))
        window.makeKeyAndOrderFront(nil)
    }
}

struct PDFKitView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        if let doc = PDFDocument(url: url) {
            pdfView.document = doc
        }
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document == nil || nsView.document?.documentURL != url {
            nsView.document = PDFDocument(url: url)
        }
    }
}

struct VideoPlayerView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.controlsStyle = .floating
        playerView.showsFullScreenToggleButton = true
        
        let player = AVPlayer(url: url)
        playerView.player = player
        
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player?.currentItem?.asset as? AVURLAsset == nil ||
           (nsView.player?.currentItem?.asset as? AVURLAsset)?.url != url {
            let player = AVPlayer(url: url)
            nsView.player = player
        }
    }
}

// MARK: - Preview

struct CatalogDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let catalog = Catalog(
            _id: BSONObjectID(),
            name: "Catálogo de Prueba",
            description: "Descripción del catálogo",
            userId: "user123",
            columns: ["Nombre", "Precio", "Categoría"],
            rows: [],
            legacyRows: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        CatalogDetailView(catalog: catalog)
    }
}
