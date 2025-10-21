import SwiftUI
import UniformTypeIdentifiers

struct MultipleFilesSection: View {
    let title: String
    let fileType: FileType
    @Binding var urls: [String]
    @State private var newURLInput: String = ""
    @State private var showAddField: Bool = false
    let onSelectFile: () -> Void
    let isUploading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button {
                    showAddField.toggle()
                } label: {
                    Label("Añadir más", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(isUploading)
            }
            
            // Lista de URLs existentes
            if !urls.isEmpty {
                ForEach(urls.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: iconForFileType(fileType))
                            .foregroundColor(.blue)
                        
                        Text(fileNameFromURL(urls[index]))
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button {
                            urls.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // Campo para añadir nueva URL
            if showAddField {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TextField("URL externa o subir archivo...", text: $newURLInput)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            if !newURLInput.isEmpty {
                                urls.append(newURLInput)
                                newURLInput = ""
                                showAddField = false
                            }
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.borderless)
                        .disabled(newURLInput.isEmpty)
                        
                        Button {
                            newURLInput = ""
                            showAddField = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    Button {
                        onSelectFile()
                    } label: {
                        Label("O selecciona un archivo local", systemImage: "folder")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForFileType(_ type: FileType) -> String {
        switch type {
        case .image:
            return "photo"
        case .pdf, .document:
            return "doc"
        case .multimedia:
            return "play.rectangle"
        }
    }
    
    private func fileNameFromURL(_ urlString: String) -> String {
        if let url = URL(string: urlString) {
            return url.lastPathComponent
        }
        return urlString
    }
}
