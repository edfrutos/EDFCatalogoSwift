#!/usr/bin/env bash
# verify_mongodb_users.sh - Verifica usuarios en MongoDB

set -euo pipefail

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Verificando usuarios en MongoDB...${NC}"
echo ""

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo -e "${GREEN}✅ Variables de entorno cargadas${NC}"
else
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📊 Información de conexión:${NC}"
echo "MONGO_URI: ${MONGO_URI:0:30}..."
echo "MONGO_DB: $MONGO_DB"
echo ""

# Crear script temporal de Swift para verificar usuarios
cat > /tmp/verify_users.swift << 'EOF'
import Foundation
import MongoSwift

@main
struct VerifyUsers {
    static func main() async {
        do {
            // Obtener variables de entorno
            guard let mongoURI = ProcessInfo.processInfo.environment["MONGO_URI"],
                  let dbName = ProcessInfo.processInfo.environment["MONGO_DB"] else {
                print("❌ Variables de entorno no encontradas")
                exit(1)
            }
            
            print("🔌 Conectando a MongoDB...")
            let client = try MongoClient(mongoURI)
            defer { try? client.syncClose() }
            
            let db = client.db(dbName)
            let users = db.collection("users")
            
            print("📊 Consultando usuarios...")
            let cursor = try await users.find()
            let results = try await cursor.toArray()
            
            print("\n✅ Usuarios encontrados: \(results.count)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            for (index, doc) in results.enumerated() {
                print("\n👤 Usuario #\(index + 1):")
                print("   Email: \(doc["email"]?.stringValue ?? "N/A")")
                print("   Name: \(doc["name"]?.stringValue ?? "N/A")")
                print("   IsAdmin: \(doc["isAdmin"]?.boolValue ?? false)")
                print("   Password: \(doc["password"]?.stringValue ?? "N/A")")
                print("   _id: \(doc["_id"]?.objectIDValue?.hex ?? "N/A")")
            }
            
            if results.isEmpty {
                print("\n⚠️  No hay usuarios en la base de datos")
                print("   Necesitas crear al menos un usuario para poder hacer login")
            }
            
        } catch {
            print("❌ Error: \(error)")
            exit(1)
        }
    }
}
EOF

echo -e "${YELLOW}🚀 Ejecutando verificación...${NC}"
echo ""

# Compilar y ejecutar
swift /tmp/verify_users.swift 2>&1 || {
    echo ""
    echo -e "${RED}❌ Error al ejecutar la verificación${NC}"
    echo -e "${YELLOW}Intentando con el proyecto compilado...${NC}"
    
    # Alternativa: usar mongo shell si está disponible
    if command -v mongosh &> /dev/null; then
        echo ""
        echo -e "${YELLOW}📊 Usando mongosh para verificar...${NC}"
        mongosh "$MONGO_URI/$MONGO_DB" --eval "db.users.find().pretty()"
    else
        echo -e "${RED}❌ mongosh no está instalado${NC}"
        echo ""
        echo -e "${YELLOW}💡 Sugerencia: Instala mongosh o verifica manualmente en MongoDB Atlas${NC}"
    fi
}

# Limpiar
rm -f /tmp/verify_users.swift

echo ""
echo -e "${GREEN}✅ Verificación completada${NC}"
