# PurruPublicidad

Galeria de cuadros para mundos de VRChat, conectada al prefab PurruPublicidad.

**Ver galeria:** https://principepurru.github.io/PurruPublicidad/

## Cambiar imagenes desde GitHub (PC o celular)

1. Abre la carpeta `imagenes`.
2. Sube archivos llamados `Cuadro 1.jpg`, `Cuadro 2.png`, etc. Se aceptan PNG, JPG, JPEG y BMP.
3. Usa numeros de 1 a 32. No pongas dos extensiones con el mismo numero.
4. Confirma el cambio (Commit changes). Actions prepara y publica automaticamente la galeria.
5. Para retirar un cuadro, elimina su archivo de `imagenes` y confirma. No renumeres los demas.

El contenido se reduce a 1024 px, se convierte a JPEG y se mantiene su proporcion. La transparencia se convierte a blanco. Los archivos de imagen deben ser publicos para descargarse en VRChat.

El flujo **Publicar PurruPublicidad** debe terminar en verde. Si un archivo no es valido, conserva el sitio anterior en vez de publicar una galeria rota. Borrar todas las imagenes es valido: se ocultan todos los cuadros.

## Cambiar desde el PC

En el equipo configurado, abre **PurruPublicidad** en el Escritorio. Cambia las fotos de la carpeta de prueba y usa **Publicar imagenes**. **Vigilar carpeta** las sincroniza mientras su ventana permanezca abierta.

Si antes editaste desde GitHub, usa **Recuperar cambios de GitHub** antes de editar en PC. Conserva las imagenes locales anteriores en un respaldo; no mezcla silenciosamente dos versiones distintas.

## URLs para Unity

- Base: `https://principepurru.github.io/PurruPublicidad/`
- Registro: `https://principepurru.github.io/PurruPublicidad/estado.txt`
- Ejemplo de imagen: `https://principepurru.github.io/PurruPublicidad/cuadro-01.jpg`

Usar GitHub Pages, no la pagina del repositorio ni el boton Raw. El prefab prepara las URLs antes de subir el mundo. La galeria web es de consulta; la administracion web se hace en GitHub.

La publicacion y las caches pueden tardar varios minutos. Cada visitante consulta el registro por separado, no hay cambio instantaneo sincronizado. El prefab consulta cada 120 s y renueva imagenes periodicamente para recuperarse de caches antiguas. 32 es el limite elegido para este prefab, no el limite de GitHub.

Al eliminar una imagen deja de publicarse en la galeria, pero GitHub conserva el historial del repositorio. No alojes contenido confidencial.
