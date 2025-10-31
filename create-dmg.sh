#!/bin/bash

# Script para crear un DMG de distribución de EDFCatalogoSwift
# Incluye la aplicación, configuración y documentación

set -e  # Salir si hay algún error

# Colores para los mensajes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   📦 Empaquetado en DMG - EDF Catálogo de Tablas${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Configuración
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="EDF Catálogo de Tablas"
APP_SHORT_NAME="EDFCatalogoSwift"
BUILD_DIR="${PROJECT_DIR}/bin"
APP_PATH="${BUILD_DIR}/${APP_SHORT_NAME}.app"
DIST_DIR="${PROJECT_DIR}/dist"
DMG_NAME="${APP_SHORT_NAME}_v1.0"
DMG_FILE="${DIST_DIR}/${DMG_NAME}.dmg"
DMG_TEMP_DIR="${DIST_DIR}/dmg_temp"
DMG_MOUNT_DIR="${DMG_TEMP_DIR}/mount"

# Verificar que la aplicación existe
echo -e "${YELLOW}🔍 Verificando aplicación compilada...${NC}"
if [ ! -d "${APP_PATH}" ]; then
    echo -e "${RED}❌ Error: La aplicación no existe en ${APP_PATH}${NC}"
    echo -e "${YELLOW}💡 Ejecute primero './build.sh' para compilar la aplicación${NC}"
    exit 1
fi
echo -e "${GREEN}   ✅ Aplicación encontrada${NC}"

# Verificar archivo .env (requerido para distribución con credenciales)
echo -e "${YELLOW}🔍 Verificando archivo de configuración...${NC}"
ENV_FILE="${PROJECT_DIR}/.env"
ENV_EXAMPLE="${PROJECT_DIR}/.env.example"

if [ ! -f "${ENV_FILE}" ]; then
    echo -e "${RED}   ❌ No se encontró archivo .env${NC}"
    if [ -f "${ENV_EXAMPLE}" ]; then
        echo -e "${YELLOW}   💡 Se encontró .env.example como referencia${NC}"
        echo -e "${YELLOW}   ⚠️  Para crear el DMG con credenciales, necesita un archivo .env${NC}"
        echo -e "${YELLOW}   💡 Puede crearlo desde .env.example y completarlo con credenciales reales${NC}"
        echo ""
        read -p "¿Desea continuar usando .env.example? (s/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            echo -e "${RED}   ❌ Operación cancelada${NC}"
            exit 1
        fi
        ENV_FILE="${ENV_EXAMPLE}"
        echo -e "${YELLOW}   ⚠️  Usando .env.example (sin credenciales reales)${NC}"
    else
        echo -e "${RED}   ❌ No se encontró .env ni .env.example${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}   ✅ Archivo .env encontrado${NC}"
    # Verificar que no esté vacío o solo con comentarios
    if ! grep -q "^[^#]*=" "${ENV_FILE}" 2>/dev/null; then
        echo -e "${YELLOW}   ⚠️  El archivo .env parece estar vacío o solo contiene comentarios${NC}"
        read -p "¿Desea continuar? (s/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            echo -e "${RED}   ❌ Operación cancelada${NC}"
            exit 1
        fi
    fi
fi

# Crear directorios
echo -e "${YELLOW}📁 Creando directorios de distribución...${NC}"
rm -rf "${DIST_DIR}" 2>/dev/null || true
mkdir -p "${DIST_DIR}"
mkdir -p "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}/package"
mkdir -p "${DMG_MOUNT_DIR}"
echo -e "${GREEN}   ✅ Directorios creados${NC}"

# Copiar aplicación
echo -e "${YELLOW}📦 Copiando aplicación...${NC}"
cp -R "${APP_PATH}" "${DMG_TEMP_DIR}/package/${APP_NAME}.app"
echo -e "${GREEN}   ✅ Aplicación copiada${NC}"

# Asegurar que el .env también esté dentro del bundle de la aplicación
echo -e "${YELLOW}📋 Actualizando .env en el bundle de la aplicación...${NC}"
APP_ENV_PATH="${DMG_TEMP_DIR}/package/${APP_NAME}.app/Contents/Resources/.env"
if [ -d "${DMG_TEMP_DIR}/package/${APP_NAME}.app/Contents/Resources" ]; then
    cp "${ENV_FILE}" "${APP_ENV_PATH}"
    chmod 644 "${APP_ENV_PATH}"
    echo -e "${GREEN}   ✅ .env actualizado en el bundle${NC}"
fi

# Copiar archivo .env
echo -e "${YELLOW}📋 Copiando configuración...${NC}"
cp "${ENV_FILE}" "${DMG_TEMP_DIR}/package/.env"
echo -e "${GREEN}   ✅ Archivo .env copiado${NC}"

