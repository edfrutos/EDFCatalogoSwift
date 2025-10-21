#!/bin/bash

# Script maestro para compilar y ejecutar EDFCatalogoSwift
# Este es el ÚNICO script que debes usar para build completo

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Build Completo de EDFCatalogoSwift ===${NC}"

# 0. Cerrar app si está corriendo
echo -e "${YELLOW}🛡️ Paso 0/5: Cerrando instancias anteriores...${NC}"
if pgrep -x "EDFCatalogoSwift" > /dev/null; then
    pkill -9 EDFCatalogoSwift
    echo -e "${GREEN}   ✅ App cerrada${NC}"
    sleep 1
else
    echo -e "${GREEN}   ✅ No hay instancias corriendo${NC}"
fi

# 1. Limpiar build anterior
echo -e "${YELLOW}🧽 Paso 1/5: Limpiando build anterior...${NC}"
rm -rf .build/release 2>/dev/null || true
rm -rf EDFCatalogoSwift.app 2>/dev/null || true
echo -e "${GREEN}   ✅ Limpieza completada${NC}"

# 2. Compilar en modo release
echo -e "${YELLOW}🔨 Paso 2/5: Compilando en modo release...${NC}"
swift build -c release

# 3. Crear estructura del bundle
APP_NAME="EDFCatalogoSwift"
BIN_DIR="bin"
APP_PATH="$BIN_DIR/$APP_NAME.app"
CONTENTS="$APP_PATH/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo -e "${YELLOW}📦 Paso 3/5: Creando bundle de aplicación...${NC}"

# Crear directorios
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# 4. Copiar ejecutable y recursos
echo -e "${YELLOW}📋 Paso 4/5: Copiando recursos...${NC}"
cp ".build/release/EDFCatalogoSwift" "$MACOS/"
chmod +x "$MACOS/EDFCatalogoSwift"

# Copiar .env
if [ -f ".env" ]; then
    cp ".env" "$RESOURCES/"
    echo -e "${GREEN}   ✅ .env copiado${NC}"
else
    echo -e "${RED}   ⚠️  No se encontró .env${NC}"
fi

# Copiar icono si existe
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES/"
    echo -e "${GREEN}   ✅ Icono copiado${NC}"
fi

# 5. Crear Info.plist
echo -e "${YELLOW}📝 Paso 5/5: Creando Info.plist...${NC}"
cat > "$CONTENTS/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>EDFCatalogoSwift</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.edefrutos.EDFCatalogoSwift</string>
    <key>CFBundleName</key>
    <string>EDFCatalogoSwift</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo -e "${GREEN}✅ Build completado exitosamente${NC}"
echo -e "${GREEN}📦 Aplicación: $APP_PATH${NC}"
echo ""
echo -e "${YELLOW}🚀 Abriendo aplicación...${NC}"
open "$APP_PATH"

echo ""
echo -e "${GREEN}=== Proceso completado ===${NC}"
echo "Para ver logs en tiempo real:"
echo "  log stream --predicate 'process == \"EDFCatalogoSwift\"' --level debug"
