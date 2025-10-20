# 🧪 Guía de Testing Manual - AddRowView

**Fecha:** 19 de Octubre de 2025  
**Componente:** AddRowView - Integración de selección de archivos  
**Estado:** Listo para testing

---

## ✅ Pre-requisitos

1. ✅ Aplicación compilada exitosamente
2. ✅ Aplicación ejecutándose (./run_app.sh)
3. ✅ Usuario autenticado (admin@edf.com)
4. ✅ Catálogos cargados (6 catálogos disponibles)

---

## 📋 Plan de Testing

### Test 1: Abrir Formulario de Agregar Fila

**Pasos:**
1. En la aplicación, selecciona cualquier catálogo de la lista
2. Haz clic en el botón "+" o "Agregar fila"
3. Verifica que se abre el formulario AddRowView

**Resultado esperado:**
- ✅ El formulario se abre correctamente
- ✅ Se muestran los campos de texto para las columnas del catálogo
- ✅ Se muestra la sección "Archivos (opcional)"
- ✅ Se muestran tres componentes FileSelectionRow:
  - "Imagen principal"
  - "Documento principal"
  - "Multimedia principal"

---

### Test 2: Selección de Archivo - Imagen

**Pasos:**
1. En el formulario AddRowView, localiza "Imagen principal"
2. Haz clic en el botón "Seleccionar archivo"
3. Verifica que se abre NSOpenPanel (selector de archivos de macOS)
4. Verifica el mensaje: "Selecciona una imagen (máx. 20MB)"
5. Intenta seleccionar un archivo que NO sea imagen (ej: .txt)
6. Verifica que el archivo no se puede seleccionar (filtro activo)
7. Selecciona una imagen válida (ej: .jpg, .png)
8. Verifica el tamaño del archivo

**Resultado esperado:**
- ✅ NSOpenPanel se abre correctamente
- ✅ Solo se pueden seleccionar archivos de imagen (.png, .jpeg, .gif, .bmp, .tiff, .heic)
- ✅ Si el archivo es menor a 20MB:
  - El nombre del archivo se muestra en la UI
  - El icono cambia a ✅
  - No hay mensaje de error
- ✅ Si el archivo es mayor a 20MB:
  - Se muestra mensaje de error: "El archivo excede el tamaño máximo permitido"
  - El archivo no se selecciona

---

### Test 3: Selección de Archivo - Documento

**Pasos:**
1. En el formulario AddRowView, localiza "Documento principal"
2. Haz clic en el botón "Seleccionar archivo"
3. Verifica que se abre NSOpenPanel
4. Verifica el mensaje: "Selecciona un documento (máx. 50MB)"
5. Selecciona un documento válido (ej: .txt, .doc, .docx, .xls, .xlsx)
6. Verifica el tamaño del archivo

**Resultado esperado:**
- ✅ NSOpenPanel se abre correctamente
- ✅ Solo se pueden seleccionar documentos (.txt, .rtf, .html, .doc, .docx, .xls, .xlsx)
- ✅ Si el archivo es menor a 50MB:
  - El nombre del archivo se muestra en la UI
  - El icono cambia a ✅
  - No hay mensaje de error
- ✅ Si el archivo es mayor a 50MB:
  - Se muestra mensaje de error
  - El archivo no se selecciona

---

### Test 4: Selección de Archivo - PDF

**Pasos:**
1. En el formulario AddRowView, localiza "Documento principal"
2. Haz clic en el botón "Seleccionar archivo"
3. Selecciona un archivo PDF
4. Verifica que se acepta correctamente

**Resultado esperado:**
- ✅ Los archivos PDF se pueden seleccionar
- ✅ Límite de tamaño: 50MB
- ✅ El archivo se muestra correctamente en la UI

---

### Test 5: Selección de Archivo - Multimedia

**Pasos:**
1. En el formulario AddRowView, localiza "Multimedia principal"
2. Haz clic en el botón "Seleccionar archivo"
3. Verifica que se abre NSOpenPanel
4. Verifica el mensaje: "Selecciona un archivo multimedia (máx. 300MB)"
5. Selecciona un archivo multimedia válido (ej: .mp4, .mov, .mp3, .wav)
6. Verifica el tamaño del archivo

**Resultado esperado:**
- ✅ NSOpenPanel se abre correctamente
- ✅ Solo se pueden seleccionar archivos multimedia (.mp4, .mov, .avi, .mp3, .wav, etc.)
- ✅ Si el archivo es menor a 300MB:
  - El nombre del archivo se muestra en la UI
  - El icono cambia a ✅
  - No hay mensaje de error
- ✅ Si el archivo es mayor a 300MB:
  - Se muestra mensaje de error
  - El archivo no se selecciona

---

### Test 6: Múltiples Archivos Seleccionados

**Pasos:**
1. Selecciona una imagen válida
2. Selecciona un documento válido
3. Selecciona un archivo multimedia válido
4. Verifica que los tres archivos se muestran correctamente en la UI

**Resultado esperado:**
- ✅ Los tres archivos se muestran simultáneamente
- ✅ Cada uno muestra su nombre correcto
- ✅ Cada uno tiene el icono ✅
- ✅ No hay conflictos entre selecciones

---

### Test 7: Deshabilitar Campos Durante Subida

**Pasos:**
1. Selecciona al menos un archivo
2. Rellena los campos obligatorios del formulario
3. Haz clic en "Guardar"
4. Observa el comportamiento de la UI durante la subida