# Copiar documentación
echo -e "${YELLOW}📚 Copiando documentación...${NC}"
if [ -f "${PROJECT_DIR}/README.md" ]; then
    cp "${PROJECT_DIR}/README.md" "${DMG_TEMP_DIR}/package/"
fi
if [ -f "${PROJECT_DIR}/MANUAL_DE_USUARIO.md" ]; then
    cp "${PROJECT_DIR}/MANUAL_DE_USUARIO.md" "${DMG_TEMP_DIR}/package/"
fi
echo -e "${GREEN}   ✅ Documentación copiada${NC}"

# Crear README de instalación
echo -e "${YELLOW}📝 Creando guía de instalación...${NC}"
cat > "${DMG_TEMP_DIR}/package/INSTALACION.txt" << 'EOF'
═══════════════════════════════════════════════════════════
  EDF Catálogo de Tablas - Guía de Instalación
═══════════════════════════════════════════════════════════

PASO 1: INSTALAR LA APLICACIÓN
───────────────────────────────────────────────────────────
1. Arrastre "EDF Catálogo de Tablas.app" a la carpeta 
   "Aplicaciones" o cualquier otra ubicación de su preferencia.

2. Haga doble clic en la aplicación para ejecutarla.

PASO 2: CONFIGURAR CREDENCIALES (PRIMERA VEZ)
───────────────────────────────────────────────────────────
La aplicación incluye un archivo .env con las credenciales 
de servicios configuradas. Si necesita cambiar alguna 
configuración:

1. Haga clic derecho en la aplicación.
2. Seleccione "Mostrar contenido del paquete".
3. Navegue a: Contents > Resources > .env
4. Edite el archivo .env con un editor de texto.

CONFIGURACIONES INCLUIDAS:
───────────────────────────────────────────────────────────
✓ MongoDB Atlas - Conexión a base de datos
✓ AWS S3 - Almacenamiento de archivos
✓ Brevo - Servicio de correo electrónico

NOTAS IMPORTANTES:
───────────────────────────────────────────────────────────
• La aplicación requiere macOS 13.0 o superior.
• Necesita conexión a Internet para funcionar.
• Las credenciales están preconfiguradas para servicios
  de producción.
• No se requieren configuraciones adicionales para el
  funcionamiento básico.

DOCUMENTACIÓN ADICIONAL:
───────────────────────────────────────────────────────────
• README.md - Información general del proyecto
• MANUAL_DE_USUARIO.md - Manual completo de usuario

SOPORTE:
───────────────────────────────────────────────────────────
Para problemas o consultas, consulte la documentación
incluida o contacte al administrador del sistema.

═══════════════════════════════════════════════════════════
EOF
echo -e "${GREEN}   ✅ Guía de instalación creada${NC}"

# Crear un archivo de licencia/términos si no existe
if [ ! -f "${PROJECT_DIR}/LICENSE.txt" ]; then
    echo -e "${YELLOW}📄 Creando archivo de términos de uso...${NC}"
    cat > "${DMG_TEMP_DIR}/package/LICENSE.txt" << 'EOF'
═══════════════════════════════════════════════════════════
  TÉRMINOS DE USO - EDF Catálogo de Tablas
═══════════════════════════════════════════════════════════

SOFTWARE DE USO INTERNO
───────────────────────────────────────────────────────────
Esta aplicación está diseñada para uso interno dentro de
la organización EDF.

CONFIDENCIALIDAD
───────────────────────────────────────────────────────────
Este paquete incluye credenciales de servicios en el
archivo .env. Mantenga estos datos confidenciales y no
los comparta fuera de la organización.

RESPONSABILIDAD
───────────────────────────────────────────────────────────
El uso de esta aplicación es bajo su propia responsabilidad.
Asegúrese de tener backups regulares de sus datos.

═══════════════════════════════════════════════════════════
EOF
fi

