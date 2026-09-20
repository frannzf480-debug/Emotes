# Catálogo de emotes UGC

GUI compacta para explorar emotes UGC reales del Marketplace de Roblox. Panel vertical a la derecha, fondo verde oscuro semitransparente, cuadrícula de 3 columnas, búsqueda, favoritos, populares, copia de ID y paginación.

Los nombres, precios, IDs y miniaturas salen del catálogo oficial (`Category=12`, `Subcategory=39`, `assetType=61`). En Studio/experiencia se consultan con `AvatarEditorService:SearchCatalog`, el método compatible con LocalScript.

## Vista previa web

```bash
python3 preview/server.py
```

Abre `http://localhost:8080`. La previsualización usa datos reales del catálogo de Roblox (nombres, IDs, precios y thumbnails `rbxcdn`).

## Roblox Studio

1. Sincroniza el proyecto con [Rojo](https://rojo.space) (`default.project.json`) **o**
2. Crea un **LocalScript** en `StarterPlayer > StarterPlayerScripts`.
3. Copia el contenido de `src/StarterPlayer/StarterPlayerScripts/EmoteCatalog.client.lua`.
4. Pulsa Play. El panel aparece a la derecha.

El cliente **no** llama a `catalog.roblox.com` (HttpService no puede hacerlo desde un LocalScript). Usa `AvatarEditorService`, `rbxthumb://` y `CatalogSearchParams`.

### Cómo “ejecutarlo”

Roblox desactiva `loadstring` por defecto (`ServerScriptService.LoadStringEnabled = false`) y `game:HttpGet` **no existe** en el motor. Este catálogo se ejecuta como LocalScript de tu experiencia, no como script de inyector.

Si quieres cargarlo desde un único archivo en Studio, pega el LocalScript completo. No uses ejecutores de terceros: violan los términos de Roblox.

## Funciones

- Buscar emotes por nombre
- Actualizar el catálogo
- Marcar / desmarcar favoritos
- Filtrar populares (`MostFavorited` / `Bestselling` cuando el enum está disponible)
- Seleccionar una tarjeta (borde resaltado)
- Ver y copiar el ID real del asset
- Mostrar precio real (o Gratis)
- Scroll vertical con carga por páginas
- Cerrar y reabrir el panel
- Ajuste a PC y móvil
