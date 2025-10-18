#!/bin/bash

# Script para ejecutar la aplicación EDF Catálogo de Tablas
# Este script asegura que las variables de entorno se carguen correctamente

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Lanzador de EDF Catálogo de Tablas ===${NC}"

# Directorio del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Verificar que existe el archivo .env
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Error: No se encuentra el archivo .env${NC}"
    echo "Por favor, crea un archivo .env con las siguientes variables:"
    echo "  MONGO_URI=tu_uri_de_mongodb"
    echo "  MONGO_DB=nombre_de_tu_base_de_datos"
    exit 1
fi

# Cargar variables del .env (ignorando comentarios y líneas vacías)
echo -e "${YELLOW}📄 Cargando variables de entorno desde .env...${NC}"
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
done < .env

# Verificar que las variables críticas están definidas
if [ -z "$MONGO_URI" ] && [ -z "$MONGODB_URI" ]; then
    echo -e "${RED}❌ Error: MONGO_URI o MONGODB_URI no está definida en .env${NC}"
    exit 1
fi

if [ -z "$MONGO_DB" ] && [ -z "$MONGODB_DB" ]; then
    echo -e "${YELLOW}⚠️  Advertencia: MONGO_DB no está definida, usando valor por defecto${NC}"
    export MONGO_DB="edf_catalogotablas"
fi

echo -e "${GREEN}✅ Variables de entorno cargadas:${NC}"
if [ -n "$MONGO_URI" ]; then
    echo "   MONGO_URI: ${MONGO_URI:0:30}..."
fi
if [ -n "$MONGO_DB" ]; then
    echo "   MONGO_DB: $MONGO_DB"
fi

# Ejecutar la aplicación directamente
echo -e "${GREEN}🚀 Lanzando aplicación...${NC}"
exec "$PROJECT_DIR/bin/EDF Catálogo de Tablas.app/Contents/MacOS/EDFCatalogoSwift"
