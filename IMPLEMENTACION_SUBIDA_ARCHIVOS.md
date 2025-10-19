# 📤 Implementación de Subida de Archivos a S3

## 📋 Estado Actual

### ✅ Fase 1: S3Service Básico (COMPLETADO)

**Archivo:** `Sources/EDFCatalogoLib/Services/S3Service.swift`

**Funcionalidades implementadas:**
- ✅ Configuración de AWS S3 desde variables de entorno
- ✅ Validación de tamaño de archivo según tipo:
  - Imágenes: máximo 20 MB
  - Documentos: máximo 50 MB
  - Multimedia: máximo 300 MB
- ✅ Generación de keys únicos para S3: `uploads/{userId}/{catalogId}/{tipo}/{timestamp}_{uuid}_{nombre}`
- ✅ Sanitización de nombres de archivo
- ✅ Detección automática de tipo de archivo por extensión
- ✅ Modo simulación cuando `USE_S3=false`
- ✅ Manejo de errores robusto con `S3Error`
- ✅ Logging detallado para debugging

**Tipos de archivo soportados:**
- **Imágenes:** JPG, JPEG, PNG, GIF, BMP, WEBP, TIFF, SVG
- **Documentos:** PDF, MD, TXT, DOC, DOCX, XLS, XLSX, PPT, PPTX, CSV, JSON, RTF
- **Multimedia:** MP4, MOV, AVI, WMV, WEBM, MKV, FLV, MP3, WAV, OGG, FLAC, M4A, AAC

**Método principal:**
```swift
public func uploadFile(
    fileUrl: URL,
    userId: String,
    catalogId: String,
    fileType: FileType
) async throws -> String
```

---

## 🔄 Fase 2: UI de Selección de Archivos (PENDIENTE)

### Archivos a modificar:
1. `Sources/EDFCatalogoLib/Views/CatalogDetailView.swift`

### Cambios necesarios:

#### 1. Agregar estado para archivos seleccionados
```swift
// En AddRowView y EditRowView
@State private var selectedImageFile: URL?
@State private var selectedDocumentFile: URL?
@State private var selectedMultimediaFile: URL?
@State private var isUploadingImage = false
@State private var isUploadingDocument = false
@State private var isUploadingMultimedia = false
```

#### 2. Crear función de selección de archivo
```swift
private func selectFile(for fileType: FileType) {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    
    // Configurar tipos permitidos según fileType
    switch fileType {
    case .image:
        panel.allowedContentTypes = [.image, .png, .jpeg, .gif, .bmp, .webP, .tiff, .svg]
    case .pdf, .document:
        panel.allowedContentTypes = [.pdf, .plainText, .rtf, .json, 
                                     UTType(filenameExtension: "md")!,
                                     UTType(filenameExtension: "doc")!,
                                     UTType(filenameExtension: "docx")!]
    case .multimedia:
        panel.allowedContentTypes = [.movie, .audio, .mpeg4Movie, .quickTimeMovie, .avi]
    }
    
    panel.begin { response in
        if response == .OK, let url = panel.url {
            // Guardar URL seleccionada
            switch fileType {
            case .image:
                selectedImageFile = url
            case .pdf, .document:
                selectedDocumentFile = url
            case .multimedia:
                selectedMultimediaFile = url
            }
        }
    }
}
```

#### 3. Modificar UI de campos de archivo
Reemplazar los `TextField` actuales por botones de selección:

```swift
// Sección de archivos
Section("Archivos (opcional)") {
    // Imagen
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text("Imagen principal")
                .font(.subheadline)
            Spacer()
            if isUploadingImage {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        
        if let imageFile = selectedImageFile {
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(.blue)
                Text(imageFile.lastPathComponent)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Button("Cambiar") {
                    selectFile(for: .image)
                }
                .buttonStyle(.borderless)
                Button("Quitar") {
                    selectedImageFile = nil
                    imageUrl = ""
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        } else if !imageUrl.isEmpty {
            // Mostrar URL existente
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.gray)
                Text(imageUrl)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Button("Cambiar") {
                    selectFile(for: .image)
                }
                .buttonStyle(.borderless)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
        } else {
            Button {
                selectFile(for: .image)
            } label: {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text("Seleccionar imagen")
                }
            }
        }
    }
    
    // Repetir para documento y multimedia...
}
```

