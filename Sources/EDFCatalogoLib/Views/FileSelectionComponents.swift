import SwiftUI
import UniformTypeIdentifiers

// MARK: - Componente de selección de archivo

struct FileSelectionRow: View {
    let title: String
    @Binding var selectedFile: URL?
    @Binding var existingUrl: String
    let isUploading: Bool
    let fileType: FileType
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                if isUploading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if let file = selectedFile {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    Text(file.lastPathComponent)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Button("Cambiar") {
                        onSelect()
                    }
                    .buttonStyle(.borderless)
                    Button("Quitar") {
                        selectedFile = nil
                        existingUrl = ""
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            } else if !existingUrl.isEmpty {
                // Mostrar URL existente
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.gray)
                    Text(existingUrl)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Button("Cambiar") {
                        onSelect()
                    }
                    .buttonStyle(.borderless)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            } else {
                Button {
                    onSelect()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Seleccionar archivo")
                    }
                }
                .disabled(isUploading)
            }
        }
    }
}

// MARK: - Extensión para selección de archivos

extension View {
    func fileSelector(
        for fileType: FileType,
        onSelect: @escaping (URL) -> Void,
        onError: @escaping (String) -> Void
    ) -> some View {
        self.modifier(FileSelectorModifier(
            fileType: fileType,
            onSelect: onSelect,
            onError: onError
        ))
    }
}

struct FileSelectorModifier: ViewModifier {
    let fileType: FileType
    let onSelect: (URL) -> Void
    let onError: (String) -> Void
    
    func body(content: Content) -> some View {
        content
    }
    
    func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        // Configurar tipos permitidos según fileType
        switch fileType {
        case .image:
            panel.allowedContentTypes = [.image, .png, .jpeg, .gif, .bmp, .webP, .tiff, .svg]
            panel.message = "Selecciona una imagen (máximo 20 MB)"
            
        case .pdf, .document:
            var docTypes: [UTType] = [.pdf, .plainText, .rtf, .json]
            if let mdType = UTType(filenameExtension: "md") {
                docTypes.append(mdType)
            }
            panel.allowedContentTypes = docTypes
            panel.message = "Selecciona un documento (máximo 50 MB)"
            
        case .multimedia:
            panel.allowedContentTypes = [.movie, .audio, .mpeg4Movie, .quickTimeMovie, .avi]
            panel.message = "Selecciona un archivo multimedia (máximo 300 MB)"
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Validar tamaño del archivo
                if let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int {
                    let maxSize: Int
                    switch fileType {
                    case .image:
                        maxSize = 20 * 1024 * 1024
                    case .pdf, .document:
                        maxSize = 50 * 1024 * 1024
                    case .multimedia:
                        maxSize = 300 * 1024 * 1024
                    }
                    
                    if fileSize > maxSize {
                        let formatter = ByteCountFormatter()
                        formatter.allowedUnits = [.useMB, .useGB]
                        formatter.countStyle = .file
                        onError("El archivo es demasiado grande (\(formatter.string(fromByteCount: Int64(fileSize)))). Máximo: \(formatter.string(fromByteCount: Int64(maxSize)))")
                        return
                    }
                }
                
                onSelect(url)
            }
        }
    }
}
