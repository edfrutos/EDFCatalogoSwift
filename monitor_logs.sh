#!/bin/bash
echo "Iniciando aplicación y monitoreando logs..."
open "bin/EDF Catálogo de Tablas.app"
sleep 2
echo "=== Logs de la aplicación ==="
log stream --predicate 'eventMessage CONTAINS "EDFCatalogo" OR processImagePath CONTAINS "EDFCatalogoSwift"' --level debug --style compact 2>&1 | head -100
