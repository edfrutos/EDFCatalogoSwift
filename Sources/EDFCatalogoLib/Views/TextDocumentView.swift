import SwiftUI
import AppKit

struct TextDocumentView: View {
    let url: URL
    let fileName: String
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = TextDocumentViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let fileType = viewModel.fileType {
                        Text(fileType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Cargando documento...")
                    Spacer()
                }
            } else if let error = viewModel.error {
                VStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error al cargar el documento")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else if viewModel.isMarkdown {
                // Markdown renderizado
                ScrollView {
                    MarkdownTextView(attributedString: viewModel.attributedContent)
                        .padding()
                }
            } else {
                // Texto plano
                ScrollView {
                    Text(viewModel.content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            
            Divider()
            
            // Controls Bar
            HStack(spacing: 16) {
                Text("\(viewModel.wordCount) palabras • \(viewModel.lineCount) líneas")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Acciones
                HStack(spacing: 8) {
                    Button {
                        viewModel.copyToClipboard()
                    } label: {
                        Label("Copiar", systemImage: "doc.on.doc")
                    }
                    
                    Button {
                        viewModel.export()
                    } label: {
                        Label("Exportar", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            viewModel.loadDocument(from: url)
        }
    }
}

// MARK: - ViewModel

@MainActor
class TextDocumentViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var attributedContent: NSAttributedString = NSAttributedString()
    @Published var isLoading: Bool = true
    @Published var error: String?
    @Published var fileType: String?
    @Published var isMarkdown: Bool = false
    @Published var wordCount: Int = 0
    @Published var lineCount: Int = 0
    
    private var currentURL: URL?
    
    func loadDocument(from url: URL) {
        isLoading = true
        error = nil
        currentURL = url
        
        let ext = url.pathExtension.lowercased()
        fileType = fileTypeDescription(for: ext)
        isMarkdown = ext == "md" || ext == "markdown"
        
        Task {
            do {
                let data = try Data(contentsOf: url)
                
                if ext == "rtf" || ext == "rtfd" {
                    // RTF
                    if let attrString = NSAttributedString(rtf: data, documentAttributes: nil) {
                        content = attrString.string
                        attributedContent = attrString
                    }
                } else if ext == "html" || ext == "htm" {
                    // HTML
                    if let attrString = NSAttributedString(html: data, documentAttributes: nil) {
                        content = attrString.string
                        attributedContent = attrString
                    }
                } else {
                    // Texto plano, JSON, Markdown, etc
                    if let text = String(data: data, encoding: .utf8) {
                        content = text
                        if isMarkdown {
                            attributedContent = renderMarkdown(text)
                        }
                    } else if let text = String(data: data, encoding: .isoLatin1) {
                        content = text
                    } else {
                        throw NSError(domain: "TextDocument", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo decodificar el archivo"])
                    }
                }
                
                // Calcular estadísticas
                calculateStats()
                
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func fileTypeDescription(for ext: String) -> String {
        switch ext {
        case "txt": return "Texto plano"
        case "md", "markdown": return "Markdown"
        case "rtf": return "Rich Text Format"
        case "json": return "JSON"
        case "xml": return "XML"
        case "html", "htm": return "HTML"
        case "csv": return "CSV"
        default: return "Documento de texto"
        }
    }
    
    private func renderMarkdown(_ markdown: String) -> NSAttributedString {
        // Renderizado básico de Markdown
        let mutableAttr = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: .newlines)
        
        for line in lines {
            var attributedLine = NSMutableAttributedString(string: line + "\n")
            
            // Headers
            if line.hasPrefix("# ") {
                attributedLine = NSMutableAttributedString(string: String(line.dropFirst(2)) + "\n")
                attributedLine.addAttribute(.font, value: NSFont.systemFont(ofSize: 24, weight: .bold), range: NSRange(location: 0, length: attributedLine.length))
            } else if line.hasPrefix("## ") {
                attributedLine = NSMutableAttributedString(string: String(line.dropFirst(3)) + "\n")
                attributedLine.addAttribute(.font, value: NSFont.systemFont(ofSize: 20, weight: .bold), range: NSRange(location: 0, length: attributedLine.length))
            } else if line.hasPrefix("### ") {
                attributedLine = NSMutableAttributedString(string: String(line.dropFirst(4)) + "\n")
                attributedLine.addAttribute(.font, value: NSFont.systemFont(ofSize: 16, weight: .bold), range: NSRange(location: 0, length: attributedLine.length))
            }
            // Bold
            else if line.contains("**") {
                let parts = line.components(separatedBy: "**")
                attributedLine = NSMutableAttributedString()
                for (index, part) in parts.enumerated() {
                    let attr = NSMutableAttributedString(string: part)
                    if index % 2 == 1 {
                        attr.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize), range: NSRange(location: 0, length: attr.length))
                    }
                    attributedLine.append(attr)
                }
                attributedLine.append(NSAttributedString(string: "\n"))
            }
            // Code
            else if line.hasPrefix("```") || line.hasPrefix("    ") {
                attributedLine.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular), range: NSRange(location: 0, length: attributedLine.length))
                attributedLine.addAttribute(.backgroundColor, value: NSColor.lightGray.withAlphaComponent(0.1), range: NSRange(location: 0, length: attributedLine.length))
            }
            
            mutableAttr.append(attributedLine)
        }
        
        return mutableAttr
    }
    
    private func calculateStats() {
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        wordCount = words.count
        lineCount = content.components(separatedBy: .newlines).count
    }
    
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
    
    func export() {
        guard let url = currentURL else { return }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = url.lastPathComponent
        savePanel.allowedContentTypes = [.plainText]
        
        savePanel.begin { response in
            if response == .OK, let saveURL = savePanel.url {
                try? self.content.write(to: saveURL, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: - Markdown Text View

struct MarkdownTextView: NSViewRepresentable {
    let attributedString: NSAttributedString
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = CGSize(width: 0, height: 0)
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.attributedString() != attributedString {
            nsView.textStorage?.setAttributedString(attributedString)
        }
    }
}
