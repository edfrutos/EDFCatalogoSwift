#!/usr/bin/env python3
import hashlib
import base64

password = "15si34Maf"
stored_hash = "JxPT68f4SIXIA9ipmxKvct19jxxK9auK1nvFyAq0wHI="

print("🔍 Probando diferentes métodos de hash:")
print(f"Contraseña: {password}")
print(f"Hash almacenado: {stored_hash}\n")

# Diferentes variaciones
tests = [
    ("SHA256 directo", hashlib.sha256(password.encode()).digest()),
    ("SHA256 doble", hashlib.sha256(hashlib.sha256(password.encode()).digest()).digest()),
    ("SHA256 con salt 'edf'", hashlib.sha256(('edf' + password).encode()).digest()),
    ("SHA256 con salt al final", hashlib.sha256((password + 'edf').encode()).digest()),
    ("SHA256 hex como bytes", base64.b64decode(hashlib.sha256(password.encode()).hexdigest().encode('utf-8'))),
]

for name, hash_bytes in tests:
    try:
        generated = base64.b64encode(hash_bytes).decode()
        match = "✅ MATCH!" if generated == stored_hash else "❌"
        print(f"{match} {name}")
        print(f"   {generated}\n")
    except Exception as e:
        print(f"❌ {name} - Error: {e}\n")

print("\n💡 Si ninguno coincide, puede que el hash se haya generado con otro método")
print("   o que la contraseña tenga espacios/caracteres especiales")
