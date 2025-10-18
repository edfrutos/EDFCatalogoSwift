# Manual de Usuario - EDF Catálogo de Tablas

## Introducción

EDF Catálogo de Tablas es una aplicación nativa para macOS que permite gestionar catálogos de tablas con integración a MongoDB Atlas para el almacenamiento de datos y AWS S3 para el almacenamiento de archivos multimedia.

## Requisitos del Sistema

- macOS 12.0 o superior
- Conexión a Internet para acceder a MongoDB Atlas y AWS S3

## Instalación

1. Descomprima el archivo `EDF Catálogo de Tablas.app.zip` en la ubicación deseada.
2. Haga doble clic en el archivo `EDF Catálogo de Tablas.app` para iniciar la aplicación.

## Inicio de Sesión

Al abrir la aplicación, se mostrará la pantalla de inicio de sesión:

1. Ingrese su dirección de correo electrónico en el campo "Email".
2. Ingrese su contraseña en el campo "Contraseña".
3. Opcionalmente, marque la casilla "Recordar credenciales" para no tener que ingresar sus credenciales la próxima vez.
4. Haga clic en el botón "Iniciar Sesión".

**Credenciales de prueba:**
- Email: test@example.com
- Contraseña: password

## Interfaz Principal

Una vez autenticado, accederá a la interfaz principal de la aplicación, que consta de:

1. **Menú lateral**: Permite navegar entre las diferentes secciones de la aplicación.
2. **Área de contenido**: Muestra el contenido de la sección seleccionada.

### Menú Lateral

El menú lateral contiene las siguientes opciones:

- **Catálogos**: Muestra la lista de catálogos disponibles.
- **Perfil**: Muestra la información de su perfil de usuario.
- **Administración**: (Solo para usuarios con rol de administrador) Acceso a funciones administrativas.
- **Cerrar Sesión**: Cierra la sesión actual y vuelve a la pantalla de inicio de sesión.

## Gestión de Catálogos

### Ver Catálogos

1. Seleccione "Catálogos" en el menú lateral.
2. Se mostrará una lista de los catálogos disponibles.
3. Haga clic en un catálogo para ver sus detalles.

### Crear un Nuevo Catálogo

1. En la vista de catálogos, haga clic en el botón "Nuevo Catálogo".
2. Ingrese el nombre del catálogo.
3. Ingrese una descripción para el catálogo.
4. Defina las columnas del catálogo (separadas por comas).
5. Haga clic en "Guardar".

### Editar un Catálogo

1. En la vista de detalles del catálogo, haga clic en el botón "Editar Catálogo".
2. Modifique los campos según sea necesario.
3. Haga clic en "Guardar Cambios".

## Gestión de Filas

### Ver Filas de un Catálogo

1. Seleccione un catálogo de la lista.
2. Se mostrarán todas las filas del catálogo seleccionado.

### Añadir una Nueva Fila

1. En la vista de detalles del catálogo, haga clic en el botón "Editar".
2. Haga clic en el botón "Añadir Fila".
3. Complete los datos para cada columna.
4. Opcionalmente, añada archivos multimedia (imágenes, documentos, videos).
5. Haga clic en "Guardar".

### Editar una Fila

1. En la vista de detalles del catálogo, haga clic en el botón "Editar".
2. Haga clic en el icono de lápiz junto a la fila que desea editar.
3. Modifique los datos según sea necesario.
4. Haga clic en "Guardar".

### Eliminar una Fila

1. En la vista de detalles del catálogo, haga clic en el botón "Editar".
2. Haga clic en el icono de papelera junto a la fila que desea eliminar.
3. Confirme la eliminación cuando se le solicite.

## Gestión de Archivos

### Ver Archivos

1. En la vista de detalles del catálogo, los archivos asociados a cada fila se muestran como iconos.
2. Haga clic en un icono para ver el archivo.

### Tipos de Archivos Soportados

- **Imágenes**: JPG, JPEG, PNG, GIF, BMP
- **Documentos**: PDF, DOC, DOCX, XLS, XLSX
- **Multimedia**: MP4, MP3

## Perfil de Usuario

Para ver su perfil de usuario:

1. Seleccione "Perfil" en el menú lateral.
2. Se mostrará su información de usuario, incluyendo:
   - Email
   - Rol
   - Dirección (si está disponible)
   - Ocupación (si está disponible)
   - Fecha de registro

## Funciones de Administración

Si tiene el rol de administrador, puede acceder a funciones adicionales:

1. Seleccione "Administración" en el menú lateral.
2. Desde aquí puede gestionar usuarios y configuraciones del sistema.

## Solución de Problemas

### La aplicación no se inicia

- Asegúrese de que su sistema cumple con los requisitos mínimos.
- Verifique que tiene conexión a Internet.
- Intente reiniciar su ordenador.

### No puedo iniciar sesión

- Verifique que está ingresando las credenciales correctas.
- Compruebe su conexión a Internet.
- Si ha olvidado su contraseña, contacte con el administrador del sistema.

### No puedo ver mis catálogos

- Verifique que tiene los permisos necesarios para acceder a los catálogos.
- Compruebe su conexión a Internet.
- Intente cerrar sesión y volver a iniciar sesión.

### No puedo ver los archivos multimedia

- Verifique que tiene conexión a Internet.
- Compruebe que el archivo existe en el servidor S3.
- Intente recargar la página.

## Soporte Técnico

Si necesita ayuda adicional, por favor contacte con el soporte técnico:

- Email: soporte@edf.com
- Teléfono: +34 123 456 789
