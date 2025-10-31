# 📦 Instrucciones para Crear DMG de Distribución

Este documento describe cómo crear un archivo DMG listo para distribución de la aplicación EDF Catálogo de Tablas.

## 🚀 Uso Rápido

```bash
./create-dmg.sh
```

El script creará automáticamente un DMG en `dist/EDFCatalogoSwift_v1.0.dmg` con todo lo necesario.

## 📋 Requisitos Previos

1. **Aplicación compilada**: La aplicación debe estar compilada en `bin/EDFCatalogoSwift.app`
   ```bash
   ./build.sh
   ```

2. **Archivo de configuración**: Debe existir un archivo `.env` en la raíz del proyecto con las credenciales de servicios:
   - MongoDB Atlas (MONGO_URI, MONGO_DB)
   - AWS S3 (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, etc.)
   - Brevo (BREVO_API_KEY, etc.)

   Si no existe `.env`, el script puede usar `.env.example` como base (pero sin credenciales reales).

## 📦 Contenido del DMG

El DMG incluye:

- ✅ **EDF Catálogo de Tablas.app** - La aplicación compilada con el .env incluido en el bundle
- ✅ **.env** - Archivo de configuración con credenciales (también dentro del bundle)
- ✅ **README.md** - Documentación general del proyecto
- ✅ **MANUAL_DE_USUARIO.md** - Manual completo de usuario
- ✅ **INSTALACION.txt** - Guía de instalación paso a paso
- ✅ **LICENSE.txt** - Términos de uso y confidencialidad

## 🔧 Configuración del Script

El script `create-dmg.sh` realiza las siguientes acciones:

1. Verifica que la aplicación esté compilada
2. Verifica la existencia del archivo `.env`
3. Crea un directorio temporal para el empaquetado
4. Copia la aplicación al directorio temporal
5. Actualiza el `.env` dentro del bundle de la aplicación
6. Copia el `.env` también en el directorio raíz del DMG (para referencia)
7. Copia toda la documentación
8. Crea archivos de ayuda (INSTALACION.txt, LICENSE.txt)
9. Configura permisos correctos
10. Crea el archivo DMG comprimido
11. Limpia archivos temporales

## 📍 Ubicación del DMG

El DMG se crea en:
```
dist/EDFCatalogoSwift_v1.0.dmg
```

## 🧪 Probar el DMG

Para probar el DMG creado:

```bash
open dist/EDFCatalogoSwift_v1.0.dmg
```

O simplemente haz doble clic en el archivo desde Finder.

## 📝 Personalización

### Cambiar el nombre del DMG

Edita la variable `DMG_NAME` en `create-dmg.sh`:

```bash
DMG_NAME="${APP_SHORT_NAME}_v1.0"  # Cambiar a la versión deseada
```

### Agregar más archivos

Agrega comandos de copia después de la sección "Copiar documentación":

```bash
# Copiar archivo adicional
cp "ruta/al/archivo" "${DMG_TEMP_DIR}/package/"
```

## ⚠️ Importante

- **Credenciales**: El archivo `.env` incluye credenciales reales de servicios. Mantenga el DMG seguro y solo distribuirlo a usuarios autorizados.
- **Términos de uso**: El DMG incluye un archivo LICENSE.txt que advierte sobre el uso interno y la confidencialidad de las credenciales.
- **macOS**: El DMG está optimizado para macOS. El script usa `hdiutil` que es nativo de macOS.

## 🔒 Seguridad

- El archivo `.env` contiene credenciales sensibles
- No suba el DMG a repositorios públicos
- Distribuya el DMG solo a usuarios autorizados
- Considere cifrar el DMG si lo distribuye por canales no seguros

## 📊 Tamaño Estimado

Un DMG típico ocupa aproximadamente:
- 8-12 MB (dependiendo del contenido)

## ✅ Verificación

Después de crear el DMG, verifica:

1. Que el DMG se monta correctamente
2. Que la aplicación se puede ejecutar con doble clic
3. Que el `.env` está presente tanto en el DMG como dentro del bundle
4. Que toda la documentación está incluida

## 🐛 Solución de Problemas

### Error: "La aplicación no existe"
- Ejecuta `./build.sh` primero para compilar la aplicación

### Error: "No se encontró .env"
- Crea un archivo `.env` desde `.env.example` y complétalo con credenciales reales

### Error al montar el DMG
- Verifica que tienes permisos de escritura en `dist/`
- Intenta eliminar el directorio `dist/` y ejecutar el script de nuevo

### El .env no se carga en la aplicación
- Verifica que el `.env` está en `Contents/Resources/.env` dentro del bundle
- Verifica los permisos del archivo (debe ser 644)