#### 4. Función de subida al guardar
```swift
private func uploadFilesAndSave() async {
    do {
        // Subir imagen si hay una seleccionada
        if let imageFile = selectedImageFile {
            isUploadingImage = true
            imageUrl = try await S3Service.shared.uploadFile(
                fileUrl: imageFile,
                userId: authViewModel.currentUser?.id.stringValue ?? "unknown",
                catalogId: catalog.id?.stringValue ?? "unknown",
                fileType: .image
            )
            isUploadingImage = false
        }
        
        // Subir documento si hay uno seleccionado
        if let documentFile = selectedDocumentFile {
            isUploadingDocument = true
            documentUrl = try await S3Service.shared.uploadFile(
                fileUrl: documentFile,
                userId: authViewModel.currentUser?.id.stringValue ?? "unknown",
                catalogId: catalog.id?.stringValue ?? "unknown",
                fileType: .document
            )
            isUploadingDocument = false
        }
        
        // Subir multimedia si hay uno seleccionado
        if let multimediaFile = selectedMultimediaFile {
            isUploadingMultimedia = true
            multimediaUrl = try await S3Service.shared.uploadFile(
                fileUrl: multimediaFile,
                userId: authViewModel.currentUser?.id.stringValue ?? "unknown",
                catalogId: catalog.id?.stringValue ?? "unknown",
                fileType: .multimedia
            )
            isUploadingMultimedia = false
        }
        
        // Guardar la fila con las URLs
        saveRow()
        
    } catch {
        print("❌ Error al subir archivos: \(error.localizedDescription)")
        // Mostrar alerta al usuario
    }
}
```

#### 5. Modificar botón de guardar
```swift
Button("Guardar") {
    Task {
        await uploadFilesAndSave()
    }
}
.disabled(isUploadingImage || isUploadingDocument || isUploadingMultimedia)
```

---

## 🚀 Fase 3: Indicadores de Progreso Avanzados (OPCIONAL)

### Funcionalidades adicionales:
- Vista previa de imagen antes de subir
- Barra de progreso durante la subida
- Cancelación de subida en progreso
- Validación de archivo antes de subir (tamaño, tipo)
- Compresión automática de imágenes grandes

### Archivo nuevo a crear:
`Sources/EDFCatalogoLib/ViewModels/FileUploadViewModel.swift`

---

## 🧪 Testing

### Tests a realizar después de cada fase:

#### Fase 1 (S3Service):
- ✅ Compilación exitosa
- ✅ Validación de tamaño de archivo
- ✅ Generación de keys únicos
- ✅ Modo simulación funciona

#### Fase 2 (UI):
- [ ] Selector de archivo se abre correctamente
- [ ] Archivo seleccionado se muestra en UI
- [ ] Subida de archivo funciona (simulada)
- [ ] URLs se guardan en MongoDB
- [ ] Archivos se muestran en vista de detalle

#### Fase 3 (Avanzado):
- [ ] Vista previa de imagen funciona
- [ ] Barra de progreso se actualiza
- [ ] Cancelación funciona
- [ ] Validación previa funciona

---

## 📝 Notas de Implementación

### Dependencias necesarias:
- ✅ `AWSS3` - Ya agregado en Package.swift
- ⚠️ Implementación real de AWS SDK pendiente (actualmente simulado)

### Variables de entorno requeridas:
```bash
AWS_ACCESS_KEY_ID=tu_access_key
AWS_SECRET_ACCESS_KEY=tu_secret_key
AWS_REGION=eu-central-1
S3_BUCKET_NAME=edf-catalogo-tablas
USE_S3=true  # false para modo simulación
```

### Estructura de carpetas en S3:
```
uploads/
  └── {userId}/
      └── {catalogId}/
          ├── images/
          │   └── {timestamp}_{uuid}_{nombre}.jpg
          ├── documents/
          │   └── {timestamp}_{uuid}_{nombre}.pdf
          └── multimedia/
              └── {timestamp}_{uuid}_{nombre}.mp4
```

---

## 🔐 Seguridad

### Consideraciones:
1. **Validación de tipo de archivo:** Se valida por extensión y MIME type
2. **Límites de tamaño:** Configurados por tipo de archivo
3. **Nombres sanitizados:** Se eliminan caracteres especiales
4. **Keys únicos:** Timestamp + UUID para evitar colisiones
5. **Permisos S3:** Configurar bucket con permisos apropiados

### Permisos S3 recomendados:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::edf-catalogo-tablas/uploads/*"
    }
  ]
}
```

---

## 📊 Estado de Implementación

- ✅ **Fase 1:** S3Service básico - COMPLETADO
- ⏳ **Fase 2:** UI de selección - PENDIENTE
- ⏳ **Fase 3:** Indicadores avanzados - PENDIENTE

**Última actualización:** 19 de Octubre de 2025
