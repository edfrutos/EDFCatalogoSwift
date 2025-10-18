#!/usr/bin/env bash
# test_manual.sh - Guía interactiva para testing manual exhaustivo

set -Eeuo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TESTS_TOTAL=0

# Archivo de resultados
RESULTS_FILE="test_results_$(date +%Y%m%d_%H%M%S).md"

# Función para imprimir con color
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Función para registrar resultado
log_result() {
    local test_name=$1
    local status=$2
    local notes=$3
    
    echo "### Test: $test_name" >> "$RESULTS_FILE"
    echo "**Estado:** $status" >> "$RESULTS_FILE"
    echo "**Notas:** $notes" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
}

# Función para ejecutar un test manual
run_manual_test() {
    local test_number=$1
    local test_name=$2
    local instructions=$3
    local expected=$4
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    clear
    print_color "$BLUE" "╔════════════════════════════════════════════════════════════╗"
    print_color "$BLUE" "║          🧪 Testing Manual - Test $test_number/$TESTS_TOTAL           ║"
    print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝"
    echo ""
    print_color "$CYAN" "📝 Test: $test_name"
    echo ""
    print_color "$YELLOW" "📋 Instrucciones:"
    echo "$instructions" | sed 's/^/   /'
    echo ""
    print_color "$YELLOW" "✅ Resultado Esperado:"
    echo "$expected" | sed 's/^/   /'
    echo ""
    print_color "$MAGENTA" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Preguntar resultado
    while true; do
        print_color "$CYAN" "¿El test pasó correctamente? (s/n/skip): "
        read -r response
        
        case $response in
            s|S|si|SI|yes|YES)
                TESTS_PASSED=$((TESTS_PASSED + 1))
                print_color "$GREEN" "✅ Test PASADO"
                log_result "$test_name" "✅ PASADO" "Test completado exitosamente"
                sleep 1
                return 0
                ;;
            n|N|no|NO)
                TESTS_FAILED=$((TESTS_FAILED + 1))
                print_color "$RED" "❌ Test FALLADO"
                echo ""
                print_color "$YELLOW" "Por favor, describe el problema encontrado:"
                read -r problem
                log_result "$test_name" "❌ FALLADO" "$problem"
                sleep 1
                return 1
                ;;
            skip|SKIP)
                TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
                print_color "$YELLOW" "⏭️  Test OMITIDO"
                log_result "$test_name" "⏭️ OMITIDO" "Test omitido por el usuario"
                sleep 1
                return 2
                ;;
            *)
                print_color "$RED" "Respuesta inválida. Por favor responde 's', 'n' o 'skip'"
                ;;
        esac
    done
}

# Inicializar archivo de resultados
cat > "$RESULTS_FILE" << EOF
# 🧪 Resultados de Testing Manual Exhaustivo
**Fecha:** $(date '+%d de %B de %Y, %H:%M')
**Aplicación:** EDF Catálogo de Tablas

---

## 📊 Resumen de Tests

EOF

print_color "$BLUE" "╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║   🧪 Testing Manual Exhaustivo - EDF Catálogo de Tablas  ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝"
echo ""
print_color "$YELLOW" "Este script te guiará a través de 36 tests manuales."
print_color "$YELLOW" "Asegúrate de tener la aplicación abierta antes de continuar."
echo ""
print_color "$CYAN" "Presiona ENTER para comenzar..."
read -r

# Lanzar aplicación
print_color "$YELLOW" "🚀 Lanzando aplicación..."
open "bin/EDF Catálogo de Tablas.app"
sleep 3

# ============================================================================
# FASE 1: AUTENTICACIÓN
# ============================================================================

print_color "$BLUE" "\n╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║              FASE 1: AUTENTICACIÓN (6 tests)              ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝\n"
sleep 2

run_manual_test 1 "Pantalla de Login Visible" \
"1. Observa la ventana de la aplicación
2. Verifica que se muestra la pantalla de login" \
"- Campo de email visible
- Campo de contraseña visible
- Botón 'Entrar' visible
- Botón deshabilitado si los campos están vacíos"

run_manual_test 2 "Validación de Campos Vacíos" \
"1. Deja ambos campos vacíos
2. Intenta hacer clic en el botón 'Entrar'
3. Prueba con solo email lleno
4. Prueba con solo contraseña llena" \
"- Botón 'Entrar' debe estar deshabilitado en todos los casos
- No debe permitir enviar el formulario"

