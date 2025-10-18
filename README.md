# EDF Catálogo de Tablas - Aplicación nativa para macOS

Esta aplicación nativa para macOS permite gestionar catálogos de tablas con integración a MongoDB Atlas y AWS S3 para el almacenamiento de archivos multimedia.

## Características

- Interfaz nativa para macOS usando SwiftUI
- Autenticación de usuarios
- Gestión de catálogos (crear, editar, visualizar)
- Gestión de filas y columnas en catálogos
- Soporte para archivos multimedia (imágenes, documentos, videos)
- Integración con AWS S3 para almacenamiento de archivos
- Integración con MongoDB Atlas para almacenamiento de datos

## Requisitos

- macOS 12.0 o superior
- Xcode 13.0 o superior (para compilar)
- Swift 5.5 o superior

## Configuración del proyecto

1. Clona el repositorio:
   ```
   git clone https://github.com/yourusername/edf_catalogotablas_macOS.git
   cd edf_catalogotablas_macOS/EDFCatalogoSwift
   ```

2. Instala las dependencias:
   ```
   swift package resolve
   ```

3. Compila el proyecto:
   ```
   swift build
   ```

## Compilación y empaquetado

Para crear un archivo `.app` ejecutable desde Finder, utiliza el script de compilación incluido:

```
./build-macos.sh
```

Este script realizará las siguientes acciones:
- Compilar el proyecto en modo release
- Crear la estructura de directorios para la aplicación macOS
- Copiar el ejecutable y los recursos necesarios
- Crear el icono de la aplicación a partir del logo
- Firmar la aplicación (firma ad-hoc)
- Quitar atributos de cuarentena

La aplicación compilada estará disponible en `bin/EDF Catálogo de Tablas.app`.

## Credenciales de prueba

Para probar la aplicación, puedes utilizar las siguientes credenciales:

- **Email**: test@example.com
- **Contraseña**: password

## Estructura del proyecto

- `Sources/App`: Punto de entrada de la aplicación
- `Sources/Models`: Modelos de datos
- `Sources/Views`: Vistas de la interfaz de usuario
- `Sources/Services`: Servicios para MongoDB, S3 y Keychain
- `Sources/Utilities`: Utilidades y helpers
- `Resources`: Recursos como imágenes y archivos de configuración

## Configuración de MongoDB Atlas

La aplicación está configurada para conectarse a MongoDB Atlas. Los parámetros de conexión están definidos en `Sources/Services/MongoService.swift`.

## Configuración de AWS S3

La aplicación está configurada para utilizar AWS S3 para el almacenamiento de archivos. Los parámetros de conexión están definidos en `Sources/Services/S3Service.swift`.

## Licencia

Este proyecto está licenciado bajo la licencia MIT. Consulta el archivo LICENSE para más detalles.
