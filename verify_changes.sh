#!/usr/bin/env bash
set -euo pipefail

# En macOS (bash 3.2) no existe 'globstar'; tampoco lo necesitamos.
# Activamos solo nullglob si estamos en bash.
if [ -n "${BASH_VERSION-}" ]; then
  shopt -s nullglob || true
fi

OK="✅"; KO="❌"
ROOT="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
SRC="$ROOT/Sources"
export LC_ALL=C

green(){ printf "%b %s\n" "$OK" "$1"; }
red(){   printf "%b %s\n" "$KO" "$1"; }

has_one_definition(){
  local pattern="$1"
  grep -R --include='*.swift' -nE "$pattern" "$SRC" | wc -l | tr -d ' '
}

# 1) MainView usa signOut
if grep -R --include='MainView.swift' -nE 'authViewModel\.(?:signOut\(\)|signOut)\b' "$SRC" >/dev/null; then
  green "MainView usa authViewModel.signOut()"
else
  red "MainView NO usa authViewModel.signOut()"
fi

# 2) LoginView usa signIn
if grep -R --include='LoginView.swift' -nE 'authViewModel\.signIn\s*\(' "$SRC" >/dev/null; then
  green "LoginView usa authViewModel.signIn(email:password:)"
else
  red "LoginView NO usa authViewModel.signIn(email:password:)"
fi

# 3) Existe RowFiles
if grep -R --include='*.swift' -nE '\bstruct\s+RowFiles\b' "$SRC" >/dev/null; then
  green "Existe struct RowFiles"
else
  red "NO existe struct RowFiles"
fi

# 4-6) CatalogRow tiene files/createdAt/updatedAt
CR_FILE="$(grep -R --include='*.swift' -lE '\bstruct\s+CatalogRow\b' "$SRC" | head -n1 || true)"
if [[ -n "${CR_FILE:-}" ]]; then
  ok=true
  grep -nE '\bstruct\s+CatalogRow\b' "$CR_FILE" >/dev/null || ok=false
  grep -nE '\bvar\s+files\s*:\s*RowFiles\b' "$CR_FILE" >/dev/null || ok=false
  grep -nE '\bvar\s+createdAt\s*:\s*Date\b' "$CR_FILE" >/dev/null || ok=false
  grep -nE '\bvar\s+updatedAt\s*:\s*Date\b' "$CR_FILE" >/dev/null || ok=false
  if $ok; then green "CatalogRow tiene 'files', 'createdAt' y 'updatedAt'"; else red "CatalogRow incompleto en ${CR_FILE#"$ROOT/"}"; fi
else
  red "NO se encontró definición de CatalogRow"
fi

# 7) Solo 1 FileType
FT_COUNT="$(has_one_definition '\benum[[:space:]]+FileType\b')"
if [[ "$FT_COUNT" == "1" ]]; then green "Solo hay 1 definición de FileType (sin duplicados)"; else red "Hay $FT_COUNT definiciones de FileType (debe ser 1)"; fi

# 8) FileType contiene image/document/multimedia/pdf
FT_FILE="$(grep -R --include='*.swift' -lE '\benum[[:space:]]+FileType\b' "$SRC" | head -n1 || true)"
if [[ -n "${FT_FILE:-}" ]]; then
  okcases=true
  grep -nE '\bcase\b.*\bimage\b' "$FT_FILE" >/dev/null || okcases=false
  grep -nE '\bcase\b.*\bdocument\b' "$FT_FILE" >/dev/null || okcases=false
  grep -nE '\bcase\b.*\bmultimedia\b' "$FT_FILE" >/dev/null || okcases=false
  grep -nE '\bcase\b.*\bpdf\b' "$FT_FILE" >/dev/null || okcases=false
  $okcases && green "FileType contiene casos image/document/multimedia/pdf" || red "FileType NO contiene todos los casos image/document/multimedia/pdf"
else
  red "No se encontró enum FileType"
fi

# 9) Solo 1 S3Service (class/struct/actor)
S3_COUNT="$(has_one_definition '\b(class|struct|actor)[[:space:]]+S3Service\b')"
if [[ "$S3_COUNT" == "1" ]]; then green "Solo hay 1 S3Service (sin duplicados)"; else red "Hay $S3_COUNT definiciones de S3Service (debe ser 1)"; fi

