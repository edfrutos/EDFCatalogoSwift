#!/bin/bash

# Script para actualizar contraseñas a SHA256
# Para admin@edf.com: admin123
# Para edfrutos@gmail.com: establecer una nueva

echo "🔐 Actualizando contraseñas en MongoDB..."
echo ""
echo "Opciones:"
echo "1. Calcular hash SHA256 de una contraseña"
echo "2. Actualizar admin@edf.com con admin123 (hasheado)"
echo "3. Actualizar edfrutos@gmail.com con contraseña personalizada"
echo ""
read -p "Elige una opción (1-3): " option

case $option in
  1)
    read -sp "Ingresa la contraseña: " password
    echo ""
    hash=$(echo -n "$password" | shasum -a 256 | awk '{print $1}' | xxd -r -p | base64)
    echo "Hash SHA256 (Base64): $hash"
    ;;
  2)
    hash=$(echo -n "admin123" | shasum -a 256 | awk '{print $1}' | xxd -r -p | base64)
    echo "Hash para admin123: $hash"
    echo ""
    echo "Ejecuta en MongoDB:"
    echo "db.Users.updateOne({Email: 'admin@edf.com'}, {\$set: {Password: '$hash'}})"
    ;;
  3)
    read -sp "Ingresa la nueva contraseña para edfrutos@gmail.com: " password
    echo ""
    hash=$(echo -n "$password" | shasum -a 256 | awk '{print $1}' | xxd -r -p | base64)
    echo "Hash SHA256 (Base64): $hash"
    echo ""
    echo "Ejecuta en MongoDB:"
    echo "db.Users.updateOne({Email: 'edfrutos@gmail.com'}, {\$set: {Password: '$hash'}})"
    ;;
  *)
    echo "Opción inválida"
    ;;
esac
