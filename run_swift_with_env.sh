#!/bin/bash

# Script para ejecutar la aplicación Swift con variables de entorno

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Lanzando EDFCatalogo Swift ===${NC}"

# Cargar variables del .env
if [ -f ".env" ]; then
    echo -e "${YELLOW}📄 Cargando variables desde .env...${NC}"
    export $(grep -v '^#' .env | grep -v '^$' | sed 's/\s*=\s*/=/' | xargs)
fi

# Verificar variables críticas
echo -e "${GREEN}✅ Variables configuradas:${NC}"
echo "  - AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:10}..."
echo "  - AWS_REGION: $AWS_REGION"
echo "  - S3_BUCKET_NAME: $S3_BUCKET_NAME"
echo "  - USE_S3: $USE_S3"
echo "  - MONGODB_DB: $MONGODB_DB"
echo ""

# Ejecutar la aplicación
echo -e "${GREEN}🚀 Ejecutando aplicación...${NC}"

# Verificar si existe el binario de release
if [ -f ".build/release/EDFCatalogoSwift" ]; then
    echo "  Usando binario release"
    .build/release/EDFCatalogoSwift
else
    echo "  Compilando y ejecutando en modo debug"
    swift run
fi
