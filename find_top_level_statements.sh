#!/usr/bin/env bash
set -euo pipefail

ROOT="Sources"
echo "🔎 Buscando sentencias ejecutables a nivel superior en ${ROOT}..."

TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

found=0

# Recorre cada .swift individualmente sin xargs
find "${ROOT}" -type f -name "*.swift" -print0 | while IFS= read -r -d '' file; do
  awk -v file="$file" '
  BEGIN { depth = 0 }
  {
    raw = $0
    line = $0

    # Ignorar comentarios de línea y líneas vacías
    if (line ~ /^[[:space:]]*\/\//) next
    if (line ~ /^[[:space:]]*$/) next

    # Ignorar imports/atributos
    if (line ~ /^[[:space:]]*(@[[:alnum:]_]+[[:space:]]*)*import[[:space:]]+/) next

    # Ignorar declaraciones de tipos/funciones/directivas
    if (line ~ /^[[:space:]]*(public|internal|private|fileprivate)?[[:space:]]*(struct|class|enum|protocol|extension|typealias)\b/) next
    if (line ~ /^[[:space:]]*(public|internal|private|fileprivate)?[[:space:]]*func\b/) next
    if (line ~ /^[[:space:]]*(#if|#endif)\b/) next

    # Si estamos a nivel superior (depth==0), buscar sospechosos
    if (depth == 0) {
      # 1) Llamadas tipo Foo(...)
      if (line ~ /^[[:space:]]*[[:alpha:]_][[:alnum:]_]*[[:space:]]*\([^{}]*\)[[:space:]]*$/) {
        printf "❌ Top-level en %s:%d: %s\n", file, NR, raw
      }
      # 2) let/var con asignación (no apertura de bloque)
      else if (line ~ /^[[:space:]]*(let|var)[[:space:]]+[[:alpha:]_][[:alnum:]_]*[[:space:]]*=[[:space:]]*[^ \t{][^{};]*$/) {
        printf "❌ Top-level en %s:%d: %s\n", file, NR, raw
      }
      # 3) Llamadas típicas ejecutables
      else if (line ~ /^[[:space:]]*(print|NSLog|Task|DispatchQueue|Timer\.scheduled|FileManager\.default|Mongo(Client|Swift))[[:space:]]*\(/) {
        printf "❌ Top-level en %s:%d: %s\n", file, NR, raw
      }
    }

    # Actualizar profundidad con llaves
    opens  = gsub(/{/, "{", raw)
    closes = gsub(/}/, "}", raw)
    depth += opens
    depth -= closes
    if (depth < 0) depth = 0
  }
  ' "$file" >> "$TMP_OUT"
done

if [[ -s "$TMP_OUT" ]]; then
  cat "$TMP_OUT"
  exit 1
else
  echo "✅ No se han detectado sentencias ejecutables a nivel superior."
fi
