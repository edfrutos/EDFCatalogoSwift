#!/usr/bin/env swift

import Foundation
import CryptoKit

// Hash almacenado en MongoDB
let storedHash = "i/GsYhUDn5BCsUVXZoVJPaDYWvlN4Lyg/LOLSCggEjs="

// Contraseñas comunes para probar
let commonPasswords = [
    "admin123",
    "Admin123",
    "admin",
    "password",
    "12345678",
    "edf123",
    "EDF123",
    "administrador"
]

print("🔍 Analizando hash: \(storedHash)")
print("")

// Decodificar Base64 para ver el hash raw
if let hashData = Data(base64Encoded: storedHash) {
    print("📊 Hash decodificado (hex): \(hashData.map { String(format: "%02x", $0) }.joined())")
    print("📊 Longitud del hash: \(hashData.count) bytes")
    print("")
    
    // Identificar tipo de hash por longitud
    switch hashData.count {
    case 16:
        print("💡 Posible algoritmo: MD5 (16 bytes)")
    case 20:
        print("💡 Posible algoritmo: SHA1 (20 bytes)")
    case 32:
        print("💡 Posible algoritmo: SHA256 (32 bytes)")
    case 48:
        print("💡 Posible algoritmo: SHA384 (48 bytes)")
    case 64:
        print("💡 Posible algoritmo: SHA512 (64 bytes)")
    default:
        print("⚠️  Longitud no estándar: \(hashData.count) bytes")
    }
    print("")
}

print("🧪 Probando contraseñas comunes con diferentes algoritmos...")
print("")

for password in commonPasswords {
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔑 Probando: '\(password)'")
    print("")
    
    guard let passwordData = password.data(using: .utf8) else { continue }
    
    // SHA256
    let sha256Hash = SHA256.hash(data: passwordData)
    let sha256Data = Data(sha256Hash)
    let sha256Base64 = sha256Data.base64EncodedString()
    print("   SHA256: \(sha256Base64)")
    if sha256Base64 == storedHash {
        print("   ✅ ¡COINCIDE! Algoritmo: SHA256")
    }
    
    // SHA512
    let sha512Hash = SHA512.hash(data: passwordData)
    let sha512Data = Data(sha512Hash)
    let sha512Base64 = sha512Data.base64EncodedString()
    print("   SHA512: \(sha512Base64.prefix(40))...")
    if sha512Base64 == storedHash {
        print("   ✅ ¡COINCIDE! Algoritmo: SHA512")
    }
    
    // SHA384
    let sha384Hash = SHA384.hash(data: passwordData)
    let sha384Data = Data(sha384Hash)
    let sha384Base64 = sha384Data.base64EncodedString()
    print("   SHA384: \(sha384Base64.prefix(40))...")
    if sha384Base64 == storedHash {
        print("   ✅ ¡COINCIDE! Algoritmo: SHA384")
    }
    
    // HMAC-SHA256 con claves comunes
    let commonKeys = ["secret", "key", "edf", "admin", "password", ""]
    for key in commonKeys {
        if let keyData = key.data(using: .utf8) {
            let hmac = HMAC<SHA256>.authenticationCode(for: passwordData, using: SymmetricKey(data: keyData))
            let hmacData = Data(hmac)
            let hmacBase64 = hmacData.base64EncodedString()
            if hmacBase64 == storedHash {
                print("   ✅ ¡COINCIDE! Algoritmo: HMAC-SHA256 con clave: '\(key)'")
            }
        }
    }
    
    print("")
}

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("💡 Sugerencias:")
print("1. Si ninguna coincide, la contraseña podría ser diferente")
print("2. Podría usar un salt almacenado en otro lugar")
print("3. Podría ser un algoritmo personalizado")
print("")
print("🔧 Solución alternativa:")
print("   Actualiza el Password en MongoDB a 'admin123' (texto plano)")
print("   y modifica el código para NO hashear la contraseña")
