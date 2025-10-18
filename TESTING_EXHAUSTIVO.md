# 🧪 Testing Exhaustivo - EDF Catálogo de Tablas

**Fecha:** 18 de Octubre de 2025  
**Versión:** 1.0.0  
**Tester:** Sistema Automatizado

---

## 📋 Índice de Pruebas

1. [Compilación y Empaquetado](#1-compilación-y-empaquetado)
2. [Carga de Variables de Entorno](#2-carga-de-variables-de-entorno)
3. [Autenticación](#3-autenticación)
4. [Gestión de Catálogos](#4-gestión-de-catálogos)
5. [Gestión de Filas](#5-gestión-de-filas)
6. [Gestión de Archivos](#6-gestión-de-archivos)
7. [Perfil de Usuario](#7-perfil-de-usuario)
8. [Administración](#8-administración)
9. [Navegación y UI](#9-navegación-y-ui)
10. [Rendimiento y Estabilidad](#10-rendimiento-y-estabilidad)

---

## 1. Compilación y Empaquetado

### ✅ Test 1.1: Compilación en Modo Release
**Estado:** PASADO  
**Descripción:** Compilar el proyecto en modo release  
**Comando:** `swift build -c release`  
**Resultado:** 
- ✅ Compilación exitosa
- ✅ Sin errores de compilación
- ⚠️ Warnings de CLibMongoC (no críticos)
- ✅ Ejecutable generado correctamente

**Tiempo de compilación:** ~65 segundos

### ✅ Test 1.2: Empaquetado de Aplicación
**Estado:** PASADO  
**Descripción:** Crear bundle .app con script build_app.sh  
**Comando:** `./build_app.sh`  
**Resultado:**
- ✅ Estructura de directorios creada
- ✅ Ejecutable copiado
- ✅ Recursos copiados
- ✅ Archivo .env copiado al bundle
- ✅ Info.plist creado
- ✅ Launcher.sh creado
- ✅ Icono de aplicación generado
- ✅ Aplicación firmada (ad-hoc)
- ✅ Atributos de cuarentena eliminados

**Ubicación:** `/Users/edefrutos/__Proyectos/EDFCatalogoSwift/bin/EDF Catálogo de Tablas.app`

### ✅ Test 1.3: Ejecución con Doble Clic
**Estado:** PASADO  
**Descripción:** Verificar que la aplicación se ejecuta con doble clic desde Finder  
**Resultado:**
- ✅ Aplicación se lanza correctamente
- ✅ Icono visible en Dock
- ✅ Proceso EDFCatalogoSwift iniciado (PID: 38480)
- ✅ Sin errores de permisos

---

## 2. Carga de Variables de Entorno

### 🔄 Test 2.1: Carga de .env desde Bundle
**Estado:** EN PROGRESO  
**Descripción:** Verificar que las variables de entorno se cargan desde el archivo .env dentro del bundle  
**Variables a verificar:**
- MONGO_URI
- MONGO_DB
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- BUCKET_NAME
- USE_S3

**Método de verificación:** Logs de la aplicación

### ⏳ Test 2.2: Conexión a MongoDB
**Estado:** PENDIENTE  
**Descripción:** Verificar conexión exitosa a MongoDB Atlas  
**Criterios:**
- Conexión establecida
- Base de datos accesible
- Sin errores de autenticación

### ⏳ Test 2.3: Conexión a AWS S3
**Estado:** PENDIENTE  
**Descripción:** Verificar conexión exitosa a AWS S3  
**Criterios:**
- Credenciales válidas
- Bucket accesible
- Permisos correctos

---

## 3. Autenticación

### ⏳ Test 3.1: Pantalla de Login Inicial
**Estado:** PENDIENTE  
**Descripción:** Verificar que la pantalla de login se muestra al iniciar  
**Elementos a verificar:**
- [ ] Campo de email visible
- [ ] Campo de contraseña visible
- [ ] Botón "Entrar" visible
- [ ] Botón deshabilitado con campos vacíos

### ⏳ Test 3.2: Login Exitoso
**Estado:** PENDIENTE  
**Credenciales de prueba:**
- Email: admin@edf.com
- Contraseña: admin123

**Pasos:**
1. Ingresar email
2. Ingresar contraseña
3. Hacer clic en "Entrar"

**Resultado esperado:**
- [ ] Autenticación exitosa
- [ ] Redirección a vista principal
- [ ] Usuario cargado en AuthViewModel
- [ ] Token guardado en Keychain

### ⏳ Test 3.3: Login Fallido - Credenciales Inválidas
**Estado:** PENDIENTE  
**Credenciales de prueba:**
- Email: test@invalid.com
- Contraseña: wrongpassword

**Resultado esperado:**
- [ ] Mensaje de error mostrado
- [ ] Usuario no autenticado
- [ ] Permanece en pantalla de login

### ⏳ Test 3.4: Validación de Campos Vacíos
**Estado:** PENDIENTE  
**Escenarios:**
1. Email vacío, contraseña con valor
2. Email con valor, contraseña vacía
3. Ambos campos vacíos

**Resultado esperado:**
- [ ] Botón "Entrar" deshabilitado en todos los casos

### ⏳ Test 3.5: Persistencia de Sesión
**Estado:** PENDIENTE  
**Pasos:**
1. Iniciar sesión exitosamente
2. Cerrar aplicación
3. Volver a abrir aplicación

**Resultado esperado:**
- [ ] Usuario sigue autenticado
- [ ] No requiere login nuevamente
- [ ] Datos de usuario cargados desde Keychain

### ⏳ Test 3.6: Cerrar Sesión
**Estado:** PENDIENTE  
**Pasos:**
1. Estar autenticado
2. Hacer clic en menú de usuario
3. Seleccionar "Cerrar sesión"

**Resultado esperado:**
- [ ] Sesión cerrada
- [ ] Token eliminado de Keychain
- [ ] Redirección a pantalla de login

---

## 4. Gestión de Catálogos

### ⏳ Test 4.1: Listar Catálogos
**Estado:** PENDIENTE  
**Descripción:** Verificar que se muestran los catálogos del usuario  
**Resultado esperado:**
- [ ] Lista de catálogos visible
- [ ] Cada catálogo muestra nombre y descripción
- [ ] Indicador de carga mientras se obtienen datos
- [ ] Manejo de error si falla la carga

### ⏳ Test 4.2: Crear Nuevo Catálogo
**Estado:** PENDIENTE  
**Pasos:**
1. Hacer clic en botón "Nuevo"
2. Ingresar nombre: "Catálogo de Prueba"
3. Ingresar descripción: "Descripción de prueba"
4. Ingresar columnas: "Columna1, Columna2, Columna3"
5. Hacer clic en "Crear"

**Resultado esperado:**
- [ ] Modal de creación se abre
- [ ] Campos de formulario visibles
- [ ] Catálogo creado en MongoDB
- [ ] Catálogo aparece en la lista
- [ ] Modal se cierra automáticamente

### ⏳ Test 4.3: Ver Detalles de Catálogo
**Estado:** PENDIENTE  
**Pasos:**
1. Hacer clic en un catálogo de la lista

**Resultado esperado:**
- [ ] Vista de detalles se muestra
- [ ] Información del catálogo visible
- [ ] Filas del catálogo listadas
- [ ] Botones de acción disponibles

### ⏳ Test 4.4: Editar Catálogo
**Estado:** PENDIENTE  
**Pasos:**
1. Abrir detalles de catálogo
2. Hacer clic en "Editar Catálogo"
3. Modificar nombre o descripción
4. Guardar cambios

**Resultado esperado:**
- [ ] Modal de edición se abre
- [ ] Campos pre-poblados con datos actuales
- [ ] Cambios guardados en MongoDB
- [ ] Vista actualizada con nuevos datos

### ⏳ Test 4.5: Eliminar Catálogo
**Estado:** PENDIENTE  
**Pasos:**
1. Abrir detalles de catálogo
2. Hacer clic en "Eliminar"
3. Confirmar eliminación

**Resultado esperado:**
- [ ] Diálogo de confirmación mostrado
- [ ] Catálogo eliminado de MongoDB
- [ ] Catálogo removido de la lista
- [ ] Redirección a lista de catálogos

### ⏳ Test 4.6: Permisos de Catálogos
**Estado:** PENDIENTE  
**Escenarios:**
1. Usuario normal ve solo sus catálogos
2. Administrador ve todos los catálogos

**Resultado esperado:**
- [ ] Filtrado correcto según rol de usuario

---

## 5. Gestión de Filas

### ⏳ Test 5.1: Ver Filas de Catálogo
**Estado:** PENDIENTE  
**Descripción:** Verificar que se muestran las filas de un catálogo  
**Resultado esperado:**
- [ ] Tabla con filas visible
- [ ] Columnas del catálogo mostradas
- [ ] Datos de cada fila visibles
- [ ] Scroll funcional si hay muchas filas

### ⏳ Test 5.2: Añadir Nueva Fila
**Estado:** PENDIENTE  
**Pasos:**
1. En vista de detalles, hacer clic en "Editar"
2. Hacer clic en "Añadir Fila"
3. Completar datos para cada columna
4. Guardar

**Resultado esperado:**
- [ ] Modal de edición se abre
- [ ] Formulario con campos para cada columna
- [ ] Fila creada en MongoDB
- [ ] Fila aparece en la tabla

### ⏳ Test 5.3: Editar Fila Existente
**Estado:** PENDIENTE  
**Pasos:**
1. En modo edición, hacer clic en icono de lápiz
2. Modificar datos
3. Guardar cambios

**Resultado esperado:**
- [ ] Campos editables
- [ ] Cambios guardados en MongoDB
- [ ] Tabla actualizada con nuevos datos

### ⏳ Test 5.4: Eliminar Fila
**Estado:** PENDIENTE  
**Pasos:**
1. En modo edición, hacer clic en icono de papelera
2. Confirmar eliminación

**Resultado esperado:**
- [ ] Confirmación solicitada
- [ ] Fila eliminada de MongoDB
- [ ] Fila removida de la tabla

### ⏳ Test 5.5: Validación de Datos en Filas
**Estado:** PENDIENTE  
**Escenarios:**
- Campos requeridos vacíos
- Tipos de datos incorrectos
- Longitud de texto excedida

**Resultado esperado:**
- [ ] Validación en cliente
- [ ] Mensajes de error claros
- [ ] No se permite guardar datos inválidos

---

## 6. Gestión de Archivos

### ⏳ Test 6.1: Subir Archivo a Fila
**Estado:** PENDIENTE  
**Tipos de archivo a probar:**
- Imagen (JPG, PNG)
- Documento (PDF, DOCX)
- Video (MP4)

**Pasos:**
1. En modo edición de fila
2. Hacer clic en botón de subir archivo
3. Seleccionar archivo
4. Guardar

**Resultado esperado:**
- [ ] Selector de archivos se abre
- [ ] Archivo se sube a S3
- [ ] URL del archivo guardada en MongoDB
- [ ] Icono de archivo visible en la fila

### ⏳ Test 6.2: Ver Archivo
**Estado:** PENDIENTE  
**Pasos:**
1. Hacer clic en icono de archivo en una fila

**Resultado esperado:**
- [ ] Archivo se descarga de S3
- [ ] Archivo se abre con aplicación predeterminada
- [ ] Sin errores de permisos

### ⏳ Test 6.3: Eliminar Archivo
**Estado:** PENDIENTE  
**Pasos:**
1. En modo edición
2. Hacer clic en eliminar archivo
3. Confirmar

**Resultado esperado:**
- [ ] Archivo eliminado de S3
- [ ] Referencia eliminada de MongoDB
- [ ] Icono de archivo desaparece

### ⏳ Test 6.4: Manejo de Errores de S3
**Estado:** PENDIENTE  
**Escenarios:**
- Credenciales inválidas
- Bucket no existe
- Sin permisos de escritura
- Archivo muy grande

**Resultado esperado:**
- [ ] Mensajes de error claros
- [ ] Aplicación no se bloquea
- [ ] Usuario puede reintentar

---

## 7. Perfil de Usuario

### ⏳ Test 7.1: Ver Perfil
**Estado:** PENDIENTE  
**Pasos:**
1. Hacer clic en "Perfil" en menú lateral

**Resultado esperado:**
- [ ] Vista de perfil se muestra
- [ ] Email del usuario visible
- [ ] Rol del usuario visible
- [ ] Fecha de registro visible
- [ ] Otros campos opcionales si existen

### ⏳ Test 7.2: Editar Perfil
**Estado:** PENDIENTE  
**Pasos:**
1. En vista de perfil
2. Hacer clic en "Editar"
3. Modificar campos editables
4. Guardar

**Resultado esperado:**
- [ ] Campos editables habilitados
- [ ] Cambios guardados en MongoDB
- [ ] Vista actualizada con nuevos datos

---

## 8. Administración

### ⏳ Test 8.1: Acceso a Panel de Administración
**Estado:** PENDIENTE  
**Escenarios:**
1. Usuario normal intenta acceder
2. Usuario administrador accede

**Resultado esperado:**
- [ ] Usuario normal: opción no visible en menú
- [ ] Administrador: opción visible y accesible

### ⏳ Test 8.2: Gestión de Usuarios (si aplica)
**Estado:** PENDIENTE  
**Funcionalidades a probar:**
- Listar usuarios
- Crear usuario
- Editar usuario
- Eliminar usuario
- Cambiar roles

**Resultado esperado:**
- [ ] Todas las operaciones funcionan correctamente
- [ ] Solo administradores pueden acceder

---

## 9. Navegación y UI

### ⏳ Test 9.1: Menú Lateral
**Estado:** PENDIENTE  
**Elementos a verificar:**
- [ ] Catálogos
- [ ] Perfil
- [ ] Administración (solo admin)
- [ ] Cerrar sesión

**Resultado esperado:**
- [ ] Todos los elementos visibles según rol
- [ ] Navegación funciona correctamente
- [ ] Selección visual del elemento activo

### ⏳ Test 9.2: Navegación entre Vistas
**Estado:** PENDIENTE  
**Rutas a probar:**
- Login → Catálogos
- Catálogos → Detalle de Catálogo
- Detalle → Catálogos (volver)
- Catálogos → Perfil
- Perfil → Catálogos

**Resultado esperado:**
- [ ] Transiciones suaves
- [ ] Estado preservado al volver
- [ ] Sin errores de navegación

### ⏳ Test 9.3: Responsive Design
**Estado:** PENDIENTE  
**Tamaños de ventana a probar:**
- Mínimo (800x600)
- Medio (1280x720)
- Grande (1920x1080)

**Resultado esperado:**
- [ ] UI se adapta correctamente
- [ ] Sin elementos cortados
- [ ] Scroll funcional cuando es necesario

### ⏳ Test 9.4: Modo Oscuro/Claro
**Estado:** PENDIENTE  
**Descripción:** Verificar que la aplicación respeta el tema del sistema  
**Resultado esperado:**
- [ ] Colores apropiados en modo claro
- [ ] Colores apropiados en modo oscuro
- [ ] Contraste adecuado en ambos modos

---

## 10. Rendimiento y Estabilidad

### ⏳ Test 10.1: Tiempo de Carga Inicial
**Estado:** PENDIENTE  
**Métrica:** Tiempo desde lanzamiento hasta pantalla de login  
**Objetivo:** < 3 segundos

### ⏳ Test 10.2: Tiempo de Autenticación
**Estado:** PENDIENTE  
**Métrica:** Tiempo desde clic en "Entrar" hasta vista principal  
**Objetivo:** < 2 segundos

### ⏳ Test 10.3: Carga de Lista de Catálogos
**Estado:** PENDIENTE  
**Escenarios:**
- 10 catálogos
- 50 catálogos
- 100 catálogos

**Objetivo:** < 1 segundo para cualquier cantidad

### ⏳ Test 10.4: Uso de Memoria
**Estado:** PENDIENTE  
**Descripción:** Monitorear uso de memoria durante operaciones normales  
**Objetivo:** < 200 MB en uso normal

### ⏳ Test 10.5: Manejo de Errores de Red
**Estado:** PENDIENTE  
**Escenarios:**
- Sin conexión a internet
- MongoDB no disponible
- S3 no disponible
- Timeout de conexión

**Resultado esperado:**
- [ ] Mensajes de error claros
- [ ] Aplicación no se bloquea
- [ ] Opción de reintentar
- [ ] Degradación elegante

### ⏳ Test 10.6: Prueba de Estrés
**Estado:** PENDIENTE  
**Descripción:** Operaciones intensivas continuas  
**Acciones:**
- Crear 20 catálogos consecutivos
- Añadir 50 filas a un catálogo
- Subir 10 archivos simultáneamente

**Resultado esperado:**
- [ ] Sin crashes
- [ ] Sin memory leaks
- [ ] Rendimiento aceptable

### ⏳ Test 10.7: Estabilidad a Largo Plazo
**Estado:** PENDIENTE  
**Descripción:** Dejar aplicación abierta durante 1 hora con uso intermitente  
**Resultado esperado:**
- [ ] Sin crashes
- [ ] Sin degradación de rendimiento
- [ ] Memoria estable

---

## 📊 Resumen de Resultados

### Estado General
- **Total de Tests:** 50+
- **Completados:** 3
- **En Progreso:** 1
- **Pendientes:** 46+
- **Pasados:** 3
- **Fallados:** 0

### Tests Críticos
- ✅ Compilación
- ✅ Empaquetado
- ✅ Ejecución con doble clic
- 🔄 Carga de variables de entorno
- ⏳ Autenticación
- ⏳ Gestión de catálogos

### Próximos Pasos
1. Completar verificación de carga de variables de entorno
2. Realizar tests de autenticación
3. Probar gestión de catálogos
4. Verificar gestión de archivos
5. Tests de rendimiento

---

## 🐛 Bugs Encontrados

### Bug #1: Warnings de CLibMongoC
**Severidad:** Baja  
**Descripción:** Warnings sobre headers no incluidos en umbrella header  
**Impacto:** No afecta funcionalidad  
**Estado:** Conocido, no crítico

---

## 📝 Notas Adicionales

- La aplicación se compila y ejecuta correctamente
- El bundle .app incluye correctamente el archivo .env
- La firma ad-hoc permite ejecución sin problemas de seguridad
- Los logs del sistema muestran inicialización correcta de la aplicación

---

**Última actualización:** 18 de Octubre de 2025, 19:06
