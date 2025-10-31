#!/bin/bash

# Script para eliminar el DMG con credenciales del historial de git

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  ADVERTENCIA: Este script eliminará el DMG del historial de git${NC}"
echo -e "${YELLOW}⚠️  Esto requiere un force push después de la limpieza${NC}"
echo ""
echo -e "${GREEN}Procediendo automáticamente...${NC}"

echo -e "${YELLOW}🧹 Limpiando historial de git...${NC}"

# Crear backup del branch actual
BACKUP_BRANCH="backup-before-dmg-cleanup-$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}📦 Creando backup branch: ${BACKUP_BRANCH}${NC}"
git branch "$BACKUP_BRANCH"

# Eliminar el DMG del historial usando git filter-branch
echo -e "${YELLOW}🗑️  Eliminando dist/EDFCatalogoSwift_v1.0.dmg del historial...${NC}"
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch dist/EDFCatalogoSwift_v1.0.dmg" \
  --prune-empty --tag-name-filter cat -- --all

# Limpiar referencias y optimizar
echo -e "${YELLOW}🧹 Limpiando referencias...${NC}"
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""
echo -e "${YELLOW}📋 Próximos pasos:${NC}"
echo "1. Verificar el historial: git log --oneline --all"
echo "2. Si todo está bien, hacer force push: git push --force origin main"
echo "3. (Opcional) Eliminar backup: git branch -D $BACKUP_BRANCH"
echo ""
echo -e "${RED}⚠️  IMPORTANTE: Notifica a colaboradores para que actualicen sus repositorios${NC}"

