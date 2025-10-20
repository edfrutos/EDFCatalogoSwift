# URLs Pre-firmadas de S3 - Estado Actual y Soluciones

## 📊 Situación Actual

El visor de archivos funciona correctamente para mostrar información de los archivos, pero **las imágenes/videos no se cargan directamente** en el modal porque el bucket de S3 es privado.

### ✅ Lo que funciona:
- Subida de archivos a S3
- Almacenamiento de URLs en MongoDB  
- Visualización de metadatos (nombre, tipo, URL)
- Botones "Descargar" y "Abrir externamente"
- Detección correcta de tipos de archivo

### ❌ Lo que NO funciona:
- Vista previa de imágenes dentro del modal (da "Access Denied")
- Vista previa de PDFs/videos dentro del modal
- Carga directa de archivos desde URLs de S3 privado

## 🔧 Causa del Problema

Las URLs de S3 almacenadas en MongoDB son URLs públicas (`https://bucket.s3.region.amazonaws.com/key`), pero el bucket está configurado como **privado**. Por lo tanto, cualquier intento de acceder a estas URLs sin autenticación resulta en "Access Denied".

Para acceder a objetos en buckets privados, se necesitan **URLs pre-firmadas** con firma AWS Signature V4, que incluyen:
- Credenciales temporales
- Timestamp de expiración
- Firma HMAC-SHA256 calculada con la clave secreta

## 💡 Soluciones Posibles

### Opción 1: Configurar Bucket como Público (✅ Más Simple)

**Ventajas:**
- Solución inmediata
- No requiere cambios en el código
- Las URLs funcionan directamente

**Desventajas:**
- Los archivos son accesibles públicamente (no recomendado para datos sensibles)

**Cómo hacerlo:**
1. Ve a la consola de AWS S3
2. Selecciona el bucket `edf-catalogo-tablas`
3. Ve a "Permissions" → "Block public access"
4. Desactiva "Block all public access"
5. Agrega una Bucket Policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::edf-catalogo-tablas/*"
    }
  ]
}
```

### Opción 2: Implementar Backend con URLs Pre-firmadas (✅ Más Seguro)

**Ventajas:**
- Control total sobre el acceso
- URLs temporales (expiran después de X segundos/minutos)
- Mantiene el bucket privado

**Desventajas:**
- Requiere un backend (Node.js, Python, etc.)
- Más complejo de implementar

**Arquitectura:**
```
[App Swift] → [Backend API] → [Genera URL pre-firmada] → [S3]
                   ↓
            [Devuelve URL firmada a la app]
```

**Ejemplo de backend (Node.js):**
```javascript
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

app.get('/presign', async (req, res) => {
  const { key } = req.query;
  const url = s3.getSignedUrl('getObject', {
    Bucket: 'edf-catalogo-tablas',
    Key: key,
    Expires: 3600 // 1 hora
  });
  res.json({ url });
});
```

### Opción 3: Implementar Firma AWS v4 en Swift (🔴 Complejo)

**Ventajas:**
- No requiere backend
- Mantiene el bucket privado

**Desventajas:**
- Implementación muy compleja de la firma HMAC-SHA256
- Requiere cálculo de hash canónico, string to sign, etc.
- Propenso a errores

**Estado:** No implementado por complejidad

### Opción 4: Usar AWS Amplify o SDK de AWS completo (⚠️ Alternativa)

**Ventajas:**
- SDK oficial con soporte completo
- Manejo automático de credenciales y firmas

**Desventajas:**
- Dependencias más pesadas
- Requiere configuración adicional

## 📝 Recomendación

Para desarrollo/pruebas: **Opción 1** (hacer el bucket público)
Para producción: **Opción 2** (backend con URLs pre-firmadas)

## 🚀 Próximos Pasos

1. **Corto plazo**: Configurar bucket como público para testing
2. **Mediano plazo**: Implementar backend simple con generación de URLs pre-firmadas
3. **Largo plazo**: Considerar migración a AWS Amplify para manejo completo

## 📚 Referencias

- [AWS S3 Pre-signed URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)
- [AWS Signature Version 4](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html)
- [AWS SDK for Swift](https://github.com/awslabs/aws-sdk-swift)
