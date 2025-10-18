#!/bin/bash
# ======================================================
# Script de Eugenio para parchear CLibMongoC.h (mongo-swift-driver)
# Soluciona warnings de umbrella headers faltantes.
# ======================================================

set -e

TARGET_FILE=".build/checkouts/mongo-swift-driver/Sources/CLibMongoC/include/CLibMongoC.h"

# Verificar que el archivo existe
if [ ! -f "$TARGET_FILE" ]; then
  echo "❌ No se encontró $TARGET_FILE"
  echo "Ejecuta primero: swift package resolve"
  exit 1
fi

# Buscar si ya contiene las cabeceras
if grep -q "CLibMongoC_common-config.h" "$TARGET_FILE"; then
  echo "✅ El archivo ya está parcheado. No se hace nada."
  exit 0
fi

echo "🛠️ Parcheando $TARGET_FILE..."

# Añadir las cabeceras antes del #endif
sed -i '' '/#include "CLibMongoC_mongoc.h"/a\
#include "CLibMongoC_common-config.h"\
#include "CLibMongoC_mongoc-stream-tls-libressl.h"\
#include "CLibMongoC_common-b64-private.h"\
#include "CLibMongoC_common-macros-private.h"\
' "$TARGET_FILE"

echo "✅ Parche aplicado correctamente."