run_manual_test 3 "Login Fallido - Credenciales Inválidas" \
"1. Ingresa email: test@invalid.com
2. Ingresa contraseña: wrongpassword
3. Haz clic en 'Entrar'
4. Observa el resultado" \
"- Debe mostrar un mensaje de error
- El mensaje debe ser claro (ej: 'Credenciales inválidas')
- El usuario debe permanecer en la pantalla de login
- Los campos no deben limpiarse automáticamente"

run_manual_test 4 "Login Exitoso" \
"1. Ingresa email: admin@edf.com
2. Ingresa contraseña: admin123
3. Haz clic en 'Entrar'
4. Espera la respuesta" \
"- Debe mostrar indicador de carga
- Debe autenticar exitosamente
- Debe redirigir a la vista principal
- Debe mostrar el menú lateral con opciones"

# Si el login falló, no continuar
if [ $? -ne 0 ]; then
    print_color "$RED" "\n⚠️  El login falló. No se puede continuar con los tests restantes."
    print_color "$YELLOW" "Por favor, verifica las credenciales y la conexión a MongoDB."
    exit 1
fi

run_manual_test 5 "Cerrar Sesión" \
"1. Busca el menú de usuario o botón de cerrar sesión
2. Haz clic en 'Cerrar sesión'
3. Observa el resultado" \
"- Debe cerrar la sesión
- Debe redirigir a la pantalla de login
- El token debe ser eliminado del Keychain"

run_manual_test 6 "Persistencia de Sesión" \
"1. Inicia sesión nuevamente (admin@edf.com / admin123)
2. Cierra completamente la aplicación (Cmd+Q)
3. Vuelve a abrir la aplicación
4. Observa si mantiene la sesión" \
"- Debe mantener la sesión iniciada
- Debe mostrar directamente la vista principal
- No debe pedir login nuevamente"

# ============================================================================
# FASE 2: GESTIÓN DE CATÁLOGOS
# ============================================================================

print_color "$BLUE" "\n╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║         FASE 2: GESTIÓN DE CATÁLOGOS (6 tests)           ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝\n"
sleep 2

run_manual_test 7 "Listar Catálogos" \
"1. Asegúrate de estar en la vista de Catálogos
2. Observa la lista de catálogos" \
"- Debe mostrar una lista de catálogos
- Cada catálogo debe mostrar nombre y descripción
- Debe haber un indicador de carga mientras se obtienen los datos
- Si no hay catálogos, debe mostrar un mensaje apropiado"

run_manual_test 8 "Crear Nuevo Catálogo" \
"1. Haz clic en el botón 'Nuevo' o '+'
2. Ingresa nombre: 'Test Catálogo $(date +%H%M%S)'
3. Ingresa descripción: 'Catálogo de prueba para testing'
4. Ingresa columnas: 'Nombre, Descripción, Precio'
5. Haz clic en 'Crear'" \
"- Debe abrir un modal o formulario
- Debe crear el catálogo en MongoDB
- El nuevo catálogo debe aparecer en la lista
- El modal debe cerrarse automáticamente"

run_manual_test 9 "Ver Detalles de Catálogo" \
"1. Haz clic en el catálogo que acabas de crear
2. Observa la vista de detalles" \
"- Debe mostrar la información del catálogo
- Debe mostrar las columnas definidas
- Debe mostrar las filas (vacío si es nuevo)
- Debe haber botones de acción (Editar, Eliminar, etc.)"

run_manual_test 10 "Editar Catálogo" \
"1. En la vista de detalles, busca el botón 'Editar Catálogo'
2. Haz clic en él
3. Modifica la descripción
4. Guarda los cambios" \
"- Debe abrir un modal de edición
- Los campos deben estar pre-poblados
- Los cambios deben guardarse en MongoDB
- La vista debe actualizarse con los nuevos datos"

run_manual_test 11 "Eliminar Catálogo" \
"1. En la vista de detalles del catálogo de prueba
2. Busca el botón 'Eliminar'
3. Haz clic en él
4. Confirma la eliminación" \
"- Debe mostrar un diálogo de confirmación
- Debe eliminar el catálogo de MongoDB
- Debe redirigir a la lista de catálogos
- El catálogo eliminado no debe aparecer en la lista"