**Resultado esperado:**
- ✅ Los TextFields se deshabilitan (no se pueden editar)
- ✅ El botón "Guardar" se deshabilita
- ✅ El botón "Cancelar" se deshabilita
- ✅ Se muestra un indicador de progreso (spinner o similar)
- ✅ El texto del botón cambia o muestra estado de carga

---

### Test 8: Subida de Archivos (Modo Simulación)

**Pasos:**
1. Selecciona una imagen pequeña (< 1MB)
2. Rellena los campos obligatorios
3. Haz clic en "Guardar"
4. Observa los logs en la terminal

**Resultado esperado en terminal:**
```
🔐 Obteniendo usuario actual para subida de archivos
👤 Usuario ID: 68ebf41a46319328197880fb
📤 Iniciando subida de imagen...
🔧 Modo simulación: Generando URL simulada
✅ Archivo subido exitosamente (simulado)
📝 URL generada: https://s3.amazonaws.com/edf-catalogo/catalogs/{catalogId}/images/{timestamp}_{filename}
💾 Guardando fila en MongoDB...
✅ Fila guardada exitosamente
```

**Resultado esperado en UI:**
- ✅ El formulario se cierra
- ✅ La nueva fila aparece en la tabla del catálogo
- ✅ La URL del archivo se guarda correctamente en MongoDB

---

### Test 9: Manejo de Errores - Usuario No Autenticado

**Pasos:**
1. (Este test requiere modificar temporalmente el código o cerrar sesión)
2. Intenta guardar una fila con archivos sin estar autenticado

**Resultado esperado:**
- ✅ Se muestra mensaje de error: "Error: Usuario no autenticado"
- ✅ El formulario no se cierra
- ✅ Los archivos no se suben
- ✅ No se guarda nada en MongoDB

---

### Test 10: Manejo de Errores - Fallo en Subida

**Pasos:**
1. (Este test requiere simular un fallo en S3Service)
2. Selecciona un archivo
3. Intenta guardar

**Resultado esperado:**
- ✅ Se muestra mensaje de error específico
- ✅ El formulario no se cierra
- ✅ Los campos se vuelven a habilitar
- ✅ El usuario puede reintentar

---

### Test 11: Validación de Campos Obligatorios

**Pasos:**
1. Selecciona archivos pero NO rellenes los campos obligatorios
2. Intenta hacer clic en "Guardar"

**Resultado esperado:**
- ✅ El botón "Guardar" está deshabilitado
- ✅ No se puede guardar sin completar campos obligatorios
- ✅ Los archivos seleccionados se mantienen

---

### Test 12: Cancelar Formulario

**Pasos:**
1. Selecciona algunos archivos
2. Rellena algunos campos
3. Haz clic en "Cancelar"

**Resultado esperado:**
- ✅ El formulario se cierra
- ✅ No se guarda nada en MongoDB
- ✅ Los archivos seleccionados se descartan
- ✅ No hay efectos secundarios

---

### Test 13: Visualización de Archivos en Detalle

**Pasos:**
1. Después de guardar una fila con archivos
2. Selecciona la fila en la tabla
3. Verifica que se muestran los archivos en la vista de detalle

**Resultado esperado:**
- ✅ Las URLs de los archivos se muestran correctamente
- ✅ Se pueden hacer clic en las URLs (si hay funcionalidad de visualización)
- ✅ Los iconos de tipo de archivo son correctos

---

## 📊 Checklist de Resultados

Marca cada test completado:

- [ ] Test 1: Abrir formulario
- [ ] Test 2: Selección de imagen
- [ ] Test 3: Selección de documento
- [ ] Test 4: Selección de PDF
- [ ] Test 5: Selección de multimedia
- [ ] Test 6: Múltiples archivos
- [ ] Test 7: Deshabilitar campos
- [ ] Test 8: Subida de archivos
- [ ] Test 9: Error de autenticación
- [ ] Test 10: Error de subida
- [ ] Test 11: Validación de campos
- [ ] Test 12: Cancelar formulario
- [ ] Test 13: Visualización en detalle

---

## 🐛 Registro de Bugs Encontrados

Si encuentras algún problema, regístralo aquí:

### Bug #1
**Descripción:**  
**Pasos para reproducir:**  
**Resultado esperado:**  
**Resultado actual:**  
**Severidad:** (Crítico/Alto/Medio/Bajo)

---

## 📝 Notas Adicionales

- La aplicación está en modo simulación para S3, las URLs generadas son ficticias
- Los archivos NO se suben realmente a AWS S3 en este momento
- Las URLs se guardan en MongoDB correctamente
- Para testing real de S3, necesitas configurar las credenciales de AWS

---

## ✅ Criterios de Aceptación

Para considerar el testing exitoso, TODOS estos criterios deben cumplirse:

1. ✅ El formulario se abre correctamente
2. ✅ Los tres selectores de archivo funcionan
3. ✅ La validación de tamaño funciona para cada tipo
4. ✅ Los filtros de tipo de archivo funcionan
5. ✅ Los archivos seleccionados se muestran en la UI
6. ✅ Los campos se deshabilitan durante la subida
7. ✅ La subida simulada funciona correctamente
8. ✅ Las URLs se guardan en MongoDB
9. ✅ El manejo de errores funciona
10. ✅ La validación de campos obligatorios funciona
11. ✅ El botón cancelar funciona
12. ✅ Los archivos se visualizan en la vista de detalle

---

**Tiempo estimado de testing:** 30-45 minutos  
**Tester:** [Tu nombre]  
**Fecha de testing:** [Fecha]  
**Resultado final:** [ ] APROBADO / [ ] RECHAZADO