# Asegurar permisos correctos y eliminar atributos extendidos
echo -e "${YELLOW}🔒 Configurando permisos y limpiando atributos...${NC}"
chmod -R 755 "${DMG_TEMP_DIR}/package/${APP_NAME}.app"
chmod 644 "${DMG_TEMP_DIR}/package/.env"
chmod 644 "${DMG_TEMP_DIR}/package"/*.md 2>/dev/null || true
chmod 644 "${DMG_TEMP_DIR}/package"/*.txt 2>/dev/null || true

# Eliminar atributos extendidos que pueden causar problemas (como quarantine)
xattr -cr "${DMG_TEMP_DIR}/package" 2>/dev/null || true

# Asegurar permisos explícitos para todos los archivos de texto
find "${DMG_TEMP_DIR}/package" -type f -name "*.md" -exec chmod 644 {} \; 2>/dev/null || true
find "${DMG_TEMP_DIR}/package" -type f -name "*.txt" -exec chmod 644 {} \; 2>/dev/null || true

echo -e "${GREEN}   ✅ Permisos y atributos configurados${NC}"

# Crear imagen DMG inicial sin el enlace (usando srcfolder)
echo -e "${YELLOW}💿 Creando imagen DMG...${NC}"

# Crear DMG inicial con todos los archivos excepto el enlace
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "${DMG_TEMP_DIR}/package" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDRW \
               "${DMG_TEMP_DIR}/temp.dmg" > /dev/null

# Montar el DMG para agregar el enlace a Aplicaciones
echo -e "${YELLOW}📂 Montando DMG para agregar enlace a Aplicaciones...${NC}"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TEMP_DIR}/temp.dmg" 2>/dev/null | egrep '^/dev/' | sed 1q | awk '{print $1}')

if [ -z "${DEVICE}" ]; then
    echo -e "${RED}   ❌ Error: No se pudo montar el DMG${NC}"
    exit 1
fi

# Esperar a que se monte completamente
sleep 3

# Obtener el punto de montaje - usar múltiples métodos
VOLUME=$(hdiutil info | grep "${DEVICE}" | grep "/Volumes" | awk '{$1=$2=$3=""; print $0}' | sed 's/^ *//' | head -1)

# Si no se encontró, intentar otro método
if [ -z "${VOLUME}" ] || [ ! -d "${VOLUME}" ]; then
    # Buscar por nombre del volumen
    for vol_path in /Volumes/*; do
        if [ -d "$vol_path" ] && mountpoint -q "$vol_path" 2>/dev/null; then
            VOLUME_NAME=$(diskutil info "$vol_path" 2>/dev/null | grep "Volume Name" | awk -F': ' '{print $2}')
            if [ "$VOLUME_NAME" = "${APP_NAME}" ]; then
                VOLUME="$vol_path"
                break
            fi
        fi
    done
fi

# Si aún no se encontró, usar el último volumen montado
if [ -z "${VOLUME}" ] || [ ! -d "${VOLUME}" ]; then
    VOLUME=$(ls -td /Volumes/*/ 2>/dev/null | head -1 | sed 's|/$||')
fi

if [ -z "${VOLUME}" ] || [ ! -d "${VOLUME}" ]; then
    echo -e "${RED}   ❌ Error: No se pudo obtener el punto de montaje${NC}"
    echo -e "${YELLOW}   Intentando listar volúmenes montados...${NC}"
    ls -la /Volumes/ 2>/dev/null || true
    hdiutil detach "${DEVICE}" > /dev/null 2>&1 || true
    exit 1
fi

echo -e "${GREEN}   ✅ DMG montado en: ${VOLUME}${NC}"

if [ -n "${VOLUME}" ] && [ -d "${VOLUME}" ]; then
    echo -e "${YELLOW}📂 Agregando enlace a carpeta Aplicaciones...${NC}"
    
    # Eliminar cualquier enlace anterior
    rm -f "${VOLUME}/Aplicaciones" 2>/dev/null || true
    
    # Crear enlace simbólico a Aplicaciones en el volumen montado
    if ln -s /Applications "${VOLUME}/Aplicaciones" 2>/dev/null; then
        echo -e "${GREEN}   ✅ Enlace simbólico creado${NC}"
        
        # Intentar crear también un alias de Finder (más visible en Finder)
        # Los alias de Finder son archivos especiales que el Finder muestra mejor
        osascript <<EOF > /dev/null 2>&1 || true
tell application "Finder"
    try
        set appsFolder to folder "Applications" of startup disk
        set volFolder to disk "${APP_NAME}"
        make alias file to appsFolder at volFolder
        set name of result to "Aplicaciones"
        -- Eliminar el enlace simbólico anterior si existe
        try
            delete POSIX file ("${VOLUME}/Aplicaciones")
        end try
    on error
        -- Si falla el alias, dejar el enlace simbólico
    end try