run_manual_test 12 "Permisos de Catálogos" \
"1. Observa los catálogos visibles
2. Si eres admin, deberías ver todos los catálogos
3. Si eres usuario normal, solo tus catálogos" \
"- El filtrado debe ser correcto según el rol
- Los catálogos de otros usuarios no deben ser visibles (si no eres admin)
- Los botones de acción deben estar disponibles según permisos"

# ============================================================================
# FASE 3: GESTIÓN DE FILAS
# ============================================================================

print_color "$BLUE" "\n╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║           FASE 3: GESTIÓN DE FILAS (5 tests)             ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝\n"
sleep 2

print_color "$YELLOW" "Para estos tests, necesitas un catálogo existente."
print_color "$YELLOW" "Si eliminaste el catálogo de prueba, crea uno nuevo."
print_color "$CYAN" "Presiona ENTER cuando estés listo..."
read -r

run_manual_test 13 "Ver Filas de Catálogo" \
"1. Abre un catálogo existente
2. Observa la tabla de filas" \
"- Debe mostrar una tabla con las columnas del catálogo
- Debe mostrar las filas existentes (o mensaje si está vacío)
- Debe haber scroll si hay muchas filas
- Los datos deben estar correctamente alineados"

run_manual_test 14 "Añadir Nueva Fila" \
"1. En la vista de detalles, haz clic en 'Editar' o 'Añadir Fila'
2. Completa los datos para cada columna
3. Guarda la fila" \
"- Debe abrir un formulario con campos para cada columna
- Debe crear la fila en MongoDB
- La nueva fila debe aparecer en la tabla
- Los datos deben mostrarse correctamente"

run_manual_test 15 "Editar Fila Existente" \
"1. En modo edición, busca el icono de lápiz en una fila
2. Haz clic en él
3. Modifica algunos datos
4. Guarda los cambios" \
"- Los campos deben ser editables
- Los cambios deben guardarse en MongoDB
- La tabla debe actualizarse con los nuevos datos
- No debe haber pérdida de datos"

run_manual_test 16 "Eliminar Fila" \
"1. En modo edición, busca el icono de papelera en una fila
2. Haz clic en él
3. Confirma la eliminación" \
"- Debe pedir confirmación
- Debe eliminar la fila de MongoDB
- La fila debe desaparecer de la tabla
- Las demás filas no deben verse afectadas"

run_manual_test 17 "Validación de Datos en Filas" \
"1. Intenta añadir una fila con campos vacíos
2. Intenta añadir datos inválidos (si aplica)
3. Observa los mensajes de validación" \
"- Debe validar campos requeridos
- Debe mostrar mensajes de error claros
- No debe permitir guardar datos inválidos
- La validación debe ser en tiempo real si es posible"

# ============================================================================
# FASE 4: GESTIÓN DE ARCHIVOS
# ============================================================================

print_color "$BLUE" "\n╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║         FASE 4: GESTIÓN DE ARCHIVOS (4 tests)            ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝\n"
sleep 2

run_manual_test 18 "Subir Archivo a Fila" \
"1. En modo edición de una fila
2. Busca el botón de subir archivo
3. Selecciona un archivo de prueba (imagen, PDF, etc.)
4. Guarda la fila" \
"- Debe abrir un selector de archivos
- Debe subir el archivo a S3
- Debe guardar la URL en MongoDB
- Debe mostrar un icono o indicador del archivo en la fila"

run_manual_test 19 "Ver Archivo" \
"1. Busca una fila con archivo adjunto
2. Haz clic en el icono del archivo" \
"- Debe descargar el archivo de S3
- Debe abrir el archivo con la aplicación predeterminada
- No debe haber errores de permisos
- El archivo debe ser el correcto"

run_manual_test 20 "Eliminar Archivo" \
"1. En modo edición de una fila con archivo
2. Busca la opción de eliminar archivo
3. Confirma la eliminación" \
"- Debe eliminar el archivo de S3
- Debe eliminar la referencia de MongoDB
- El icono del archivo debe desaparecer
- La fila debe seguir existiendo sin el archivo"

