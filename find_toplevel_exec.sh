#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-Sources}"
echo "🔎 Buscando código ejecutable a NIVEL SUPERIOR en '${ROOT}'…"

find "$ROOT" -type f -name "*.swift" -not -path "*/.build/*" -print0 |
while IFS= read -r -d '' f; do
  awk -v file="$f" '
  BEGIN{
    depth=0; inStr=0; esc=0; inBlk=0;
  }
  function is_exec(line){
    # muy conservador: llamadas foo(…), Task {, Timer.scheduled…, asignaciones simples, etc.
    return (line ~ /[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(/ \
         || line ~ /^(let|var)[[:space:]]+[A-Za-z_]/ \
         || line ~ /(Task|DispatchQueue|Timer\.scheduled|FileManager\.default|NSLog|print)[[:space:]]*\(/)
  }
  {
    s=$0

    # cortar comentarios de línea
    sub(/\/\/.*$/, "", s)

    # procesar char a char para strings, comentarios bloque y llaves
    i=1
    while (i <= length(s)) {
      c=substr(s,i,1); n=(i<length(s)?substr(s,i+1,1):"")
      if (inBlk){
        if (c=="*" && n=="/"){ inBlk=0; i+=2; continue }
        i++; continue
      }
      if (!inStr && c=="/" && n=="*"){ inBlk=1; i+=2; continue }
      if (!inStr && c=="\"" ){ inStr=1; esc=0; i++; continue }
      if (inStr){
        if (c=="\\" && !esc){ esc=1; i++; continue }
        if (c=="\"" && !esc){ inStr=0; i++; continue }
        esc=0; i++; continue
      }
      # fuera de string/comentario: ajusta profundidad
      if (c=="{") depth++
      else if (c=="}" && depth>0) depth--
      i++
    }

    # línea limpiada para evaluar “ejecutable”
    t=s
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
    if (t=="" || inBlk || inStr) next

    # si estamos a profundidad 0, esto es a nivel superior
    if (depth==0 && is_exec(t)) {
      printf("❌ %s:%d: %s\n", file, NR, t)
    }
  }
  ' "$f"
done | tee /tmp/toplevel_exec.out

if grep -q "❌" /tmp/toplevel_exec.out; then
  echo "⚠️  Hay código ejecutable a nivel superior. Mueve esas líneas dentro de un tipo/función."
  exit 1
else
  echo "✅ No hay código ejecutable a nivel superior."
fi
