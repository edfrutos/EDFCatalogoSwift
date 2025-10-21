#!/usr/bin/env swift

import Foundation

// Leer .env
var env = ProcessInfo.processInfo.environment
let envPath = "/Users/edefrutos/__Proyectos/EDFCatalogoSwift/.env"

if let text = try? String(contentsOfFile: envPath, encoding: .utf8) {
    print("📄 Leyendo .env desde: \(envPath)")
    for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = raw.trimmingCharacters(in: .whitespaces)
        guard !line.isEmpty, !line.hasPrefix("#"), let eq = line.firstIndex(of: "=") else { continue }
        let k = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
        let v = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
        if !k.isEmpty { env[k] = v }
    }
}

print("\n🔧 Configuración S3:")
print("  - AWS_ACCESS_KEY_ID: \(env["AWS_ACCESS_KEY_ID"]?.prefix(10) ?? "NO CONFIGURADO")...")
print("  - AWS_SECRET_ACCESS_KEY: \(env["AWS_SECRET_ACCESS_KEY"]?.prefix(10) ?? "NO CONFIGURADO")...")
print("  - AWS_REGION: \(env["AWS_REGION"] ?? "NO CONFIGURADO")")
print("  - S3_BUCKET_NAME: \(env["S3_BUCKET_NAME"] ?? "NO CONFIGURADO")")
print("  - USE_S3: \(env["USE_S3"] ?? "NO CONFIGURADO")")