# 10) updateCatalog() exactamente 1
UPD_COUNT="$(has_one_definition '\bfunc[[:space:]]+updateCatalog\s*\(')"
if [[ "$UPD_COUNT" == "1" ]]; then green "Hay 1 definición de updateCatalog()"
elif [[ "$UPD_COUNT" == "0" ]]; then red "Hay 0 definiciones de updateCatalog() (debe ser 1)"
else red "Hay $UPD_COUNT definiciones de updateCatalog() (debe ser 1)"; fi

# 11) MongoService importa NIO
if grep -R --include='MongoService.swift' -nE '\bimport[[:space:]]+NIO\b' "$SRC" >/dev/null; then
  green "MongoService importa NIO"
else
  red "MongoService NO importa NIO"
fi

# 12) catalogsCollection() es async throws y llama connectIfNeeded()
CC_FILE="$(grep -R --include='*.swift' -lE '\bfunc\s+catalogsCollection\s*\(' "$SRC" | head -n1 || true)"
if [[ -n "${CC_FILE:-}" ]]; then
  if grep -nE '\bfunc\s+catalogsCollection\s*\([^)]*\)\s*(async[[:space:]]+throws|throws[[:space:]]+async|async.*throws)' "$CC_FILE" >/dev/null; then
    green "catalogsCollection() es async throws"
  else
    red "catalogsCollection() no es async throws"
  fi
  if grep -nE 'try[[:space:]]+await[[:space:]]+connectIfNeeded\s*\(' "$CC_FILE" >/dev/null; then
    green "catalogsCollection() llama try await connectIfNeeded()"
  else
    red "catalogsCollection() NO llama try await connectIfNeeded()"
  fi
else
  red "No se halló catalogsCollection()"
fi

# 13) Todos los Catalog(...) incluyen createdAt/updatedAt
if [ -x "$ROOT/find_incomplete_catalogs.sh" ]; then
  # ejecuta y captura salida (sin ocultarla del todo para poder decidir por contenido)
  FIND_OUT="$("$ROOT/find_incomplete_catalogs.sh" 2>&1 || true)"
  if echo "$FIND_OUT" | grep -q 'No se han encontrado inicializaciones de Catalog sin createdAt/updatedAt'; then
    green "Todas las construcciones de Catalog incluyen createdAt/updatedAt"
  else
    red "Alguna construcción de Catalog no incluye createdAt/updatedAt"
    printf "%s\n" "$FIND_OUT" | sed -n '1,200p'
  fi
else
  # Fallback rápido si no existe el script dedicado
  if command -v pcregrep >/dev/null 2>&1; then
    # Busca bloques Catalog(...) multilínea y filtra los que no contengan createdAt/updatedAt
    PCRE_OUT="$(pcregrep -nM 'Catalog[[:space:]]*\((.|\n)*?\)' "$SRC"/*.swift "$SRC"/*/*.swift 2>/dev/null | \
               pcregrep -nMv '(createdAt[[:space:]]*:|updatedAt[[:space:]]*:)' || true)"
    if [ -n "$PCRE_OUT" ]; then
      red "Alguna construcción de Catalog no incluye createdAt/updatedAt"
      printf "%s\n" "$PCRE_OUT" | sed -n '1,200p'
    else
      green "Todas las construcciones de Catalog incluyen createdAt/updatedAt"
    fi
  else
    echo "ℹ️ Aviso: no se encontró $ROOT/find_incomplete_catalogs.sh ni pcregrep; omito este chequeo."
  fi
fi

# 14) No usar patrón conflictivo BSONDocument(row.data.map...)
if grep -R --include='*.swift' -nE 'BSONDocument\s*\(\s*row\.data\.map' "$SRC" >/dev/null; then
  red "Se encontró un patrón conflictivo de BSONDocument(row.data...)"
else
  green "No se encontraron patrones conflictivos de BSONDocument(row.data...)"
fi

# 15) CatalogDetailView incluye case .pdf
if grep -R --include='CatalogDetailView.swift' -nE '\bcase[[:space:]]+\.pdf\b' "$SRC" >/dev/null; then
  green "CatalogDetailView incluye case .pdf en los switch"
else
  red "CatalogDetailView NO incluye case .pdf en los switch"
fi

# 16) Solo un @main
MAIN_COUNT="$(grep -R --include='*.swift' -n '@main' "$SRC" | wc -l | tr -d ' ')"
if [[ "$MAIN_COUNT" == "1" ]]; then green "Solo hay un @main en todo el proyecto"; else red "Hay $MAIN_COUNT ocurrencias de @main (debe haber 1)"; fi

exit 0
