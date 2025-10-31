# 🔒 Limpieza del Historial de Git - Archivos Sensibles

## ⚠️ IMPORTANTE: Archivos Sensibles Detectados en el Historial

Se han encontrado archivos con información sensible que ya están en el historial del repositorio:

- **test_hash.py** (commit 78f79b3) - Contiene contraseña en texto plano: `"15si34Maf"`
- **fix_passwords.sh** (commit 6083ca7) - Contiene referencias a contraseñas

## 🛡️ Acción Inmediata Requerida

**CAMBIAR LA CONTRASEÑA EXPUESTA INMEDIATAMENTE:**
- Contraseña expuesta: `15si34Maf`
- Cambiar esta contraseña en MongoDB para cualquier usuario que la esté usando

## 📋 Opciones para Limpiar el Historial

### Opción 1: BFG Repo-Cleaner (RECOMENDADO - Más rápido y seguro)

```bash
# 1. Instalar BFG (si no está instalado)
# macOS: brew install bfg

# 2. Clonar un repositorio fresco (solo bare)
cd /tmp
git clone --mirror https://github.com/usuario/repo.git

# 3. Eliminar archivos sensibles
bfg --delete-files test_hash.py repo.git
bfg --delete-files fix_passwords.sh repo.git

# 4. Limpiar referencias
cd repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 5. Forzar push (requiere permisos)
git push --force

# 6. Todos los colaboradores deben clonar de nuevo el repositorio
```

### Opción 2: git filter-branch (Alternativa)

```bash
# Eliminar test_hash.py del historial completo
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch test_hash.py" \
  --prune-empty --tag-name-filter cat -- --all

# Eliminar fix_passwords.sh del historial completo
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch fix_passwords.sh" \
  --prune-empty --tag-name-filter cat -- --all

# Limpiar referencias
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Forzar push (ADVERTENCIA: esto reescribe el historial)
git push --force --all
git push --force --tags
```

### Opción 3: Solo Cambiar Contraseña (Si no puedes limpiar el historial)

Si no puedes limpiar el historial del repositorio:

1. **Cambiar la contraseña inmediatamente** en MongoDB
2. Asegurar que `.gitignore` esté actualizado (✅ ya hecho)
3. Informar a todos los colaboradores sobre la exposición
4. Considerar rotar todas las credenciales relacionadas

## 📝 Después de Limpiar el Historial

1. **Notificar a todos los colaboradores:**
   - Deben clonar el repositorio de nuevo
   - O hacer `git fetch origin && git reset --hard origin/main`

2. **Verificar que los archivos no aparezcan:**
   ```bash
   git log --all --full-history -- test_hash.py
   git log --all --full-history -- fix_passwords.sh
   ```

3. **Asegurar que .gitignore esté actualizado** (✅ ya hecho)

## ⚠️ ADVERTENCIA

- **Nunca** hagas force push a un repositorio compartido sin coordinar con el equipo
- Los colaboradores necesitarán reclonar o resetear sus repositorios locales
- Las copias forkadas también deberán actualizarse
- Si el repositorio está en GitHub/GitLab, considera usar "Protected Branches" después

## 🔐 Mejores Prácticas Futuras

1. ✅ Usar `.env` para credenciales (ya implementado)
2. ✅ No commitear contraseñas en texto plano (ahora protegido con .gitignore)
3. ✅ Usar secretos de GitHub/GitLab para CI/CD
4. ✅ Revisar commits antes de pushear: `git diff --cached`
5. ✅ Usar herramientas como `git-secrets` para prevenir commits accidentales

