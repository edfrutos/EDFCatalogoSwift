#!/bin/bash
# Script: find_incomplete_catalogs.sh
# Busca construcciones de Catalog( sin createdAt o updatedAt y muestra archivo + línea.

set -euo pipefail

echo "🔍 Buscando construcciones 'Catalog(' sin 'createdAt' o 'updatedAt'..."
echo

# Verificación rápida de pcregrep
if ! command -v pcregrep >/dev/null 2>&1; then
  echo "❌ pcregrep no está instalado. Instálalo con 'brew install pcre' y vuelve a ejecutar."
  exit 2
fi

# Extraemos todos los bloques Catalog(...) en modo multilínea (-M) con número de línea (-n)
# Cada MATCH empieza con: RUTA/archivo.swift:LINEA:... (línea de cabecera de pcregrep)
pcregrep -nM 'Catalog[[:space:]]*\((.|\n)*?\)' Sources 2>/dev/null | /usr/bin/awk '
BEGIN {
  header = ""; block = ""; found = 0;
}

# Una nueva coincidencia empieza en una línea con formato "ruta:linea:..."
/^[^:]+:[0-9]+:/ {
  # Si ya teníamos un bloque acumulado, procesarlo antes de empezar el nuevo
  if (block != "") {
    process_block(header, block);
    block = "";
  }
  header = $0;
  block  = $0 "\n";
  next;
}

# Continuación del bloque actual
{
  block = block $0 "\n";
}

# Al finalizar, procesamos el último bloque si existe
END {
  if (block != "") {
    process_block(header, block);
  }
  if (found == 0) {
    print "✅ No se han encontrado inicializaciones de Catalog sin createdAt/updatedAt.";
  } else {
    exit 1;
  }
}

# Función para procesar un bloque, verificando la presencia de createdAt y updatedAt
function process_block(h, b,    parts, n, file, line, hasCreated, hasUpdated, outHeader) {
  hasCreated = (b ~ /createdAt:/);
  hasUpdated = (b ~ /updatedAt:/);

  if (!hasCreated || !hasUpdated) {
    # h viene como "ruta/archivo.swift:NUM:..."
    n = split(h, parts, ":");
    if (n >= 2) {
      file = parts[1];
      line = parts[2];
      outHeader = "⚠️  Falta algún campo en: " file " (línea " line ")";
    } else {
      outHeader = "⚠️  Falta algún campo en: (no se pudo parsear cabecera)";
    }
    print outHeader;
    print "-------------------------------------------";
    print b;
    print "-------------------------------------------";
    found = 1;  # GLOBAL
  }
}
'

echo
echo "✅ Búsqueda completada."
