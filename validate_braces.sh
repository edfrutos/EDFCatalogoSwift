#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-Sources}"

echo "🔎 Validando balance de (), {}, [] en '${ROOT}' (por archivo)..."

find "$ROOT" -type f -name "*.swift" \
  -not -path "*/.git/*" \
  -not -path "*/.build/*" \
  -not -path "*/DerivedData/*" \
  -print0 |
while IFS= read -r -d '' file; do
  awk -v file="$file" '
  BEGIN {
    inBlockComment = 0
    inString = 0
    stringDelim = ""     # \" o \047 (comilla simple)
    prevWasBackslash = 0

    top = 0
    hasError = 0
  }

  function push(ch, line, col) { top++; stack[top]=ch; sl[top]=line; sc[top]=col }
  function pop(   ch) { if (top>0) { ch=stack[top]; top--; return ch } return "" }

  {
    line = $0
    n = length(line)
    i = 1
    while (i <= n) {
      c  = substr(line, i, 1)
      cn = (i < n) ? substr(line, i+1, 1) : ""

      # Bloque /* ... */
      if (inBlockComment) {
        if (c=="*" && cn=="/") { inBlockComment=0; i+=2; prevWasBackslash=0; continue }
        i++; prevWasBackslash=0; continue
      }

      # Cadena "..." o '...'
      if (inString) {
        if (c==stringDelim && prevWasBackslash==0) { inString=0; stringDelim="" }
        prevWasBackslash = (c=="\\" ? 1 : 0)
        i++; continue
      }

      # Comentarios
      if (c=="/" && cn=="/") break
      if (c=="/" && cn=="*") { inBlockComment=1; i+=2; prevWasBackslash=0; continue }

      # Inicio de cadenas
      if (c=="\"") { inString=1; stringDelim="\""; prevWasBackslash=0; i++; continue }
      if (c=="\047") { inString=1; stringDelim="\047"; prevWasBackslash=0; i++; continue }

      # Balanceo
      if (c=="(" || c=="{" || c=="[") {
        push(c, NR, i)
      } else if (c==")" || c=="}" || c=="]") {
        open = pop()
        ok = 0
        if (open=="(" && c==")") ok=1
        if (open=="{" && c=="}") ok=1
        if (open=="[" && c=="]") ok=1
        if (!ok) {
          if (open=="") {
            printf("❌ %s:%d:%d: cierre inesperado '%s' (no hay apertura)\n", file, NR, i, c)
          } else {
            # Nota: sl[top+1]/sc[top+1] contienen la ultima apertura extraída
            printf("❌ %s:%d:%d: cierre inesperado '%s'; ultima apertura era '%s' en %d:%d\n",
                   file, NR, i, c, open, sl[top+1], sc[top+1])
          }
          hasError = 1
        }
      }

      prevWasBackslash = 0
      i++
    }
  }

  END {
    if (inString) {
      printf("❌ %s: fin de archivo dentro de cadena %s sin cerrar\n", file, stringDelim)
      hasError = 1
    }
    if (inBlockComment) {
      printf("❌ %s: fin de archivo dentro de comentario /* ... */ sin cerrar\n", file)
      hasError = 1
    }
    while (top > 0) {
      printf("❌ %s:%d:%d: apertura '%s' sin cierre\n", file, sl[top], sc[top], stack[top])
      top--
      hasError = 1
    }
    # Silencioso si OK por archivo (descomenta si quieres ver OKs)
    # if (!hasError) printf("✅ %s: balance correcto\n", file)
  }
  ' "$file"
done | tee /tmp/brace_check.out

if grep -q "❌" /tmp/brace_check.out; then
  echo "⚠️  Revisa los errores arriba. (Un desbalance puede provocar el error de '@main con top-level code')."
  exit 1
else
  echo "✅ Balance correcto de llaves/paréntesis en todos los archivos."
fi