end tell
EOF
        echo -e "${GREEN}   ✅ Intentando crear alias de Finder...${NC}"
    else
        echo -e "${RED}   ❌ No se pudo crear el enlace a Aplicaciones${NC}"
    fi
    
    # Verificar que existe (enlace o alias)
    if [ -e "${VOLUME}/Aplicaciones" ]; then
        echo -e "${GREEN}   ✅ Carpeta Aplicaciones presente y accesible${NC}"
        ls -l "${VOLUME}/Aplicaciones" 2>/dev/null || true
    else
        echo -e "${RED}   ❌ Error: Carpeta Aplicaciones no encontrada${NC}"
    fi
    
    # Limpiar atributos extendidos del volumen montado
    echo -e "${YELLOW}🧹 Configurando permisos y limpiando atributos...${NC}"
    xattr -cr "${VOLUME}" 2>/dev/null || true
    
    # Asegurar permisos de lectura para todos los usuarios
    chmod -R a+r "${VOLUME}" 2>/dev/null || true
    
    # Asegurar permisos correctos para directorios y archivos
    find "${VOLUME}" -type d -exec chmod 755 {} \; 2>/dev/null || true
    find "${VOLUME}" -type f \( -name "*.md" -o -name "*.txt" \) -exec chmod 644 {} \; 2>/dev/null || true
    
    # Restaurar permisos de ejecución para la app
    if [ -d "${VOLUME}/${APP_NAME}.app" ]; then
        chmod -R 755 "${VOLUME}/${APP_NAME}.app" 2>/dev/null || true
    fi
    # Verificar que el enlace esté presente antes de configurar el layout
    if [ -L "${VOLUME}/Aplicaciones" ]; then
        # Configurar el layout de la ventana del Finder
        echo -e "${YELLOW}🎨 Configurando layout del DMG...${NC}"
        
        # Usar osascript para configurar el layout del Finder
        # Esperar un momento para que Finder reconozca el enlace
        sleep 1
        
        osascript <<EOF > /dev/null 2>&1 || true
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 920, 420}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        try
            -- Asegurar que todos los items visibles estén posicionados
            set position of item "${APP_NAME}.app" of container window to {160, 205}
        on error
        end try
        try
            -- Forzar que el enlace Aplicaciones sea visible
            set position of item "Aplicaciones" of container window to {360, 205}
        on error errMsg
            -- Si falla, intentar con el nombre exacto
            try
                set position of item "Aplicaciones" of container window to {360, 205}
            end try
        end try
        try
            set position of item "INSTALACION.txt" of container window to {160, 100}
            set position of item "README.md" of container window to {260, 100}
            set position of item "MANUAL_DE_USUARIO.md" of container window to {360, 100}
        on error
        end try
        -- Actualizar la vista para forzar la actualización
        close
        delay 0.5
        open
        update without registering applications
        delay 1.5
        close
        delay 0.5
    end tell
end tell
EOF
        echo -e "${GREEN}   ✅ Layout configurado${NC}"
    else
        echo -e "${YELLOW}   ⚠️  No se configuró el layout (el enlace no existe)${NC}"
    fi
    
    # Forzar sincronización
    sync
    sleep 1
fi

# Desmontar
hdiutil detach "${DEVICE}" > /dev/null 2>&1 || true
sleep 1

# Convertir a formato de solo lectura comprimido
echo -e "${YELLOW}🗜️  Comprimiendo DMG...${NC}"
hdiutil convert "${DMG_TEMP_DIR}/temp.dmg" \
                -format UDZO \
                -imagekey zlib-level=9 \
                -o "${DMG_FILE}" > /dev/null

# Eliminar atributos extendidos del DMG final
echo -e "${YELLOW}🧹 Limpiando atributos extendidos del DMG...${NC}"
xattr -cr "${DMG_FILE}" 2>/dev/null || true

# Limpiar
echo -e "${YELLOW}🧹 Limpiando archivos temporales...${NC}"
rm -rf "${DMG_TEMP_DIR}"
echo -e "${GREEN}   ✅ Archivos temporales eliminados${NC}"

# Verificar que el DMG se creó correctamente
if [ -f "${DMG_FILE}" ]; then
    DMG_SIZE=$(du -h "${DMG_FILE}" | cut -f1)
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   ✅ DMG creado exitosamente${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}📦 Archivo: ${DMG_FILE}${NC}"
    echo -e "${GREEN}📊 Tamaño: ${DMG_SIZE}${NC}"
    echo ""
    echo -e "${YELLOW}📋 Contenido del DMG:${NC}"
    echo "   • ${APP_NAME}.app"
    echo "   • Aplicaciones (enlace para arrastrar la app)"
    echo "   • .env (credenciales de servicios)"
    echo "   • README.md"
    echo "   • MANUAL_DE_USUARIO.md"
    echo "   • INSTALACION.txt"
    echo ""
    echo -e "${BLUE}💡 Para probar el DMG:${NC}"
    echo "   open ${DMG_FILE}"
    echo ""
else
    echo -e "${RED}❌ Error: No se pudo crear el archivo DMG${NC}"
    exit 1
fi

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