run_manual_test 21 "Manejo de Errores de S3" \
"1. Intenta subir un archivo muy grande (>10MB)
2. Observa el comportamiento" \
"- Debe mostrar un mensaje de error claro
- La aplicación no debe bloquearse
- Debe permitir reintentar con otro archivo
- El error debe ser informativo"

# ============================================================================
# FASE 5: PERFIL DE USUARIO
# ============================================================================

print_color "$BLUE" "\n╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║         FASE 5: PERFIL DE USUARIO (2 tests)              ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝\n"
sleep 2

run_manual_test 22 "Ver Perfil" \
"1. Haz clic en 'Perfil' en el menú lateral
2. Observa la información mostrada" \
"- Debe mostrar el email del usuario
- Debe mostrar el rol (admin/usuario)
- Debe mostrar otros campos si existen
- La información debe ser correcta"

run_manual_test 23 "Editar Perfil" \
"1. En la vista de perfil, busca el botón 'Editar'
2. Modifica algún campo editable
3. Guarda los cambios" \
"- Los campos editables deben habilitarse
- Los cambios deben guardarse en MongoDB
- La vista debe actualizarse
- No debe permitir cambiar el email (si aplica)"

# ============================================================================
# FASE 6: ADMINISTRACIÓN
# ============================================================================

print_color "$BLUE" "\n╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║          FASE 6: ADMINISTRACIÓN (2 tests)                 ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝\n"
sleep 2

run_manual_test 24 "Acceso a Panel de Administración" \
"1. Busca la opción 'Administración' en el menú lateral
2. Si eres admin, debería estar visible
3. Si no eres admin, no debería aparecer" \
"- Solo visible para administradores
- Debe abrir el panel de administración
- Debe mostrar opciones administrativas"

run_manual_test 25 "Gestión de Usuarios (si aplica)" \
"1. En el panel de administración
2. Busca la sección de usuarios
3. Verifica las opciones disponibles" \
"- Debe listar usuarios (si aplica)
- Debe permitir crear/editar/eliminar usuarios (si aplica)
- Debe permitir cambiar roles (si aplica)
- Solo accesible para administradores"

# ============================================================================
# FASE 7: NAVEGACIÓN Y UI
# ============================================================================

print_color "$BLUE" "\n╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║          FASE 7: NAVEGACIÓN Y UI (4 tests)                ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝\n"
sleep 2

run_manual_test 26 "Menú Lateral" \
"1. Observa el menú lateral
2. Verifica todos los elementos
3. Haz clic en cada opción" \
"- Catálogos visible
- Perfil visible
- Administración visible (solo admin)
- Cerrar sesión visible
- Navegación funciona correctamente
- Elemento activo resaltado visualmente"

run_manual_test 27 "Navegación entre Vistas" \
"1. Navega: Catálogos → Detalle → Catálogos
2. Navega: Catálogos → Perfil → Catálogos
3. Usa el botón 'Volver' si existe" \
"- Transiciones suaves
- Estado preservado al volver
- Sin errores de navegación
- Breadcrumbs o indicadores de ubicación (si aplica)"

run_manual_test 28 "Responsive Design" \
"1. Redimensiona la ventana a diferentes tamaños
2. Prueba tamaño mínimo (800x600)
3. Prueba tamaño grande (1920x1080)" \
"- UI se adapta correctamente
- Sin elementos cortados
- Scroll funcional cuando es necesario
- Texto legible en todos los tamaños"

run_manual_test 29 "Modo Oscuro/Claro" \
"1. Cambia el tema del sistema (Preferencias → Apariencia)
2. Observa cómo responde la aplicación" \
"- Colores apropiados en modo claro
- Colores apropiados en modo oscuro
- Contraste adecuado en ambos modos
- Transición suave entre modos"

# ============================================================================
# FASE 8: RENDIMIENTO Y ESTABILIDAD
# ============================================================================

print_color "$BLUE" "\n╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║    FASE 8: RENDIMIENTO Y ESTABILIDAD (7 tests)           ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝\n"
sleep 2

run_manual_test 30 "Tiempo de Carga Inicial" \
"1. Cierra la aplicación completamente
2. Cronometra el tiempo desde que la abres hasta que ves la UI
3. Objetivo: < 3 segundos" \
"- Carga rápida
- Sin pantallas en blanco prolongadas
- Indicador de carga si es necesario"

