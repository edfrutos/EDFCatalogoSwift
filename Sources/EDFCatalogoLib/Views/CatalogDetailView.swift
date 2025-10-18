import SwiftUI
import PDFKit
import AVKit
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

    public init(catalog: Catalog) {
        self.catalog = catalog
        loadRows()
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
        let newRow = CatalogRow(
            _id: BSONObjectID(),
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

        rows[index] = updatedRow
        persistCatalogChanges()
    }

    public func deleteRow(at index: Int) {
        guard index >= 0 && index < rows.count else { return }
        rows.remove(at: index)
        persistCatalogChanges()
    }

    private func persistCatalogChanges() {
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
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: CatalogDetailViewModel
    @State private var selectedRowIndex: Int?
    @State private var showingFileViewer = false
    @State private var selectedFileUrl: String = ""
    @State private var selectedFileName: String = ""

    public init(catalog: Catalog) {
        _viewModel = StateObject(wrappedValue: CatalogDetailViewModel(catalog: catalog))
    }

    public var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left").imageScale(.large)
                }

                Text(viewModel.catalog.name)
                    .font(.largeTitle).fontWeight(.bold)

                Spacer()

                Button(viewModel.isEditing ? "Terminar edición" : "Editar") {
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.rows.indices, id: \.self) { index in
                            CatalogRowView(
                                row: viewModel.rows[index],
                                columns: viewModel.catalog.columns,
                                isEditing: viewModel.isEditing,
                                onEdit: { viewModel.updateRow(at: index, data: $0, files: $1) },
                                onDelete: { viewModel.deleteRow(at: index) },
                                onFileSelected: { url, name in
                                    selectedFileUrl = url
                                    selectedFileName = name
                                    showingFileViewer = true
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
        .sheet(isPresented: $viewModel.showingAddRowSheet) {
            AddRowView(columns: viewModel.catalog.columns) { data, files in
                viewModel.addRow(data: data, files: files)
            }
        }
        .sheet(isPresented: $showingFileViewer) {
            FileViewerView(
                url: selectedFileUrl.isEmpty ? "URL no disponible" : selectedFileUrl,
                fileName: selectedFileName.isEmpty ? "Archivo no disponible" : selectedFileName
            )
        }
    }
}

// MARK: - Fila

struct CatalogRowView: View {
    let row: CatalogRow
    let columns: [String]
    let isEditing: Bool
    let onEdit: ([String: String], RowFiles) -> Void
    let onDelete: () -> Void
    let onFileSelected: (String, String) -> Void

    @State private var editedData: [String: String] = [:]
    @State private var showingEditSheet = false
    @State private var isExpanded = false

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
                        Text("Fila \(row.id.prefix(8))")
                            .font(.headline)
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
                            editedData = row.data
                            showingEditSheet = true
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
                                    onFileSelected(image, "Imagen principal")
                                }
                            }

                            if let document = row.files.document {
                                FileItemView(url: document, type: "Documento principal") {
                                    onFileSelected(document, "Documento principal")
                                }
                            }

                            if let multimedia = row.files.multimedia {
                                FileItemView(url: multimedia, type: "Multimedia principal") {
                                    onFileSelected(multimedia, "Multimedia principal")
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
        .sheet(isPresented: $showingEditSheet) {
            EditRowView(
                data: editedData,
                files: row.files,
                columns: columns
            ) { updatedData, updatedFiles in
                onEdit(updatedData, updatedFiles)
            }
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
    let columns: [String]
    let onSave: ([String: String], RowFiles) -> Void

    @State private var data: [String: String] = [:]
    @State private var imageUrl: String = ""
    @State private var documentUrl: String = ""
    @State private var multimediaUrl: String = ""

    init(columns: [String], onSave: @escaping ([String: String], RowFiles) -> Void) {
        self.columns = columns
        self.onSave = onSave

        var initialData: [String: String] = [:]
        for column in columns { initialData[column] = "" }
        _data = State(initialValue: initialData)
    }

    var body: some View {
        VStack {
            HStack {
                Text("Añadir Nueva Fila").font(.headline)
                Spacer()
                Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.plain)
            }
            .padding()

            Form {
                Section(header: Text("Datos")) {
                    ForEach(columns, id: \.self) { column in
                        TextField(column, text: Binding(
                            get: { data[column] ?? "" },
                            set: { data[column] = $0 }
                        ))
                    }
                }

                Section(header: Text("Archivos")) {
                    TextField("URL de imagen", text: $imageUrl)
                    TextField("URL de documento", text: $documentUrl)
                    TextField("URL de multimedia", text: $multimediaUrl)
                }
            }
            .padding()

            HStack {
                Spacer()
                Button("Guardar") {
                    let files = RowFiles(
                        image: imageUrl.isEmpty ? nil : imageUrl,
                        images: [],
                        document: documentUrl.isEmpty ? nil : documentUrl,
                        documents: [],
                        multimedia: multimediaUrl.isEmpty ? nil : multimediaUrl,
                        multimediaFiles: []
                    )
                    onSave(data, files)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
}

struct EditRowView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var data: [String: String]
    @State private var imageUrl: String
    @State private var documentUrl: String
    @State private var multimediaUrl: String

    let columns: [String]
    let onSave: ([String: String], RowFiles) -> Void

    init(data: [String: String], files: RowFiles, columns: [String], onSave: @escaping ([String: String], RowFiles) -> Void) {
        _data = State(initialValue: data)
        _imageUrl = State(initialValue: files.image ?? "")
        _documentUrl = State(initialValue: files.document ?? "")
        _multimediaUrl = State(initialValue: files.multimedia ?? "")
        self.columns = columns
        self.onSave = onSave
    }

    var body: some View {
        VStack {
            HStack {
                Text("Editar Fila").font(.headline)
                Spacer()
                Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.plain)
            }
            .padding()

            Form {
                Section(header: Text("Datos")) {
                    ForEach(columns, id: \.self) { column in
                        TextField(column, text: Binding(
                            get: { data[column] ?? "" },
                            set: { data[column] = $0 }
                        ))
                    }
                }

                Section(header: Text("Archivos")) {
                    TextField("URL de imagen", text: $imageUrl)
                    TextField("URL de documento", text: $documentUrl)
                    TextField("URL de multimedia", text: $multimediaUrl)
                }
            }
            .padding()

            HStack {
                Spacer()
                Button("Guardar") {
                    let files = RowFiles(
                        image: imageUrl.isEmpty ? nil : imageUrl,
                        images: [],
                        document: documentUrl.isEmpty ? nil : documentUrl,
                        documents: [],
                        multimedia: multimediaUrl.isEmpty ? nil : multimediaUrl,
                        multimediaFiles: []
                    )
                    onSave(data, files)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - Visor de archivo (sin dependencia de FileType global)

struct FileViewerView: View {
    let url: String
    let fileName: String
    @Environment(\.presentationMode) var presentationMode

    // Deducción local del "tipo" por extensión — evita ambigüedad con FileType
    private enum LocalFileKind { case image, pdf, video, other }

    private var kind: LocalFileKind {
        let lower = fileName.lowercased()
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") {
            return .image
        } else if lower.hasSuffix(".pdf") {
            return .pdf
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") || lower.hasSuffix(".avi") {
            return .video
        } else {
            return .other
        }
    }

    private var resolvedURL: URL? {
        // Prefer presigned/absolute URL to the original string
        return URL(string: url)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Visor de Archivo")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button("Cerrar") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding()

            // Content
            VStack(spacing: 20) {
                Image(systemName: fileTypeIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)

                Text("Archivo: \(fileName)")
                    .font(.headline)

                Text("URL: \(url)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text("Tipo: \(fileTypeDescription)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Preview inline (incluye .pdf)
            Group {
                switch kind {
                case .image:
                    if let u = resolvedURL {
                        if #available(macOS 12.0, *) {
                            AsyncImage(url: u) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure:
                                    Text("No se pudo cargar la imagen.")
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(minHeight: 200)
                        } else {
                            Text("Vista previa de imagen no disponible en esta versión de macOS.")
                        }
                    } else {
                        Text("URL de imagen inválida")
                    }

                case .pdf:
                    if let u = resolvedURL {
                        PDFKitView(url: u)
                            .frame(minHeight: 300)
                    } else {
                        Text("URL de PDF inválida")
                    }

                case .video:
                    if let u = resolvedURL {
                        VideoPlayer(player: AVPlayer(url: u))
                            .frame(minHeight: 240)
                    } else {
                        Text("URL de vídeo inválida")
                    }

                case .other:
                    Text("Este tipo de archivo no tiene vista previa integrada.")
                }
            }
            .padding(.horizontal)

            // Footer
            HStack {
                Button("Descargar") { downloadFile() }
                    .buttonStyle(.bordered)

                Spacer()

                Button("Abrir externamente") { openExternally() }
                    .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
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
        Task {
            do {
                let s3Service = S3Service.shared
                let presignedUrl = try await s3Service.generatePresignedUrl(for: url)
                NSWorkspace.shared.open(presignedUrl)
            } catch {
                // Fallback a la URL original
                if let urlObj = URL(string: url) {
                    NSWorkspace.shared.open(urlObj)
                }
            }
        }
    }

    private func openExternally() {
        Task {
            do {
                let s3Service = S3Service.shared
                let presignedUrl = try await s3Service.generatePresignedUrl(for: url)
                NSWorkspace.shared.open(presignedUrl)
            } catch {
                // Fallback a la URL original
                if let urlObj = URL(string: url) {
                    NSWorkspace.shared.open(urlObj)
                }
            }
        }
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
