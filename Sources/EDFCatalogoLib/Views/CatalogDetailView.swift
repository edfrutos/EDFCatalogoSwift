import SwiftUI
import Foundation
import PDFKit
import AVKit
import AVFoundation
import UniformTypeIdentifiers
import WebKit
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

                            // Imagen principal
                            if let image = row.files.image {
                                FileItemView(url: image, type: "Imagen principal") {
                                    let fileName = URL(string: image)?.lastPathComponent ?? "Imagen principal"
                                    onFileSelected(image, fileName)
                                }
                            }
                            // Imágenes adicionales
                            if !row.files.images.isEmpty {
                                ForEach(row.files.images, id: \.self) { img in
                                    FileItemView(url: img, type: "Imagen adicional") {
                                        let fileName = URL(string: img)?.lastPathComponent ?? "Imagen adicional"
                                        onFileSelected(img, fileName)
                                    }
                                }
                            }

                            // Documento principal
                            if let document = row.files.document {
                                FileItemView(url: document, type: "Documento principal") {
                                    let fileName = URL(string: document)?.lastPathComponent ?? "Documento principal"
                                    onFileSelected(document, fileName)
                                }
                            }
                            // Documentos adicionales
                            if !row.files.documents.isEmpty {
                                ForEach(row.files.documents, id: \.self) { doc in
                                    FileItemView(url: doc, type: "Documento adicional") {
                                        let fileName = URL(string: doc)?.lastPathComponent ?? "Documento adicional"
                                        onFileSelected(doc, fileName)
                                    }
                                }
                            }

                            // Multimedia principal
                            if let multimedia = row.files.multimedia {
                                FileItemView(url: multimedia, type: "Multimedia principal") {
                                    let fileName = URL(string: multimedia)?.lastPathComponent ?? "Multimedia principal"
                                    onFileSelected(multimedia, fileName)
                                }
                            }
                            // Multimedia adicional
                            if !row.files.multimediaFiles.isEmpty {
                                ForEach(row.files.multimediaFiles, id: \.self) { media in
                                    FileItemView(url: media, type: "Multimedia adicional") {
                                        let fileName = URL(string: media)?.lastPathComponent ?? "Multimedia adicional"
                                        onFileSelected(media, fileName)
                                    }
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

            Button("Ver") { 
                print("🔘 DEBUG - Botón 'Ver' presionado")
                print("  URL: \(url)")
                print("  Tipo: \(type)")
                onSelect() 
            }
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }

    private var fileName: String {
        guard let urlObj = URL(string: url) else { return "Archivo" }
        
        // Para URLs de YouTube, extraer el ID del video
        if url.lowercased().contains("youtube.com") || url.lowercased().contains("youtu.be") {
            if let videoId = extractYouTubeVideoId(from: url) {
                return "Video de YouTube - \(videoId)"
            }
        }
        
        // Para otras URLs de streaming, usar un nombre más descriptivo
        if url.lowercased().contains("vimeo.com") {
            return "Video de Vimeo"
        } else if url.lowercased().contains("dailymotion.com") {
            return "Video de Dailymotion"
        } else if url.lowercased().contains("twitch.tv") {
            return "Video de Twitch"
        }
        
        // Para archivos normales, usar el nombre del archivo
        let lastPath = urlObj.lastPathComponent
        if lastPath.isEmpty || lastPath == "/" {
            return "Archivo multimedia"
        }
        
        return lastPath
    }
    
    private func extractYouTubeVideoId(from urlString: String) -> String? {
        let url = urlString.lowercased()
        
        // Patrón para youtube.com/watch?v=VIDEO_ID
        if let range = url.range(of: "v=") {
            let startIndex = range.upperBound
            let endIndex = url.index(startIndex, offsetBy: 11) // Los IDs de YouTube tienen 11 caracteres
            if endIndex <= url.endIndex {
                return String(url[startIndex..<endIndex])
            }
        }
        
        // Patrón para youtu.be/VIDEO_ID
        if let range = url.range(of: "youtu.be/") {
            let startIndex = range.upperBound
            let endIndex = url.index(startIndex, offsetBy: 11)
            if endIndex <= url.endIndex {
                return String(url[startIndex..<endIndex])
            }
        }
        
        return nil
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
                        onSelectFile: { selectAndUploadAdditionalFile(for: .image) },
                        isUploading: isUploadingImage
                    )
                    
                    Divider()
                    
                    // Múltiples documentos adicionales
                    MultipleFilesSection(
                        title: "Documentos adicionales",
                        fileType: .document,
                        urls: $additionalDocuments,
                        onSelectFile: { selectAndUploadAdditionalFile(for: .document) },
                        isUploading: isUploadingDocument
                    )
                    
                    Divider()
                    
                    // Múltiples archivos multimedia adicionales
                    MultipleFilesSection(
                        title: "Archivos multimedia adicionales",
                        fileType: .multimedia,
                        urls: $additionalMultimedia,
                        onSelectFile: { selectAndUploadAdditionalFile(for: .multimedia) },
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
    
    // Seleccionar y subir archivo ADICIONAL, agregando su URL al array correspondiente
    private func selectAndUploadAdditionalFile(for fileType: FileType) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        switch fileType {
        case .image:
            panel.allowedContentTypes = [.png, .jpeg, .gif, .bmp, .tiff, .heic]
        case .document, .pdf:
            panel.allowedContentTypes = [.plainText, .rtf, .html, .pdf]
        case .multimedia:
            panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .avi, .mpeg, .mp3, .wav]
        }
        
        panel.begin { response in
            guard response == .OK, let fileURL = panel.url else { return }
            Task { @MainActor in
                guard let userId = authViewModel.currentUser?.id else { return }
                do {
                    switch fileType {
                    case .image:
                        isUploadingImage = true
                        let uploaded = try await S3Service.shared.uploadFile(
                            fileUrl: fileURL,
                            userId: userId,
                            catalogId: catalogId,
                            fileType: .image
                        )
                        additionalImages.append(uploaded)
                        isUploadingImage = false
                    case .document, .pdf:
                        isUploadingDocument = true
                        let uploaded = try await S3Service.shared.uploadFile(
                            fileUrl: fileURL,
                            userId: userId,
                            catalogId: catalogId,
                            fileType: .document
                        )
                        additionalDocuments.append(uploaded)
                        isUploadingDocument = false
                    case .multimedia:
                        isUploadingMultimedia = true
                        let uploaded = try await S3Service.shared.uploadFile(
                            fileUrl: fileURL,
                            userId: userId,
                            catalogId: catalogId,
                            fileType: .multimedia
                        )
                        additionalMultimedia.append(uploaded)
                        isUploadingMultimedia = false
                    }
                } catch {
                    uploadError = "Error subiendo archivo adicional: \(error.localizedDescription)"
                    isUploadingImage = false
                    isUploadingDocument = false
                    isUploadingMultimedia = false
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
        
        // Normalizar URLs: si el usuario pegó varias URLs en el mismo campo, separarlas y distribuirlas
        func splitUrls(_ value: String) -> [String] {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return [] }
            // Separar por espacios, saltos de línea o repeticiones de esquema http(s)
            var parts: [String] = []
            var buffer = trimmed
            // Insertar separadores antes de cada "http" excepto el inicial
            buffer = buffer.replacingOccurrences(of: "http://", with: "\nhttp://")
            buffer = buffer.replacingOccurrences(of: "https://", with: "\nhttps://")
            for token in buffer.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
                if t.hasPrefix("http://") || t.hasPrefix("https://") { parts.append(t) }
            }
            return parts
        }

        let imageUrls = splitUrls(imageUrl)
        let documentUrls = splitUrls(documentUrl)
        let multimediaUrls = splitUrls(multimediaUrl)

        // Subir archivos si están seleccionados
        var finalImageUrl = imageUrls.first ?? ""
        var finalDocumentUrl = documentUrls.first ?? ""
        var finalMultimediaUrl = multimediaUrls.first ?? ""
        // Las restantes van a adicionales
        if imageUrls.count > 1 { additionalImages.append(contentsOf: imageUrls.dropFirst()) }
        if documentUrls.count > 1 { additionalDocuments.append(contentsOf: documentUrls.dropFirst()) }
        if multimediaUrls.count > 1 { additionalMultimedia.append(contentsOf: multimediaUrls.dropFirst()) }
        
        // Obtener userId del usuario autenticado
        guard let userId = authViewModel.currentUser?.id else {
            uploadError = "Error: Usuario no autenticado"
            return
        }
        
        // Subir imagen si está seleccionada
        if let imageFile = selectedImageFile {
            isUploadingImage = true
            do {
                let uploaded = try await S3Service.shared.uploadFile(
                    fileUrl: imageFile,
                    userId: userId,
                    catalogId: catalogId,
                    fileType: .image
                )
                if finalImageUrl.isEmpty {
                    finalImageUrl = uploaded
                } else {
                    additionalImages.append(uploaded)
                }
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
                let uploaded = try await S3Service.shared.uploadFile(
                    fileUrl: documentFile,
                    userId: userId,
                    catalogId: catalogId,
                    fileType: .document
                )
                if finalDocumentUrl.isEmpty {
                    finalDocumentUrl = uploaded
                } else {
                    additionalDocuments.append(uploaded)
                }
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
                let uploaded = try await S3Service.shared.uploadFile(
                    fileUrl: multimediaFile,
                    userId: userId,
                    catalogId: catalogId,
                    fileType: .multimedia
                )
                if finalMultimediaUrl.isEmpty {
                    finalMultimediaUrl = uploaded
                } else {
                    additionalMultimedia.append(uploaded)
                }
            } catch {
                uploadError = "Error al subir multimedia: \(error.localizedDescription)"
                isUploadingMultimedia = false
                return
            }
            isUploadingMultimedia = false
        }

        // Asegurar que URL externas también se agreguen sin sobrescribir
        if !imageUrls.isEmpty && !finalImageUrl.isEmpty && imageUrls.first != finalImageUrl {
            additionalImages.append(contentsOf: imageUrls)
        }
        if !documentUrls.isEmpty && !finalDocumentUrl.isEmpty && documentUrls.first != finalDocumentUrl {
            additionalDocuments.append(contentsOf: documentUrls)
        }
        if !multimediaUrls.isEmpty && !finalMultimediaUrl.isEmpty && multimediaUrls.first != finalMultimediaUrl {
            additionalMultimedia.append(contentsOf: multimediaUrls)
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
        
        print("🔍 DEBUG - Archivos adicionales inicializados:")
        print("  additionalImages: \(files.images)")
        print("  additionalDocuments: \(files.documents)")
        print("  additionalMultimedia: \(files.multimediaFiles)")
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
                        onSelectFile: { selectAndUploadAdditionalFile(for: .image) },
                        isUploading: isUploadingImage
                    )
                    
                    Divider()
                    
                    // Múltiples documentos adicionales
                    MultipleFilesSection(
                        title: "Documentos adicionales",
                        fileType: .document,
                        urls: $additionalDocuments,
                        onSelectFile: { selectAndUploadAdditionalFile(for: .document) },
                        isUploading: isUploadingDocument
                    )
                    
                    Divider()
                    
                    // Múltiples archivos multimedia adicionales
                    MultipleFilesSection(
                        title: "Archivos multimedia adicionales",
                        fileType: .multimedia,
                        urls: $additionalMultimedia,
                        onSelectFile: { selectAndUploadAdditionalFile(for: .multimedia) },
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

    // Selecciona un archivo local, lo sube a S3 y AGREGA la URL al array correspondiente
    private func selectAndUploadAdditionalFile(for fileType: FileType) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        switch fileType {
        case .image:
            panel.allowedContentTypes = [.png, .jpeg, .gif, .bmp, .tiff, .heic]
        case .document, .pdf:
            panel.allowedContentTypes = [.plainText, .rtf, .html, .pdf]
        case .multimedia:
            panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .avi, .mpeg, .mp3, .wav]
        }
        
        panel.begin { response in
            guard response == .OK, let fileURL = panel.url else { return }
            Task { @MainActor in
                guard let userId = authViewModel.currentUser?.id else { return }
                do {
                    switch fileType {
                    case .image:
                        isUploadingImage = true
                        let uploaded = try await S3Service.shared.uploadFile(
                            fileUrl: fileURL,
                            userId: userId,
                            catalogId: catalogId,
                            fileType: .image
                        )
                        additionalImages.append(uploaded)
                        isUploadingImage = false
                    case .document, .pdf:
                        isUploadingDocument = true
                        let uploaded = try await S3Service.shared.uploadFile(
                            fileUrl: fileURL,
                            userId: userId,
                            catalogId: catalogId,
                            fileType: .document
                        )
                        additionalDocuments.append(uploaded)
                        isUploadingDocument = false
                    case .multimedia:
                        isUploadingMultimedia = true
                        let uploaded = try await S3Service.shared.uploadFile(
                            fileUrl: fileURL,
                            userId: userId,
                            catalogId: catalogId,
                            fileType: .multimedia
                        )
                        additionalMultimedia.append(uploaded)
                        isUploadingMultimedia = false
                    }
                } catch {
                    uploadError = "Error subiendo archivo adicional: \(error.localizedDescription)"
                    isUploadingImage = false
                    isUploadingDocument = false
                    isUploadingMultimedia = false
                }
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

    // Indica si la URL actual apunta a un vídeo de plataforma de streaming
    private var isStreaming: Bool {
        guard let u = resolvedURL else { return false }
        return isStreamingVideoURL(u)
    }
    private var kind: LocalFileKind {
        let lower = fileName.lowercased()
        let urlLower = url.lowercased()
        
        print("🔍 DEBUG - Detección de tipo de archivo:")
        print("  fileName: \(fileName)")
        print("  url: \(url)")
        print("  lower: \(lower)")
        print("  urlLower: \(urlLower)")
        
        // Detectar por extensión de archivo
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") {
            print("  ✅ Detectado como IMAGEN por extensión")
            return .image
        } else if lower.hasSuffix(".pdf") {
            print("  ✅ Detectado como PDF por extensión")
            return .pdf
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") || lower.hasSuffix(".avi") {
            print("  ✅ Detectado como VIDEO por extensión")
            return .video
        } else if lower.hasSuffix(".txt") || lower.hasSuffix(".md") || lower.hasSuffix(".rtf") || lower.hasSuffix(".json") || lower.hasSuffix(".xml") || lower.hasSuffix(".csv") || lower.hasSuffix(".html") || lower.hasSuffix(".htm") {
            print("  ✅ Detectado como TEXTO por extensión")
            return .text
        }
        
        // Detectar por patrones de URL de video (para URLs externas sin extensión)
        if urlLower.contains("youtube.com") || urlLower.contains("youtu.be") || 
           urlLower.contains("vimeo.com") || urlLower.contains("dailymotion.com") ||
           urlLower.contains("twitch.tv") || urlLower.contains("facebook.com/watch") ||
           urlLower.contains("instagram.com/p/") || urlLower.contains("tiktok.com") ||
           urlLower.contains("streamable.com") || urlLower.contains("gfycat.com") ||
           urlLower.contains("giphy.com") || urlLower.contains("imgur.com") ||
           urlLower.contains("video") || urlLower.contains("watch") ||
           urlLower.contains("play") || urlLower.contains("embed") {
            print("  ✅ Detectado como VIDEO por patrón de URL")
            return .video
        }
        
        // Detectar por patrones de URL de imagen
        if urlLower.contains("image") || urlLower.contains("photo") || urlLower.contains("picture") ||
           urlLower.contains("img") || urlLower.contains("gallery") {
            print("  ✅ Detectado como IMAGEN por patrón de URL")
            return .image
        }
        
        // Detectar por patrones de URL de documento
        if urlLower.contains("document") || urlLower.contains("doc") || urlLower.contains("file") ||
           urlLower.contains("download") || urlLower.contains("attachment") {
            print("  ✅ Detectado como TEXTO por patrón de URL")
            return .text
        }
        
        print("  ❌ Detectado como OTRO")
        return .other
    }

    private var resolvedURL: URL? {
        // Usar la URL pre-firmada si está disponible, sino la original
        return presignedUrl ?? URL(string: url)
    }
    
    private func isStreamingVideoURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString.lowercased()
        
        print("🔍 DEBUG - Verificando si es streaming video:")
        print("  URL: \(urlString)")
        
        let isYouTube = urlString.contains("youtube.com") || urlString.contains("youtu.be")
        let isVimeo = urlString.contains("vimeo.com")
        let isOther = urlString.contains("dailymotion.com") ||
                      urlString.contains("twitch.tv") ||
                      urlString.contains("facebook.com/watch") ||
                      urlString.contains("instagram.com/p/") ||
                      urlString.contains("tiktok.com") ||
                      urlString.contains("streamable.com") ||
                      urlString.contains("gfycat.com") ||
                      urlString.contains("giphy.com") ||
                      urlString.contains("imgur.com") ||
                      urlString.contains("embed") ||
                      urlString.contains("player")
        
        let isStreaming = isYouTube || isVimeo || isOther
        
        print("  Es YouTube: \(isYouTube)")
        print("  Es Vimeo: \(isVimeo)")
        print("  Es otra plataforma: \(isOther)")
        print("  Es streaming: \(isStreaming)")
        
        return isStreaming
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
                                    if isStreamingVideoURL(u) {
                                        // Para URLs de streaming (YouTube, Vimeo, etc.)
                                        VStack(spacing: 15) {
                                            // WebView para reproducir el video
                                            YouTubeWebView(url: u)
                                                .frame(minHeight: 480, maxHeight: 600)
                                                .cornerRadius(8)
                                            
                                            VStack(spacing: 8) {
                                                Text("Video de Streaming")
                                                    .font(.headline)
                                                
                                                Text("Este video está alojado en una plataforma externa")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.center)
                                                
                                                Text("Si no se reproduce, usa 'Abrir externamente'")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .padding()
                                            .background(Color(.controlBackgroundColor))
                                            .cornerRadius(10)
                                            
                                            Button("Abrir en navegador") {
                                                print("🌐 Abriendo URL en navegador: \(u)")
                                                NSWorkspace.shared.open(u)
                                            }
                                            .buttonStyle(.borderedProminent)
                                        }
                                    } else {
                                        // Para archivos de video directos (MP4, MOV, etc.)
                                        VStack(spacing: 10) {
                                            VideoPlayerView(url: u)
                                                .frame(height: 500)
                                                .cornerRadius(10)
                                            Text("🎥 Reproductor de video")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            // Botón de fallback para abrir externamente si no funciona
                                            Button("Si el video no se reproduce, haz clic aquí para abrirlo externamente") {
                                                NSWorkspace.shared.open(u)
                                            }
                                            .buttonStyle(.bordered)
                                            .font(.caption)
                                        }
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
                                    // Mostrar el documento directamente en el modal
                                    TextPreviewView(url: u)
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
                    .disabled(isStreaming) // No tiene sentido descargar URLs de streaming

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
    
    private func isExternalURL(_ urlString: String) -> Bool {
        let lower = urlString.lowercased()
        
        // Detectar URLs externas conocidas
        return lower.contains("youtube.com") || 
               lower.contains("youtu.be") ||
               lower.contains("vimeo.com") ||
               lower.contains("dailymotion.com") ||
               lower.contains("twitch.tv") ||
               lower.contains("facebook.com") ||
               lower.contains("instagram.com") ||
               lower.contains("tiktok.com") ||
               lower.contains("streamable.com") ||
               lower.contains("gfycat.com") ||
               lower.contains("giphy.com") ||
               lower.contains("imgur.com") ||
               lower.contains("google.com") ||
               lower.contains("amazon.com") ||
               lower.contains("dropbox.com") ||
               lower.contains("drive.google.com") ||
               lower.contains("onedrive.live.com") ||
               !lower.contains("s3") // Si no contiene 's3', probablemente es externa
    }
    
    private func loadPresignedUrl() {
        isLoadingPresigned = true
        
        // Verificar si es una URL externa (no de S3)
        if isExternalURL(url) {
            print("🌐 URL externa detectada, no se necesita URL pre-firmada: \(url)")
            if let directUrl = URL(string: url) {
                self.presignedUrl = directUrl
            } else {
                self.urlError = "URL inválida: \(url)"
            }
            self.isLoadingPresigned = false
            return
        }
        
        Task {@MainActor in
            do {
                print("🔑 Solicitando URL pre-firmada para: \(url)")
                let s3Service = S3Service.shared
                let signed = try await s3Service.generatePresignedUrl(for: url, expirationInSeconds: 3600)
                
                print("✅ URL pre-firmada recibida: \(signed)")
                self.presignedUrl = signed
                self.isLoadingPresigned = false
            } catch {
                print("❌ Error generando URL pre-firmada: \(error)")
                
                // Verificar si es un error de acceso específico
                let errorMessage = error.localizedDescription
                if errorMessage.contains("Access Denied") || errorMessage.contains("AccessDenied") {
                    self.urlError = "Access Denied - El archivo está en un bucket privado"
                } else if errorMessage.contains("NoSuchKey") || errorMessage.contains("NoSuchBucket") {
                    self.urlError = "Archivo no encontrado en S3"
                } else {
                    self.urlError = "Error de acceso: \(errorMessage)"
                }
                
                // Fallback a URL directa para intentar abrir externamente
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
        let urlLower = url.lowercased()
        
        // Detectar por extensión de archivo
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") {
            return "photo"
        } else if lower.hasSuffix(".pdf") {
            return "doc.richtext"
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") || lower.hasSuffix(".avi") {
            return "play.rectangle"
        }
        
        // Detectar por patrones de URL de video (para URLs externas sin extensión)
        if urlLower.contains("youtube.com") || urlLower.contains("youtu.be") || 
           urlLower.contains("vimeo.com") || urlLower.contains("dailymotion.com") ||
           urlLower.contains("twitch.tv") || urlLower.contains("facebook.com/watch") ||
           urlLower.contains("instagram.com/p/") || urlLower.contains("tiktok.com") ||
           urlLower.contains("streamable.com") || urlLower.contains("gfycat.com") ||
           urlLower.contains("giphy.com") || urlLower.contains("imgur.com") ||
           urlLower.contains("video") || urlLower.contains("watch") ||
           urlLower.contains("play") || urlLower.contains("embed") {
            return "play.rectangle"
        }
        
        return "doc"
    }

    private var fileTypeDescription: String {
        let lower = fileName.lowercased()
        let urlLower = url.lowercased()
        
        // Detectar por extensión de archivo
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") {
            return "Imagen"
        } else if lower.hasSuffix(".pdf") {
            return "PDF"
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") || lower.hasSuffix(".avi") {
            return "Archivo multimedia"
        }
        
        // Detectar por patrones de URL de video (para URLs externas sin extensión)
        if urlLower.contains("youtube.com") || urlLower.contains("youtu.be") || 
           urlLower.contains("vimeo.com") || urlLower.contains("dailymotion.com") ||
           urlLower.contains("twitch.tv") || urlLower.contains("facebook.com/watch") ||
           urlLower.contains("instagram.com/p/") || urlLower.contains("tiktok.com") ||
           urlLower.contains("streamable.com") || urlLower.contains("gfycat.com") ||
           urlLower.contains("giphy.com") || urlLower.contains("imgur.com") ||
           urlLower.contains("video") || urlLower.contains("watch") ||
           urlLower.contains("play") || urlLower.contains("embed") {
            return "Video de Streaming"
        }
        
        return "Documento"
    }

    private func downloadFile() {
        // Usar la URL resuelta (pre-firmada si está disponible)
        let urlToDownload = resolvedURL ?? URL(string: url)
        
        print("📥 Iniciando descarga:")
        print("  URL original: \(url)")
        print("  URL resuelta: \(urlToDownload?.absoluteString ?? "nil")")
        print("  fileName: \(fileName)")
        
        guard let urlObj = urlToDownload else {
            print("❌ URL inválida para descargar: \(url)")
            return
        }
        
        // Crear panel de guardado
        let savePanel = NSSavePanel()

        // Sugerir un nombre de archivo con extensión adecuada si falta
        var suggestedName = fileName
        if !suggestedName.contains(".") {
            switch kind {
            case .pdf:
                suggestedName += ".pdf"
            case .image:
                suggestedName += ".png"
            case .text:
                suggestedName += ".txt"
            case .video:
                suggestedName += ".mp4"
            case .other:
                break
            }
        }
        savePanel.nameFieldStringValue = suggestedName
        // No forzar tipos: evita que aparezca .txt por defecto cuando no aplica
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        savePanel.begin { response in
            if response == .OK, let saveURL = savePanel.url {
                // Descargar el archivo
                Task {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: urlObj)
                        try data.write(to: saveURL)
                        print("✅ Archivo descargado exitosamente: \(saveURL)")
                    } catch {
                        print("❌ Error descargando archivo: \(error)")
                    }
                }
            }
        }
    }

    private func openExternally() {
        // Usar la URL resuelta (pre-firmada si está disponible)
        let urlToOpen = resolvedURL ?? URL(string: url)
        
        print("👁 Abriendo archivo externamente:")
        print("  URL original: \(url)")
        print("  URL resuelta: \(urlToOpen?.absoluteString ?? "nil")")
        print("  fileName: \(fileName)")
        
        guard let urlObj = urlToOpen else {
            print("❌ URL inválida para abrir: \(url)")
            return
        }
        
        // Para archivos MD, intentar abrir con la aplicación predeterminada
        if fileName.lowercased().hasSuffix(".md") || fileName.lowercased().hasSuffix(".markdown") {
            // Crear un archivo temporal y abrirlo
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: urlObj)
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    try data.write(to: tempURL)
                    
                    // Abrir con la aplicación predeterminada
                    NSWorkspace.shared.open(tempURL)
                    print("✅ Archivo MD abierto con aplicación predeterminada")
                } catch {
                    print("❌ Error abriendo archivo MD: \(error)")
                    // Fallback: abrir URL directamente
                    NSWorkspace.shared.open(urlObj)
                }
            }
        } else {
            // Para otros tipos de archivo, abrir directamente
            print("🌐 Abriendo URL directamente: \(urlObj)")
            NSWorkspace.shared.open(urlObj)
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

// MARK: - YouTube WebView
struct YouTubeWebView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        // Configurar para YouTube
        // webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let urlString = url.absoluteString
        
        // Convertir URL a ID (incluye YouTube Shorts) y construir un iframe HTML
        let videoId: String? = extractYouTubeVideoId(from: urlString)
        
        if let videoId {
            let html = """
            <html>
              <head>
                <meta name=\"viewport\" content=\"initial-scale=1.0, maximum-scale=1.0\" />
                <style>body { margin:0; background:#111; } .wrap{position:fixed; inset:0;} iframe{width:100%; height:100%; border:0;}</style>
              </head>
              <body>
                <div class=\"wrap\">
                  <iframe src=\"https://www.youtube-nocookie.com/embed/\(videoId)?rel=0&modestbranding=1&playsinline=1\" allow=\"autoplay; encrypted-media; picture-in-picture\" allowfullscreen></iframe>
                </div>
              </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
            print("🎥 Cargando iframe YouTube para ID: \(videoId)")
        } else {
            // Fallback: cargar la URL tal cual
            if let u = URL(string: urlString) {
                webView.load(URLRequest(url: u))
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ YouTube WebView cargado correctamente")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Error cargando YouTube WebView: \(error)")
        }
    }
    
    private func extractYouTubeVideoId(from urlString: String) -> String? {
        // Usar URLComponents para no perder mayúsculas del ID
        guard let url = URL(string: urlString) else { return nil }
        let host = (url.host ?? "").lowercased()
        let path = url.path
        
        // Caso 1: youtube.com/watch?v=ID
        if host.contains("youtube.com"), let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let id = components.queryItems?.first(where: { $0.name == "v" })?.value, !id.isEmpty {
                return String(id.prefix(11))
            }
        }
        
        // Caso 2: youtu.be/ID
        if host.contains("youtu.be") {
            let segments = path.split(separator: "/")
            if let first = segments.first, !first.isEmpty {
                return String(first.prefix(11))
            }
        }
        
        // Caso 3: youtube.com/shorts/ID
        if host.contains("youtube.com") && path.lowercased().contains("/shorts/") {
            let segments = path.split(separator: "/")
            if let index = segments.firstIndex(where: { $0.lowercased() == "shorts" }),
               segments.indices.contains(segments.index(after: index)) {
                let id = segments[segments.index(after: index)]
                if !id.isEmpty { return String(id.prefix(11)) }
            }
        }
        
        return nil
    }
}

   // MARK: - Previsualizador de texto en modal
   struct TextPreviewView: View {
       let url: URL
       @State private var text: String = "Cargando..."

       var body: some View {
           ScrollView {
               Text(text)
                   .font(.body)
                   .padding()
                   .frame(maxWidth: .infinity, alignment: .leading)
           }
           .onAppear { loadText() }
           .frame(minWidth: 400, minHeight: 200)
       }
       private func loadText() {
           DispatchQueue.global(qos: .userInitiated).async {
               if let content = try? String(contentsOf: url, encoding: .utf8) {
                   DispatchQueue.main.async {
                       text = content
                   }
               } else {
                   DispatchQueue.main.async {
                       text = "No se pudo cargar el archivo de texto."
                   }
               }
           }
       }
   }