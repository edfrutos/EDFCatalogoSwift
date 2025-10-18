#!/bin/bash

# Script para empaquetar la aplicación para distribución

set -e  # Salir si hay algún error

# Colores para los mensajes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Empaquetando EDFCatalogoSwift para distribución ===${NC}"

# Directorio del proyecto
PROJECT_DIR="$(pwd)"
APP_NAME="EDF Catálogo de Tablas"
BUILD_DIR="${PROJECT_DIR}/bin"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DIST_DIR="${PROJECT_DIR}/dist"
ZIP_FILE="${DIST_DIR}/${APP_NAME}.app.zip"

# Verificar si la aplicación existe
if [ ! -d "${APP_PATH}" ]; then
    echo -e "${RED}Error: La aplicación no existe en ${APP_PATH}${NC}"
    echo -e "${YELLOW}Ejecute primero el script build-macos.sh para generar la aplicación${NC}"
    exit 1
fi

# Crear directorio de distribución
echo -e "${YELLOW}Creando directorio de distribución...${NC}"
mkdir -p "${DIST_DIR}"

# Copiar documentación
echo -e "${YELLOW}Copiando documentación...${NC}"
cp "${PROJECT_DIR}/README.md" "${DIST_DIR}/README.md"
cp "${PROJECT_DIR}/MANUAL_DE_USUARIO.md" "${DIST_DIR}/MANUAL_DE_USUARIO.md"

# Crear archivo ZIP con la aplicación
echo -e "${YELLOW}Creando archivo ZIP...${NC}"
cd "${BUILD_DIR}"
zip -r "${ZIP_FILE}" "${APP_NAME}.app"
cd "${PROJECT_DIR}"

# Verificar si el archivo ZIP se creó correctamente
if [ -f "${ZIP_FILE}" ]; then
    echo -e "${GREEN}=== Empaquetado completado ===${NC}"
    echo -e "${GREEN}El archivo ZIP está disponible en: ${ZIP_FILE}${NC}"
else
    echo -e "${RED}Error: No se pudo crear el archivo ZIP${NC}"
    exit 1
fi

# Mostrar contenido del directorio de distribución
echo -e "${YELLOW}Contenido del directorio de distribución:${NC}"
ls -la "${DIST_DIR}"
