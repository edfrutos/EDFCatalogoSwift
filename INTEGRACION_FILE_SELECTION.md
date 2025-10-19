# 📝 Guía de Integración: Componentes de Selección de Archivos

## 🎯 Objetivo

Integrar los componentes de `FileSelectionComponents.swift` en `CatalogDetailView.swift` para permitir la selección y subida de archivos locales a S3.

---

## 📦 Componentes Disponibles

### 1. `FileSelectionRow`
Componente UI que muestra el estado de selección de archivo con tres estados:
- **Sin archivo:** Botón "Seleccionar archivo"
- **Archivo seleccionado:** Muestra nombre con botones "Cambiar" y "Quitar"
- **URL existente:** Muestra URL con botón "Cambiar"

### 2. `FileSelectorModifier`
Extensión que abre NSOpenPanel con validación de tamaño automática.

---

## 🔧 Pasos de Integración

### Paso 1: Importar en CatalogDetailView.swift

El archivo `FileSelectionComponents.swift` ya está en el mismo módulo, por lo que no necesita import adicional.

### Paso 2: Modificar `AddRowView`

#### 2.1. Agregar estados para archivos seleccionados

Buscar la línea donde se declaran los `@State` en `AddRowView` y agregar:

```swift
// Estados para archivos seleccionados
@State private var selectedImageFile: URL?
@State private var selectedDocumentFile: URL?
@State private var selectedMultimediaFile: URL?

// Estados de subida
@State private var isUploadingImage = false
@State private var isUploadingDocument = false
@State private var isUploadingMultimedia = false
@State private var uploadError: String?
```

#### 2.2. Agregar computed property para estado de subida

```swift
private var isUploading: Bool {
    isUploadingImage || isUploadingDocument || isUploadingMultimedia
}
```

#### 2.3. Reemplazar TextFields de archivos con FileSelectionRow

Buscar la sección `Section(header: Text("Archivos (opcional)"))` y reemplazar los `TextField` con:

```swift
Section(header: Text("Archivos (opcional)")) {
    // Imagen
    FileSelectionRow(
        title: "Imagen principal",
        selectedFile: $selectedImageFile,
        existingUrl: $imageUrl,
        isUploading: isUploadingImage,
        fileType: .image,
        onSelect: { selectFile(for: .image) }
    )
    
    // Documento
    FileSelectionRow(
        title: "Documento principal",
        selectedFile: $selectedDocumentFile,
        existingUrl: $documentUrl,
        isUploading: isUploadingDocument,
        fileType: .document,
        onSelect: { selectFile(for: .document) }
    )
    
    // Multimedia
    FileSelectionRow(
        title: "Multimedia principal",
        selectedFile: $selectedMultimediaFile,
        existingUrl: $multimediaUrl,
        isUploading: isUploadingMultimedia,
        fileType: .multimedia,
        onSelect: { selectFile(for: .multimedia) }
    )
}

if let uploadError = uploadError {
    Section {
        Text("❌ Error: \(uploadError)")
            .foregroundColor(.red)
            .font(.caption)
    }
}
```

#### 2.4. Agregar función de selección de archivo

Agregar después del `body`:

```swift
// MARK: - Selección de archivos

private func selectFile(for fileType: FileType) {
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
                    uploadError = "El archivo es demasiado grande (\(formatter.string(fromByteCount: Int64(fileSize)))). Máximo: \(formatter.string(fromByteCount: Int64(maxSize)))"
                    return
                }
            }
            
            // Guardar URL seleccionada
            switch fileType {
            case .image:
                selectedImageFile = url
                uploadError = nil
            case .pdf, .document:
                selectedDocumentFile = url
                uploadError = nil
            case .multimedia:
                selectedMultimediaFile = url
                uploadError = nil
            }
        }
    }
}
```

#### 2.5. Agregar función de subida de archivos

