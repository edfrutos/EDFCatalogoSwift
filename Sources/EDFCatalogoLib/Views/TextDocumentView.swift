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
                    Group {
                        if let attributedString = try? AttributedString(markdown: viewModel.content) {
                            Text(attributedString)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        } else {
                            Text(viewModel.content)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                }
            } else {
                // Texto plano
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(viewModel.content)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .id("text-content")
                    }
                    .onAppear {
                        // Asegurar que el scroll esté en la parte superior
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("text-content", anchor: .top)
                            }
                        }
                    }
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
        // Usar el renderizado nativo de SwiftUI para Markdown
        do {
            let attributedString = try AttributedString(markdown: markdown)
            return NSAttributedString(attributedString)
        } catch {
            // Fallback: mostrar como texto plano si falla el renderizado
            print("⚠️ Error renderizando Markdown: \(error)")
            return NSAttributedString(string: markdown)
        }
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
        textView.textContainerInset = CGSize(width: 8, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.attributedString() != attributedString {
            nsView.textStorage?.setAttributedString(attributedString)
            // Asegurar que el scroll esté en la parte superior
            DispatchQueue.main.async {
                nsView.scrollToBeginningOfDocument(nil)
                nsView.needsDisplay = true
            }
        }
    }
}
