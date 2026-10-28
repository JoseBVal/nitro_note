# NitroNote

**Aplicación móvil para organizar notas, apuntes e información técnica.**

NitroNote es un prototipo de aplicación móvil para Android desarrollado con Flutter y Dart. Su objetivo es facilitar la creación, organización y consulta de información mediante notas que pueden contener texto, imágenes y grabaciones de audio.

La aplicación permite organizar el contenido en carpetas personalizadas y conservar los datos localmente en el dispositivo, ofreciendo una forma práctica de administrar apuntes académicos, comandos, soluciones técnicas e ideas personales.

## Características principales

- **Gestión de carpetas:** crear, editar, personalizar y eliminar carpetas.
- **Gestión de notas:** crear, consultar, editar y eliminar notas.
- **Búsqueda:** encontrar carpetas y notas mediante texto.
- **Favoritos:** marcar notas importantes para acceder a ellas fácilmente.
- **Imágenes:** adjuntar hasta dos imágenes por nota, utilizando la galería o la cámara.
- **Notas de audio:** grabar y reproducir una grabación de audio por nota.
- **Modo claro y oscuro:** adaptar la apariencia de la aplicación.
- **Compartir notas:** compartir el título y el contenido de una nota como texto.
- **Almacenamiento local:** conservar la información en el dispositivo para consultarla posteriormente.

## Tecnologías utilizadas

| Tecnología | Uso |
|---|---|
| Flutter | Desarrollo de la aplicación móvil y su interfaz. |
| Dart | Lenguaje de programación del proyecto. |
| Hive | Almacenamiento local de datos. |

## Pantallas principales

NitroNote cuenta con cuatro vistas principales que permiten navegar entre las distintas funciones:

1. **Carpetas:** organiza las notas por categorías personalizadas.
2. **Lista de notas:** muestra las notas de una carpeta y permite buscarlas o filtrarlas.
3. **Editor de notas:** permite modificar el título, contenido, favoritos, imágenes y audio.
4. **Detalle de la nota:** presenta el contenido guardado y permite consultar las imágenes, reproducir el audio y acceder a las acciones disponibles.

## Instalación y ejecución

### Requisitos previos

- Tener instalado el [Flutter SDK](https://docs.flutter.dev/get-started/install).
- Contar con Dart, incluido en el SDK de Flutter.
- Utilizar un editor compatible, como Visual Studio Code o Android Studio.
- Disponer de un dispositivo Android o emulador configurado.

### Pasos para ejecutar el proyecto

1. Clona el repositorio:

   ```bash
   git clone URL_DE_TU_REPOSITORIO
   ```

2. Ingresa a la carpeta del proyecto:

   ```bash
   cd NitroNote
   ```

3. Instala las dependencias:

   ```bash
   flutter pub get
   ```

4. Comprueba la configuración del entorno:

   ```bash
   flutter doctor
   ```

5. Ejecuta la aplicación:

   ```bash
   flutter run
   ```

> **Nota:** reemplaza `URL_DE_TU_REPOSITORIO` por la dirección real de tu repositorio de GitHub. Si la carpeta del proyecto tiene otro nombre, utiliza ese nombre en el comando `cd`.

## Pruebas y funcionamiento

El prototipo permite probar el flujo de creación, edición y consulta de notas, la organización por carpetas, el uso de imágenes y la nueva funcionalidad de grabación y reproducción de audio.

También permite comprobar la persistencia de la información local al cerrar y volver a abrir la aplicación.

## Objetivo del proyecto

Desarrollar una aplicación móvil intuitiva que facilite la organización de información académica y personal, integrando diferentes medios para registrar y consultar contenido.

## Posibles mejoras futuras

- Incorporar copias de seguridad y restauración de datos.
- Permitir exportar notas a PDF o imagen.
- Ampliar las opciones de personalización visual.
- Incorporar nuevas herramientas para organizar y consultar información.

## Autor

**JoseBVal**

## Tipo de proyecto

Proyecto académico de desarrollo de aplicaciones móviles, creado con fines educativos para aplicar conocimientos de programación, diseño de interfaces y almacenamiento local.

---

*NitroNote — Tus apuntes, imágenes y audios organizados en un solo lugar.*