```swift
// MARK: - Subida de archivos

private func uploadFilesAndSave() async {
    uploadError = nil
    
    do {
        let userId = authViewModel.currentUser?.id.hex ?? "unknown"
        let catalogId = "temp-catalog-id" // TODO: Obtener ID real del catálogo
        
        // Subir imagen si hay una seleccionada
        if let imageFile = selectedImageFile {
            isUploadingImage = true
            imageUrl = try await S3Service.shared.uploadFile(
                fileUrl: imageFile,
                userId: userId,
                catalogId: catalogId,
                fileType: .image
            )
            isUploadingImage = false
        }
        
        // Subir documento si hay uno seleccionado
        if let documentFile = selectedDocumentFile {
            isUploadingDocument = true
            documentUrl = try await S3Service.shared.uploadFile(
                fileUrl: documentFile,
                userId: userId,
                catalogId: catalogId,
                fileType: .document
            )
            isUploadingDocument = false
        }
        
        // Subir multimedia si hay uno seleccionado
        if let multimediaFile = selectedMultimediaFile {
            isUploadingMultimedia = true
            multimediaUrl = try await S3Service.shared.uploadFile(
                fileUrl: multimediaFile,
                userId: userId,
                catalogId: catalogId,
                fileType: .multimedia
            )
            isUploadingMultimedia = false
        }
        
        // Guardar la fila con las URLs
        if hasRequiredData {
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
        } else {
            showValidationError = true
        }
        
    } catch {
        uploadError = error.localizedDescription
        isUploadingImage = false
        isUploadingDocument = false
        isUploadingMultimedia = false
    }
}
```

#### 2.6. Modificar botón de guardar

Reemplazar el botón "Guardar" actual con:

```swift
Button("Guardar") {
    Task {
        await uploadFilesAndSave()
    }
}
.buttonStyle(.borderedProminent)
.disabled(isUploading || !hasRequiredData)
```

#### 2.7. Deshabilitar campos durante subida

Agregar `.disabled(isUploading)` a todos los `TextField` de datos.

#### 2.8. Agregar @EnvironmentObject

Al inicio de `AddRowView`, agregar:

```swift
@EnvironmentObject private var authViewModel: AuthViewModel
```

---

### Paso 3: Modificar `EditRowView`

Repetir los mismos pasos que en `AddRowView`, con las siguientes diferencias:

1. Los estados de URL ya existen, solo agregar los estados de archivo seleccionado
2. La función `uploadFilesAndSave()` no necesita validar `hasRequiredData`
3. Usar el mismo patrón de UI y funciones

---

## 🧪 Testing

Después de la integración, probar:

1. **Test 26:** Seleccionar y subir archivo de cada tipo
2. **Test 27:** Verificar que los archivos se muestran correctamente
3. **Test 28:** Descargar/abrir archivos
4. **Test 29:** Editar y eliminar referencias de archivos

---

## ⚠️ Notas Importantes

1. **Tamaño del archivo:** CatalogDetailView.swift tiene >900 líneas. Considera refactorizar en archivos más pequeños.

2. **ID del catálogo:** Actualmente usa "temp-catalog-id". Necesitas pasar el ID real del catálogo a AddRowView/EditRowView.

3. **AuthViewModel:** Asegúrate de que esté disponible como `@EnvironmentObject` en la jerarquía de vistas.

4. **Imports necesarios:** Asegúrate de tener:
   ```swift
   import UniformTypeIdentifiers
   ```

5. **Compilación incremental:** Después de cada cambio, compila para verificar que no hay errores.

---

## 📝 Checklist de Integración

- [ ] Agregar estados para archivos seleccionados en AddRowView
- [ ] Reemplazar TextFields con FileSelectionRow en AddRowView
- [ ] Agregar función selectFile() en AddRowView
- [ ] Agregar función uploadFilesAndSave() en AddRowView
- [ ] Modificar botón de guardar en AddRowView
- [ ] Agregar @EnvironmentObject en AddRowView
- [ ] Repetir pasos para EditRowView
- [ ] Compilar y verificar sin errores
- [ ] Realizar tests 26-29

---

**Última actualización:** 19 de Octubre de 2025  
**Estado:** Componentes creados y compilando ✅  
**Próximo paso:** Integración en CatalogDetailView.swift
