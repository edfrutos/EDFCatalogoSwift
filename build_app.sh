#!/bin/bash

# ============================================================
# Script para compilar y empaquetar EDFCatalogoSwift (macOS)
# usando credenciales AWS estándar (~/.aws/credentials y config)
# ============================================================

set -Eeuo pipefail
IFS=$'\n\t'

# --- Colores para mensajes ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

echo -e "${GREEN}=== Compilando EDFCatalogoSwift para macOS ===${NC}"

# --- Rutas y nombres ---
PROJECT_DIR="$(pwd)"
APP_NAME="EDF Catálogo de Tablas"
BUILD_DIR="${PROJECT_DIR}/.build"
APP_DIR="${PROJECT_DIR}/bin/${APP_NAME}.app"
RESOURCES_DIR="${APP_DIR}/Contents/Resources"

# --- Limpiar compilaciones previas ---
echo -e "${YELLOW}Limpiando directorios anteriores...${NC}"
rm -rf "${BUILD_DIR}" "${APP_DIR}" "${PROJECT_DIR}/bin"
mkdir -p "${PROJECT_DIR}/bin"

# --- Compilar en modo release ---
echo -e "${YELLOW}Compilando el proyecto...${NC}"
swift build -c release

# Obtener ruta del binario compilado de forma fiable
BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="${BIN_DIR}/EDFCatalogoSwift"

# --- Crear estructura básica del .app ---
echo -e "${YELLOW}Creando estructura de la aplicación...${NC}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${RESOURCES_DIR}/Assets"

# --- Copiar el ejecutable ---
echo -e "${YELLOW}Copiando el ejecutable...${NC}"
cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/EDFCatalogoSwift"
chmod +x "${APP_DIR}/Contents/MacOS/EDFCatalogoSwift"

# --- Copiar recursos ---
echo -e "${YELLOW}Copiando recursos...${NC}"
cp "${PROJECT_DIR}/Resources/favicon_chula.jpeg" "${RESOURCES_DIR}/Assets/" 2>/dev/null || true

# --- Copiar archivo .env si existe ---
if [ -f "${PROJECT_DIR}/.env" ]; then
    echo -e "${YELLOW}Copiando archivo .env...${NC}"
    cp "${PROJECT_DIR}/.env" "${RESOURCES_DIR}/.env"
    echo -e "${GREEN}✅ Archivo .env copiado al bundle${NC}"
else
    echo -e "${RED}⚠️  Advertencia: No se encontró archivo .env${NC}"
fi

# --- Crear Info.plist ---
echo -e "${YELLOW}Creando Info.plist...${NC}"
cat > "${APP_DIR}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher.sh</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.edf.catalogotablas</string>
    <key>CFBundleName</key>
    <string>EDF Catálogo de Tablas</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# --- Crear launcher.sh actualizado ---
echo -e "${YELLOW}Creando launcher.sh...${NC}"
cat > "${APP_DIR}/Contents/MacOS/launcher.sh" << 'LAUNCHER'
#!/usr/bin/env bash
# launcher.sh — Lanza la app cargando variables de entorno desde .env

set -Eeuo pipefail
IFS=$'\n\t'

# Directorio del ejecutable dentro del .app
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Buscar el archivo .env - PRIMERO dentro del bundle
ENV_FILE="${DIR}/../Resources/.env"

# Si no existe dentro del bundle, buscar en el directorio del proyecto
if [[ ! -f "$ENV_FILE" ]]; then
  PROJECT_DIR="${DIR}/../../../../.."
  ENV_FILE="${PROJECT_DIR}/.env"
  
  # Si tampoco existe ahí, intentar otra ubicación
  if [[ ! -f "$ENV_FILE" ]]; then
    PROJECT_DIR="${DIR}/../../../.."
    ENV_FILE="${PROJECT_DIR}/.env"
  fi
fi

