#!/bin/bash

# Compilar y ejecutar la app en segundo plano
swift run EDFCatalogoSwift &

# Esperar un momento para que arranque
sleep 2

# Activar la aplicación para que reciba foco
osascript -e 'tell application "System Events" to set frontmost of first process whose unix id is '"$(pgrep -n EDFCatalogoSwift)"' to true'
