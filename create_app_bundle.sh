#!/bin/bash

# Script para crear bundle de aplicación macOS

set -e

APP_NAME="EDF Catálogo de Tablas"
BUNDLE_NAME="EDF Catálogo de Tablas.app"
BUILD_DIR=".build/release"
BIN_DIR="bin"
RESOURCES_DIR="Resources"

echo "🏗️  Creando bundle de aplicación..."

# Crear estructura de directorios
mkdir -p "$BIN_DIR/$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BIN_DIR/$BUNDLE_NAME/Contents/Resources"

# Copiar ejecutable
echo "📦 Copiando ejecutable..."
cp "$BUILD_DIR/EDFCatalogoSwift" "$BIN_DIR/$BUNDLE_NAME/Contents/MacOS/EDFCatalogoSwift"
chmod +x "$BIN_DIR/$BUNDLE_NAME/Contents/MacOS/EDFCatalogoSwift"

# Convertir JPEG a ICNS si es necesario
if [ -f "$RESOURCES_DIR/favicon_chula.jpeg" ]; then
    echo "🎨 Procesando icono..."
    
    # Crear iconset temporal
    ICONSET_DIR="$BIN_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # Convertir JPEG a PNG y crear diferentes tamaños
    sips -s format png "$RESOURCES_DIR/favicon_chula.jpeg" --out "$BIN_DIR/temp_icon.png" > /dev/null 2>&1
    
    sips -z 16 16     "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32     "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32     "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64     "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128   "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256   "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256   "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512   "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512   "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1
    sips -z 1024 1024 "$BIN_DIR/temp_icon.png" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1
    
    # Crear ICNS
    iconutil -c icns "$ICONSET_DIR" -o "$BIN_DIR/$BUNDLE_NAME/Contents/Resources/AppIcon.icns"
    
    # Limpiar temporales
    rm -rf "$ICONSET_DIR" "$BIN_DIR/temp_icon.png"
fi

# Crear Info.plist
echo "📝 Creando Info.plist..."
cat > "$BIN_DIR/$BUNDLE_NAME/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>EDFCatalogoSwift</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.edf.catalogotablas</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ Bundle creado exitosamente en: $BIN_DIR/$BUNDLE_NAME"
echo ""
echo "Para ejecutar la aplicación:"
echo "  open '$BIN_DIR/$BUNDLE_NAME'"
