import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let url: URL
    let fileName: String
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = PDFViewerViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(fileName)
                    .font(.headline)
                    .lineLimit(1)
                
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
            
            // PDF Viewer
            PDFKitViewWithControls(url: url, viewModel: viewModel)
            
            Divider()
            
            // Controls Bar
            HStack(spacing: 16) {
                // Navegación
                HStack(spacing: 8) {
                    Button {
                        viewModel.previousPage()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(viewModel.currentPage <= 1)
                    
                    Text("Página \(viewModel.currentPage) de \(viewModel.totalPages)")
                        .font(.caption)
                        .frame(width: 120)
                    
                    Button {
                        viewModel.nextPage()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(viewModel.currentPage >= viewModel.totalPages)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Zoom
                HStack(spacing: 8) {
                    Button {
                        viewModel.zoomOut()
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    
                    Text("\(Int(viewModel.zoomLevel * 100))%")
                        .font(.caption)
                        .frame(width: 50)
                    
                    Button {
                        viewModel.zoomIn()
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    
                    Button {
                        viewModel.resetZoom()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .help("Restablecer zoom")
                }
                
                Divider()
                    .frame(height: 20)
                
                Spacer()
                
                // Acciones
                HStack(spacing: 8) {
                    Button {
                        viewModel.exportPDF()
                    } label: {
                        Label("Exportar", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        viewModel.printPDF()
                    } label: {
                        Label("Imprimir", systemImage: "printer")
                    }
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - ViewModel

@MainActor
class PDFViewerViewModel: ObservableObject {
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 0
    @Published var zoomLevel: CGFloat = 1.0
    
    weak var pdfView: PDFView?
    
    func nextPage() {
        pdfView?.goToNextPage(nil)
        updatePageNumber()
    }
    
    func previousPage() {
        pdfView?.goToPreviousPage(nil)
        updatePageNumber()
    }
    
    func zoomIn() {
        if zoomLevel < 3.0 {
            zoomLevel += 0.25
            pdfView?.scaleFactor = zoomLevel
        }
    }
    
    func zoomOut() {
        if zoomLevel > 0.5 {
            zoomLevel -= 0.25
            pdfView?.scaleFactor = zoomLevel
        }
    }
    
    func resetZoom() {
        zoomLevel = 1.0
        pdfView?.scaleFactor = zoomLevel
    }
    
    func updatePageNumber() {
        if let pdfView = pdfView, let currentPage = pdfView.currentPage {
            self.currentPage = (pdfView.document?.index(for: currentPage) ?? 0) + 1
        }
    }
    
    func exportPDF() {
        guard let pdfView = pdfView, let document = pdfView.document else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "documento_exportado.pdf"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                document.write(to: url)
            }
        }
    }
    
    func printPDF() {
        guard let pdfView = pdfView, let document = pdfView.document else { return }
        
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        
        let printOperation = document.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true)
        printOperation?.run()
    }
}

// MARK: - PDFKit View with Controls

struct PDFKitViewWithControls: NSViewRepresentable {
    let url: URL
    @ObservedObject var viewModel: PDFViewerViewModel
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = NSColor.windowBackgroundColor
        
        // Habilitar selección y búsqueda
        pdfView.displaysPageBreaks = true
        pdfView.displayBox = .mediaBox
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            DispatchQueue.main.async {
                viewModel.totalPages = document.pageCount
                viewModel.currentPage = 1
                viewModel.pdfView = pdfView
            }
        }
        
        // Notificación de cambio de página
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            viewModel.updatePageNumber()
        }
        
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document == nil || nsView.document?.documentURL != url {
            if let document = PDFDocument(url: url) {
                nsView.document = document
                DispatchQueue.main.async {
                    viewModel.totalPages = document.pageCount
                    viewModel.currentPage = 1
                }
            }
        }
    }
}
