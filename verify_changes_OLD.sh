#!/usr/bin/env bash
set -euo pipefail

ROOT="Sources"

# Utilidad: grep recursivo con soporte para regex extendido
gr() {
  # macOS grep es BSD; -E es ERE; -R recursivo; -n número de línea; -I ignora binarios
  grep -R -nI -E "$1" "$ROOT" || true
}

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; }

# 1) MainView usa authViewModel.signOut()
# Permitimos: dentro de Task { await ... }, con/ sin await, con espacios y saltos de línea.
if gr 'authViewModel[[:space:]]*\.[[:space:]]*signOut[[:space:]]*\(' | grep 'Views/MainView.swift' >/dev/null; then
  pass "MainView usa authViewModel.signOut()"
else
  fail "MainView NO usa authViewModel.signOut()"
fi

# 2) LoginView usa authViewModel.signIn(email:password:)
# Permitimos presencia de try/await y saltos de línea
if gr 'authViewModel[[:space:]]*\.[[:space:]]*signIn[[:space:]]*\([[:space:]]*email[[:space:]]*:' | grep 'Views/LoginView.swift' >/dev/null; then
  pass "LoginView usa authViewModel.signIn(email:password:)"
else
  fail "LoginView NO usa authViewModel.signIn(email:password:)"
fi

# 3) ProfileView estructura básica
if gr 'struct[[:space:]]+ProfileView' >/dev/null && gr 'VStack[[:space:]]*\(' | grep 'Views/ProfileView.swift' >/dev/null; then
  pass "ProfileView usa VStack"
else
  fail "ProfileView NO usa VStack"
fi

# 4) Modelos de catálogos
if gr '\bstruct[[:space:]]+RowFiles\b' >/dev/null; then pass "Existe struct RowFiles"; else fail "No existe struct RowFiles"; fi
if gr '\bstruct[[:space:]]+CatalogRow\b' | grep -E 'files[[:space:]]*:' >/dev/null; then pass "CatalogRow tiene 'files'"; else fail "CatalogRow NO tiene 'files'"; fi
if gr '\bstruct[[:space:]]+CatalogRow\b' | grep -E 'createdAt[[:space:]]*:' >/dev/null; then pass "CatalogRow tiene 'createdAt'"; else fail "CatalogRow NO tiene 'createdAt'"; fi
if gr '\bstruct[[:space:]]+CatalogRow\b' | grep -E 'updatedAt[[:space:]]*:' >/dev/null; then pass "CatalogRow tiene 'updatedAt'"; else fail "CatalogRow NO tiene 'updatedAt'"; fi

# 5) FileType único y con casos requeridos
FT_DECLS=$(gr 'enum[[:space:]]+FileType[[:space:]]*:[^$]+' | wc -l | tr -d ' ')
if [ "$FT_DECLS" = "1" ]; then pass "Solo hay 1 definición de FileType (sin duplicados)"; else fail "Hay $FT_DECLS definiciones de FileType (debe ser 1)"; fi
for CASE in image document multimedia pdf; do
  if gr "enum[[:space:]]+FileType" | grep -E "\b$CASE\b" >/dev/null; then
    true
  else
    fail "FileType NO contiene caso $CASE"
  fi
done
pass "FileType contiene casos image/document/multimedia/pdf"

# 6) Solo hay 1 S3Service
S3_DECLS=$(gr 'class[[:space:]]+S3Service\b|actor[[:space:]]+S3Service\b|struct[[:space:]]+S3Service\b' | wc -l | tr -d ' ')
if [ "$S3_DECLS" = "1" ]; then pass "Solo hay 1 S3Service (sin duplicados)"; else fail "Hay $S3_DECLS definiciones de S3Service (debe ser 1)"; fi

# 7) updateCatalog(): exactamente 1 definición (en Services)
UPD_COUNT=$(gr 'func[[:space:]]+updateCatalog[[:space:]]*\(' | wc -l | tr -d ' ')
if [ "$UPD_COUNT" = "1" ]; then pass "Hay 1 definición de updateCatalog()"; else fail "Hay $UPD_COUNT definiciones de updateCatalog() (debe ser 1)"; fi

# 8) MongoService importa NIO
if gr '^import[[:space:]]+NIO\b' | grep 'Services/MongoService.swift' >/dev/null; then
  pass "MongoService importa NIO"
else
  fail "MongoService NO importa NIO"
fi

# 9) catalogsCollection(): async throws y llama a try await connectIfNeeded()
if gr 'func[[:space:]]+catalogsCollection[[:space:]]*\([^\)]*\)[[:space:]]*async[[:space:]]+throws' >/dev/null; then
  pass "catalogsCollection() es async throws"
else
  fail "catalogsCollection() no es async throws"
fi
if gr 'func[[:space:]]+catalogsCollection[^{]+{[^}]*try[[:space:]]+await[[:space:]]+connectIfNeeded\(\)' >/dev/null; then
  pass "catalogsCollection() llama try await connectIfNeeded()"
else
  fail "catalogsCollection() NO llama try await connectIfNeeded()"
fi

# 10) createdAt/updatedAt presentes al construir Catalog
if gr 'Catalog\([^\)]*createdAt:[^,]+,[^)]*updatedAt:' >/dev/null; then
  pass "Todas las construcciones de Catalog incluyen createdAt/updatedAt"
else
  fail "Falta createdAt/updatedAt en alguna construcción de Catalog"
fi

# 11) BSONDocument seguro (sin el patrón conflictivo)
if gr 'BSONDocument\([[:space:]]*row\.data\.map' >/dev/null; then
  fail "Se encontró un patrón conflictivo de BSONDocument(row.data...)"
else
  pass "No se encontraron patrones conflictivos de BSONDocument(row.data...)"
fi

# 12) CatalogDetailView maneja .pdf
if gr 'switch[[:space:]]*\(?fileType\)?[[:space:]]*{' | grep 'Views/CatalogDetailView.swift' >/dev/null && \
   gr 'case[[:space:]]*\.pdf' | grep 'Views/CatalogDetailView.swift' >/dev/null; then
  pass "CatalogDetailView incluye case .pdf en los switch"
else
  fail "CatalogDetailView NO incluye case .pdf en los switch"
fi

# 13) Un único @main
MAIN_COUNT=$(gr '^@main' | wc -l | tr -d ' ')
if [ "$MAIN_COUNT" = "1" ]; then pass "Solo hay un @main en todo el proyecto"; else fail "Hay $MAIN_COUNT @main en el proyecto (debe ser 1)"; fi
