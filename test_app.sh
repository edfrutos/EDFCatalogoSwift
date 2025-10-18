#!/usr/bin/env bash
# test_app.sh - Script de testing exhaustivo para EDFCatalogoSwift

set -Eeuo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Función para imprimir con color
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Función para ejecutar un test
run_test() {
    local test_name=$1
    local test_command=$2
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    print_color "$BLUE" "\n🧪 Test $TESTS_TOTAL: $test_name"
    
    if eval "$test_command"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        print_color "$GREEN" "✅ PASADO"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_color "$RED" "❌ FALLADO"
        return 1
    fi
}

# Función para verificar archivo
check_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        print_color "$GREEN" "  ✓ Archivo existe: $file"
        return 0
    else
        print_color "$RED" "  ✗ Archivo no existe: $file"
        return 1
    fi
}

# Función para verificar directorio
check_dir() {
    local dir=$1
    if [[ -d "$dir" ]]; then
        print_color "$GREEN" "  ✓ Directorio existe: $dir"
        return 0
    else
        print_color "$RED" "  ✗ Directorio no existe: $dir"
        return 1
    fi
}

print_color "$BLUE" "╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║   🧪 Testing Exhaustivo - EDF Catálogo de Tablas         ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝"

echo ""
print_color "$YELLOW" "📋 FASE 1: Verificación de Estructura"
echo ""

# Test 1: Verificar que existe el bundle .app
run_test "Verificar bundle .app existe" \
    'check_dir "bin/EDF Catálogo de Tablas.app"'

# Test 2: Verificar ejecutable
run_test "Verificar ejecutable existe" \
    'check_file "bin/EDF Catálogo de Tablas.app/Contents/MacOS/EDFCatalogoSwift"'

# Test 3: Verificar launcher.sh
run_test "Verificar launcher.sh existe" \
    'check_file "bin/EDF Catálogo de Tablas.app/Contents/MacOS/launcher.sh"'

# Test 4: Verificar Info.plist
run_test "Verificar Info.plist existe" \
    'check_file "bin/EDF Catálogo de Tablas.app/Contents/Info.plist"'

# Test 5: Verificar .env en bundle
run_test "Verificar .env en bundle" \
    'check_file "bin/EDF Catálogo de Tablas.app/Contents/Resources/.env"'

# Test 6: Verificar icono
run_test "Verificar icono de aplicación" \
    'check_file "bin/EDF Catálogo de Tablas.app/Contents/Resources/AppIcon.icns"'

echo ""
print_color "$YELLOW" "📋 FASE 2: Verificación de Permisos"
echo ""

# Test 7: Verificar permisos de ejecución del ejecutable
run_test "Verificar permisos de ejecución del ejecutable" \
    '[[ -x "bin/EDF Catálogo de Tablas.app/Contents/MacOS/EDFCatalogoSwift" ]]'

# Test 8: Verificar permisos de ejecución del launcher
run_test "Verificar permisos de ejecución del launcher" \
    '[[ -x "bin/EDF Catálogo de Tablas.app/Contents/MacOS/launcher.sh" ]]'

echo ""
print_color "$YELLOW" "📋 FASE 3: Verificación de Variables de Entorno"
echo ""

# Test 9: Verificar que .env contiene MONGO_URI
run_test "Verificar MONGO_URI en .env" \
    'grep -q "MONGO_URI=" "bin/EDF Catálogo de Tablas.app/Contents/Resources/.env"'

# Test 10: Verificar que .env contiene MONGO_DB
run_test "Verificar MONGO_DB en .env" \
    'grep -q "MONGO_DB=" "bin/EDF Catálogo de Tablas.app/Contents/Resources/.env"'

# Test 11: Verificar que .env contiene AWS_ACCESS_KEY_ID
run_test "Verificar AWS_ACCESS_KEY_ID en .env" \
    'grep -q "AWS_ACCESS_KEY_ID=" "bin/EDF Catálogo de Tablas.app/Contents/Resources/.env"'

# Test 12: Verificar que .env contiene AWS_SECRET_ACCESS_KEY
run_test "Verificar AWS_SECRET_ACCESS_KEY en .env" \
    'grep -q "AWS_SECRET_ACCESS_KEY=" "bin/EDF Catálogo de Tablas.app/Contents/Resources/.env"'

# Test 13: Verificar que .env contiene BUCKET_NAME
run_test "Verificar BUCKET_NAME en .env" \
    'grep -q "BUCKET_NAME=" "bin/EDF Catálogo de Tablas.app/Contents/Resources/.env"'

echo ""
print_color "$YELLOW" "📋 FASE 4: Ejecución de Aplicación"
echo ""

# Test 14: Ejecutar aplicación y capturar logs
print_color "$BLUE" "\n🧪 Test $((TESTS_TOTAL + 1)): Ejecutar aplicación y verificar logs de inicio"
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# Crear archivo temporal para logs
LOG_FILE=$(mktemp)
echo "  📝 Archivo de logs: $LOG_FILE"