run_manual_test 31 "Tiempo de Autenticación" \
"1. Cierra sesión
2. Cronometra desde clic en 'Entrar' hasta vista principal
3. Objetivo: < 2 segundos" \
"- Respuesta rápida
- Indicador de carga visible
- Sin bloqueos de UI"

run_manual_test 32 "Carga de Lista de Catálogos" \
"1. Navega a la vista de catálogos
2. Observa el tiempo de carga
3. Objetivo: < 1 segundo" \
"- Carga rápida independiente de la cantidad
- Indicador de carga si es necesario
- Sin bloqueos"

run_manual_test 33 "Uso de Memoria" \
"1. Abre Monitor de Actividad (Activity Monitor)
2. Busca 'EDFCatalogoSwift'
3. Observa el uso de memoria durante 5 minutos
4. Objetivo: < 200 MB en uso normal" \
"- Uso de memoria razonable
- Sin incremento constante (memory leaks)
- Memoria estable durante uso normal"

run_manual_test 34 "Manejo de Errores de Red" \
"1. Desconecta el WiFi
2. Intenta cargar catálogos
3. Reconecta el WiFi
4. Intenta de nuevo" \
"- Mensaje de error claro
- Aplicación no se bloquea
- Opción de reintentar
- Recuperación automática al reconectar"

run_manual_test 35 "Prueba de Estrés" \
"1. Crea 5 catálogos rápidamente
2. Añade 10 filas a un catálogo
3. Sube 3 archivos
4. Observa el comportamiento" \
"- Sin crashes
- Sin degradación significativa de rendimiento
- Todas las operaciones completan exitosamente
- UI sigue respondiendo"

run_manual_test 36 "Estabilidad a Largo Plazo" \
"1. Deja la aplicación abierta durante 10 minutos
2. Realiza operaciones variadas intermitentemente
3. Observa si hay problemas" \
"- Sin crashes
- Sin degradación de rendimiento
- Memoria estable
- UI sigue respondiendo correctamente"

# ============================================================================
# RESUMEN FINAL
# ============================================================================

print_color "$BLUE" "\n╔════════════════════════════════════════════════════════════╗"
print_color "$BLUE" "║                  📊 RESUMEN FINAL                          ║"
print_color "$BLUE" "╚════════════════════════════════════════════════════════════╝\n"

# Agregar resumen al archivo
cat >> "$RESULTS_FILE" << EOF

---

## 📊 Resumen Final

**Total de Tests:** $TESTS_TOTAL
**Tests Pasados:** $TESTS_PASSED ✅
**Tests Fallados:** $TESTS_FAILED ❌
**Tests Omitidos:** $TESTS_SKIPPED ⏭️

**Porcentaje de Éxito:** $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%

---

## 🎯 Conclusión

EOF

print_color "$CYAN" "Total de tests ejecutados: $TESTS_TOTAL"
print_color "$GREEN" "Tests pasados: $TESTS_PASSED"
print_color "$RED" "Tests fallados: $TESTS_FAILED"
print_color "$YELLOW" "Tests omitidos: $TESTS_SKIPPED"

echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_color "$GREEN" "╔════════════════════════════════════════════════════════════╗"
    print_color "$GREEN" "║     ✅ TESTING MANUAL COMPLETADO EXITOSAMENTE             ║"
    print_color "$GREEN" "╚════════════════════════════════════════════════════════════╝"
    echo "La aplicación está lista para producción." >> "$RESULTS_FILE"
else
    print_color "$YELLOW" "╔════════════════════════════════════════════════════════════╗"
    print_color "$YELLOW" "║     ⚠️  TESTING COMPLETADO CON ALGUNOS FALLOS            ║"
    print_color "$YELLOW" "╚════════════════════════════════════════════════════════════╝"
    echo "Se encontraron $TESTS_FAILED problemas que deben ser resueltos." >> "$RESULTS_FILE"
fi

echo ""
print_color "$CYAN" "📄 Resultados guardados en: $RESULTS_FILE"
echo ""
print_color "$YELLOW" "Presiona ENTER para finalizar..."
read -r

# Cerrar aplicación
killall EDFCatalogoSwift 2>/dev/null || true

print_color "$GREEN" "✅ Testing manual completado. ¡Gracias!"
