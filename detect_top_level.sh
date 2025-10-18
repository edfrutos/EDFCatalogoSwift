#!/usr/bin/env bash
set -euo pipefail
dir="Sources/EDFCatalogoSwift"

# Busca en todos los .swift del target
find "$dir" -type f -name '*.swift' -print0 \
| xargs -0 -n1 awk '
  BEGIN { depth=0; filename=ARGV[ARGC-1] }
  {
    # elimina comentarios de línea para evitar falsos positivos
    gsub(/\/\/.*/,"",$0)

    # cuenta llaves para saber si estamos a nivel 0
    for (i=1;i<=length($0);i++) {
      c=substr($0,i,1)
      if (c=="{") depth++
      else if (c=="}") depth--
    }

    # línea "limpia" sin espacios iniciales
    line=$0
    sub(/^[ \t\r\n]+/, "", line)

    # patrones peligrosos a nivel 0
    if (depth==0 && line ~ /^(print\(|Task\s*\{|DispatchQueue\.|Timer\.|NSLog\(|FileManager\.default|try\s+|await\s+|let\s+|var\s+|_+\s*=|[A-Za-z_][A-Za-z0-9_]*\s*\()/) {
      printf("%s:%d:%s\n", FILENAME, NR, $0)
    }
  }'