# Cargar variables de entorno desde .env si existe
if [[ -f "$ENV_FILE" ]]; then
  echo "📄 Cargando variables de entorno desde: $ENV_FILE"
  
  # Cargar el .env línea por línea para manejar espacios correctamente
  while IFS= read -r line || [ -n "$line" ]; do
    # Ignorar comentarios y líneas vacías
    if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
      # Eliminar espacios alrededor del = y exportar
      if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
        var_name="${BASH_REMATCH[1]}"
        var_value="${BASH_REMATCH[2]}"
        export "$var_name=$var_value"
      fi
    fi
  done < "$ENV_FILE"
  
  echo "✅ Variables de entorno cargadas"
else
  echo "⚠️  Advertencia: No se encontró archivo .env"
  echo "   Buscado en: $ENV_FILE"
  echo "   La aplicación usará valores por defecto"
fi

# NOTA: Las credenciales AWS se leen automáticamente desde:
#   ~/.aws/credentials
#   ~/.aws/config

# Mostrar información de conexión (sin mostrar credenciales completas)
if [[ -n "${MONGO_URI:-}" ]]; then
  echo "🔌 MongoDB URI configurado: ${MONGO_URI:0:30}..."
elif [[ -n "${MONGODB_URI:-}" ]]; then
  echo "🔌 MongoDB URI configurado: ${MONGODB_URI:0:30}..."
fi

if [[ -n "${MONGO_DB:-}" ]]; then
  echo "🗄️  Base de datos: ${MONGO_DB}"
elif [[ -n "${MONGODB_DB:-}" ]]; then
  echo "🗄️  Base de datos: ${MONGODB_DB}"
fi

# Ejecutar la aplicación
echo "🚀 Lanzando EDFCatalogoSwift..."
exec "${DIR}/EDFCatalogoSwift"
LAUNCHER

chmod +x "${APP_DIR}/Contents/MacOS/launcher.sh"

# --- Crear icono (.icns) ---
echo -e "${YELLOW}Creando icono de la aplicación...${NC}"
mkdir -p "${PROJECT_DIR}/tmp_iconset.iconset"
cp "${PROJECT_DIR}/Resources/favicon_chula.jpeg" "${PROJECT_DIR}/tmp_iconset.iconset/icon_512x512.jpg" 2>/dev/null || true
sips -s format png "${PROJECT_DIR}/tmp_iconset.iconset/icon_512x512.jpg" --out "${PROJECT_DIR}/tmp_iconset.iconset/icon_512x512.png" >/dev/null

# Crear diferentes tamaños
for size in 16 32 64 128 256 512; do
  sips -z $size $size "${PROJECT_DIR}/tmp_iconset.iconset/icon_512x512.png" --out "${PROJECT_DIR}/tmp_iconset.iconset/icon_${size}x${size}.png" >/dev/null
done
cp "${PROJECT_DIR}/tmp_iconset.iconset/icon_512x512.png" "${PROJECT_DIR}/tmp_iconset.iconset/icon_512x512@2x.png"

# Generar AppIcon.icns
iconutil -c icns "${PROJECT_DIR}/tmp_iconset.iconset" -o "${RESOURCES_DIR}/AppIcon.icns" 2>/dev/null || true
rm -rf "${PROJECT_DIR}/tmp_iconset.iconset"

# --- Firmar la aplicación (firma ad-hoc) ---
echo -e "${YELLOW}Firmando la aplicación...${NC}"
codesign --force --deep --sign - "${APP_DIR}"

# --- Quitar atributos de cuarentena ---
echo -e "${YELLOW}Quitando atributos de cuarentena...${NC}"
xattr -cr "${APP_DIR}"

# --- Final ---
echo -e "${GREEN}=== Compilación completada ===${NC}"
echo -e "${GREEN}Aplicación creada en:${NC} ${APP_DIR}"
echo -e "${YELLOW}Para ejecutar, haz doble clic en la app o usa:${NC}"
echo -e "${YELLOW}open \"${APP_DIR}\"${NC}"
