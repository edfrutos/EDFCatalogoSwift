#!/bin/bash

# Ver logs de la aplicación en tiempo real
echo "📊 Viendo logs de EDFCatalogoSwift..."
echo "Presiona Ctrl+C para salir"
echo ""

# Usar el log de sistema de macOS
log stream --predicate 'process == "EDFCatalogoSwift"' --level debug
