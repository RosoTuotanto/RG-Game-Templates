# Image sources

This folder holds the SVG sources of the images in the core and the templates, and the script that renders them into the PNG files the games use.

## Folders

`src/` has three parts:

- `core/` is RG CORE: the Solar2D project in `game/` and its docs in `developmentFiles/`.
- `templates/<name>/` is one template, split the same way.
- `images/` is this folder, with one folder of sources for the core and one for each template.

A source sits at the path its PNG has inside `game/`. For example, `top-down/maps/tileset.svg` is the source of `src/templates/top-down/game/maps/tileset.png`.

## Requirements

- Linux
- Python 3 with Pillow
- Node.js with the `playwright` package and its Chromium

## Usage

```sh
python3 src/images/build_images.py
```

The script renders every SVG file and writes its PNG into `game/`, replacing the old one.

To build only some images, name their folders or files inside this folder:

```sh
python3 src/images/build_images.py top-down core/assets/images/template/ui/slider.svg
```

An image that fails is reported, and the others are still built. Run `build.bat` or `build.sh` afterwards to get the new images into `dst/`.

To add an image, save its SVG at the path the PNG should have inside `game/`. The PNG gets the `width` and `height` of the SVG, which must be whole pixels.

## Configuration

The settings are in `config.json`.

- `tilesets` lists the tileset sources with their tile size. A tileset SVG holds its tiles in a grid with no gaps. The script cuts the tiles apart and repeats each tile's edge pixels outward, which gives the PNG the margin and spacing the Tiled maps use. A new tileset needs an entry here.
- `opaque` lists the sources whose PNG is saved without an alpha channel.
- `render` and `bounds` set the render quality and the time and memory one render may use.