# Ejecutar aplicación en background y capturar logs
print_color "$YELLOW" "  🚀 Lanzando aplicación..."
"bin/EDF Catálogo de Tablas.app/Contents/MacOS/launcher.sh" > "$LOG_FILE" 2>&1 &
APP_PID=$!

echo "  🔢 PID de la aplicación: $APP_PID"

# Esperar un poco para que la aplicación inicie
sleep 3

# Verificar que el proceso sigue ejecutándose
if ps -p $APP_PID > /dev/null; then
    print_color "$GREEN" "  ✓ Aplicación se está ejecutando"
    
    # Mostrar logs capturados
    echo ""
    print_color "$BLUE" "  📄 Logs de inicio:"
    echo "  ────────────────────────────────────────"
    cat "$LOG_FILE" | sed 's/^/  /'
    echo "  ────────────────────────────────────────"
    
    # Verificar logs específicos
    echo ""
    print_color "$BLUE" "  🔍 Verificando logs específicos:"
    
    LOGS_OK=true
    
    if grep -q "📄 Cargando variables de entorno" "$LOG_FILE"; then
        print_color "$GREEN" "  ✓ Variables de entorno cargadas"
    else
        print_color "$RED" "  ✗ No se encontró mensaje de carga de variables"
        LOGS_OK=false
    fi
    
    if grep -q "✅ Variables de entorno cargadas" "$LOG_FILE"; then
        print_color "$GREEN" "  ✓ Confirmación de carga de variables"
    else
        print_color "$RED" "  ✗ No se encontró confirmación de carga"
        LOGS_OK=false
    fi
    
    if grep -q "🚀 Lanzando EDFCatalogoSwift" "$LOG_FILE"; then
        print_color "$GREEN" "  ✓ Aplicación lanzada"
    else
        print_color "$RED" "  ✗ No se encontró mensaje de lanzamiento"
        LOGS_OK=false
    fi
    
    # Esperar un poco más para logs de conexión
    sleep 2
    
    # Capturar logs adicionales del sistema
    print_color "$BLUE" "\n  📊 Logs del sistema (últimos 5 segundos):"
    echo "  ────────────────────────────────────────"
    log show --predicate "process == 'EDFCatalogoSwift'" --style syslog --last 5s 2>&1 | \
        grep -E "(🔌|✅|⚠️|❌|MongoDB|AWS|Error)" | \
        tail -20 | \
        sed 's/^/  /' || echo "  (No se encontraron logs del sistema)"
    echo "  ────────────────────────────────────────"
    
    if $LOGS_OK; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        print_color "$GREEN" "\n✅ PASADO - Aplicación ejecutándose correctamente"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_color "$RED" "\n❌ FALLADO - Algunos logs esperados no se encontraron"
    fi
    
    # Mantener aplicación abierta para inspección manual
    print_color "$YELLOW" "\n  ⏸️  La aplicación permanecerá abierta para inspección manual."
    print_color "$YELLOW" "  📱 Por favor, verifica visualmente:"
    echo "     1. ¿Se muestra la pantalla de login?"
    echo "     2. ¿Los campos de email y contraseña son visibles?"
    echo "     3. ¿El botón 'Entrar' está presente?"
    echo ""
    print_color "$YELLOW" "  Presiona ENTER cuando hayas terminado la inspección visual..."
    read -r
    
    # Cerrar aplicación
    print_color "$YELLOW" "  🛑 Cerrando aplicación..."
    kill $APP_PID 2>/dev/null || true
    sleep 1
    
else
    print_color "$RED" "  ✗ La aplicación no se está ejecutando"
    print_color "$RED" "  📄 Logs capturados:"
    cat "$LOG_FILE" | sed 's/^/  /'
    TESTS_FAILED=$((TESTS_FAILED + 1))
    print_color "$RED" "\n❌ FALLADO"
fi

# Limpiar archivo temporal
rm -f "$LOG_FILE"

echo ""
print_color "$BLUE" "╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║                    📊 RESUMEN DE TESTS                     ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝"
echo ""

print_color "$BLUE" "Total de tests ejecutados: $TESTS_TOTAL"
print_color "$GREEN" "Tests pasados: $TESTS_PASSED"
print_color "$RED" "Tests fallados: $TESTS_FAILED"

echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    print_color "$GREEN" "╔════════════════════════════════════════════════════════════╗"
    print_color "$GREEN" "║          ✅ TODOS LOS TESTS PASARON EXITOSAMENTE          ║"
    print_color "$GREEN" "╚════════════════════════════════════════════════════════════╝"
    exit 0
else
    print_color "$RED" "╔════════════════════════════════════════════════════════════╗"
    print_color "$RED" "║              ❌ ALGUNOS TESTS FALLARON                     ║"
    print_color "$RED" "╚════════════════════════════════════════════════════════════╝"
    exit 1
fi
