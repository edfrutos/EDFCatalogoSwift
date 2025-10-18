#!/bin/bash

# Script para ejecutar la aplicación con variables de entorno desde .env

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Lanzador de EDF Catálogo de Tablas ===${NC}"

# Verificar que existe el archivo .env
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Error: No se encuentra el archivo .env${NC}"
    echo "Por favor, crea un archivo .env con las siguientes variables:"
    echo "  MONGODB_URI=tu_uri_de_mongodb"
    echo "  MONGODB_DB=nombre_de_tu_base_de_datos"
    exit 1
fi

# Cargar variables del .env
echo -e "${YELLOW}📄 Cargando variables de entorno desde .env...${NC}"
export $(cat .env | grep -v '^#' | xargs)

# Verificar que las variables críticas están definidas
if [ -z "$MONGODB_URI" ]; then
    echo -e "${RED}❌ Error: MONGODB_URI no está definida en .env${NC}"
    exit 1
fi

if [ -z "$MONGODB_DB" ]; then
    echo -e "${YELLOW}⚠️  Advertencia: MONGODB_DB no está definida, usando valor por defecto${NC}"
    export MONGODB_DB="edf_catalogo_tablas"
fi

echo -e "${GREEN}✅ Variables de entorno cargadas:${NC}"
echo "   MONGODB_URI: ${MONGODB_URI:0:30}..."
echo "   MONGODB_DB: $MONGODB_DB"

# Lanzar la aplicación
echo -e "${GREEN}🚀 Lanzando aplicación...${NC}"
open -a "bin/EDF Catálogo de Tablas.app" --env MONGODB_URI="$MONGODB_URI" --env MONGODB_DB="$MONGODB_DB"

echo -e "${GREEN}✅ Aplicación lanzada${NC}"
echo ""
echo "Para ver los logs en tiempo real, ejecuta:"
echo "  log stream --predicate 'process == \"EDFCatalogoSwift\"' --level debug"
