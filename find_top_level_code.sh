#!/usr/bin/env bash
set -euo pipefail

ROOT="Sources"

echo "🔎 Buscando posibles sentencias a nivel superior (fuera de tipos/funciones) en ${ROOT}..."

find "$ROOT" -type f -name "*.swift" | while read -r f; do
  /usr/bin/perl -ne '
    # Estado por archivo
    our $depth //= 0;
    our $prev_attr //= 0;

    # Copias por línea
    my $raw = $_;
    my $line = $raw;

    # Quitar comentarios de línea //...
    $line =~ s{//.*$}{};

    # Trim
    my $trim = $line; $trim =~ s/^\s+|\s+$//g;

    # Contar llaves de esta línea
    my $opens  = () = $line =~ /{/g;
    my $closes = () = $line =~ /}/g;
    my $depth_before = $depth;

    # ¿Estamos a nivel superior?
    if ($trim ne "" && $depth_before == 0) {
      my $ok = 0;

      # Permitidos a nivel superior
      $ok ||= ($trim =~ /^import\b/);
      $ok ||= ($trim =~ /^@preconcurrency\s+import\b/);
      $ok ||= ($trim =~ /^@main\b/);
      $ok ||= ($trim =~ /^(#if|#endif)\b/);
      $ok ||= ($trim =~ /^(?:public|internal|private|fileprivate)?\s*(struct|class|enum|protocol|extension)\b/);
      $ok ||= ($trim =~ /^(?:public|internal|private|fileprivate)?\s*typealias\b/);
      $ok ||= ($trim =~ /^(?:public|internal|private|fileprivate)?\s*(?:@objc|@available|@frozen|@MainActor|@testable)?\s*func\b/);

      # Propiedades sin inicialización directa (solo la firma)
      $ok ||= ($trim =~ /^(?:public|internal|private|fileprivate)?\s*(?:@StateObject|@EnvironmentObject)?\s*(?:let|var)\b[^{=]*$/);

      # Atributos sueltos que preceden a una declaración en la siguiente línea (los aceptamos)
      if ($trim =~ /^@(objc|available|frozen|MainActor|testable|uncheckedSendable|_cdecl)\b/) {
        $ok = 1;
        $prev_attr = 1;
      } else {
        $prev_attr = 0 unless $trim eq "";
      }

      # Líneas que solo abren bloque
      $ok ||= ($trim =~ /{$/);

      # Reporte si no es OK
      if (!$ok) {
        printf "❌ Top-level en %s:%d: %s", $ARGV, $., $raw;
      }
    }

    # Actualizar profundidad
    $depth += $opens - $closes;

    END {
      # reset por archivo al terminar
      $depth = 0;
      $prev_attr = 0;
    }
  ' "$f"
done
