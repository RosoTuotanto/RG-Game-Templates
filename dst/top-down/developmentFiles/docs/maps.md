# Maps

The game's maps are made in [Tiled](https://www.mapeditor.org/) and built into Solar2D display objects by PonyTiled (`game/com/ponywolf/ponytiled.lua`) when `game/scenes/game.lua` opens a map. This document covers what a map for this layer must contain and what the code reads from it. General information about the project is in the [README](../../game/README.md).

## Map files

- Each map is a Tiled JSON file in `game/maps/`, such as `outdoor1.json`. Its file name without `.json` is the map's name in exits and in the settings.
- Set the tile layer format to CSV in the map's properties. PonyTiled does not read Base64 or compressed tile data and prints `ERROR: Tile layer encoding/compression not supported` instead.
- Embed the tilesets in the map file. PonyTiled also loads external `.tsx` tilesets, but it reads no margin, spacing, tile properties or tile animations from them.
- Tiled saves each image path relative to the map file, and the game scene loads images from `maps`, so keep the map files in `game/maps/`.
- The shipped maps use 64 x 64 tiles. The settings and the frame sizes in `game/data/animations.lua` are sized for that, so a new map with another tile size needs those values changed as well.

## Tilesets

| Tileset | Image | Tiles | Used for |
| --- | --- | --- | --- |
| `tileset` | `maps/tileset.png`, 544 x 272 pixels | 32 tiles of 64 x 64 in 8 columns, margin 2, spacing 4 | The tile layers |
| `characters` | `maps/characters.png` | 3 tiles of 64 x 96 | The hero and NPC objects |
| `items` | `maps/items.png` | 3 tiles of 64 x 64 | The item objects |
| `props` | a collection of images in `maps/props/` | `crate.png`, `pillar.png`, `tree.png`, `sign.png` | Props and signs |

- PonyTiled cuts an embedded tilesheet by the tileset's tile size, margin and spacing, so the values set in Tiled must match the image. A new `tileset.png` drawn on the same grid keeps working with the shipped maps.
- The margin and spacing leave room around each tile, and `sampleImageSheetsInsideFrame` in the settings samples each frame slightly inside its edges, so neighbouring tiles do not bleed into each other.
- A collection of images has one image file per tile. Use it for objects that do not fit the tile grid, such as the tree.

## Layers

The code looks up two layers by name. Every other layer is drawn in the order Tiled lists it, from the bottom up.

| Layer | Kind | What it holds |
| --- | --- | --- |
| `game` | object layer | The hero, NPCs, items, signs, props and spawn points. The game scene sorts this layer for draw order. |
| `physics` | object layer | Walls, exits and message zones. It is hidden in Tiled, and the game scene hides it too. |

- The shipped outdoor maps put the tile layers `ground`, `paths` and `walls` below `game`, and `indoor1` puts `floor` and `walls` there. These names are free to change.
- A tile layer listed above `game` is drawn in front of the hero. The outdoor maps call it `above`, and any name works.
- A layer group in Tiled is flattened into its layers, which keep the group's visibility and opacity. An offset on a layer or a group has no effect in the game.

## Object types

The object's type (the `type` field in the map file) decides what the game does with it. The game scene runs the extensions in `game/maps/extensions/` on their types with `map:extend( "hero", "npc", "exit", "item", "zone" )`. The other types are plain PonyTiled objects that the game scene reads directly.

### hero

The player character. Every map needs exactly one, because the game scene builds the player from it.

| Setting | Value |
| --- | --- |
| Object | A tile object from the `characters` tileset, on the `game` layer |
| Name and type | `hero` |
| `anchorY` (float) | `0.875`, the row of the hero's feet (`heroSheet.feetY`, 84) divided by the frame height (96) |

The extension replaces the object with a sprite from `heroSheet` in `game/data/animations.lua` and gives it a round dynamic body of `topDown.heroBodyRadius` on its feet. The object's place on the start map is where a new game starts. Arriving through an exit moves the hero to a spawn point, and loading a save moves it to the saved position.

### npc

A character the player can talk to.

| Setting | Value |
| --- | --- |
| Object | A tile object from the `characters` tileset, on the `game` layer |
| Type | `npc` |
| `anchorY` (float) | `0.875`, the row of the feet (`characterSheet.feetY`) divided by the frame height |
| `frame` (int) | The NPC's frame in `maps/characters.png`. Default 1. |
| `node` (string) | The story passage the NPC opens. Without it, the NPC opens `story.npcPassage`. |
| `ignoreInteract` (bool) | `true` makes the interact key skip the NPC. Default false. |

The extension draws the NPC from `frame`, not from the tile picked in Tiled, so set the tile to the same frame to see the right picture in Tiled. The NPC gets a round static body of radius 24 on its feet, and it hops when the player talks to it. In the shipped maps the guide opens `guide` and NPC 2 opens `npc2`.

### item

An item the player can pick up. [inventory.md](inventory.md) covers the item data and the record of picked up items.

| Setting | Value |
| --- | --- |
| Object | A tile object from the `items` tileset, on the `game` layer |
| Name | A name no other item on the same map has |
| Type | `item` |
| `frame` (int) | The item's frame in `maps/items.png`. Default 1. |
| `item` (string) | The item's id in `game/data/items.lua` |
| `ignoreInteract` (bool) | `true` makes the interact key skip the item. Default false. |

The game records a picked up item by its map and its name, and does not build it again on a later visit. The item gets a round static body of radius 20 that the hero cannot walk over.

### sign

A map object the player can read. No extension handles it: the game scene's interact code opens the sign's passage.

| Setting | Value |
| --- | --- |
| Object | A tile object, such as `sign.png` from the `props` tileset, on the `game` layer |
| Type | `sign` |
| `bodyType` (string) | `static`, so the sign blocks the hero |
| `node` (string) | The story passage the sign opens, such as `signOutdoor1` and `signIndoor1` in the shipped maps |
| `ignoreInteract` (bool) | `true` makes the interact key skip the sign. Default false. |

The interact key acts on hidden NPCs, signs and items too. `ignoreInteract` is the way to leave an object out, and code can set it on the object at any time. Set on a layer in Tiled, it applies to every object on that layer.

### prop

Scenery the hero walks in front of and behind, such as trees, pillars and crates.

| Setting | Value |
| --- | --- |
| Object | A tile object from the `props` tileset, on the `game` layer |
| Type | `prop` (no code reads it) |
| `anchorY` (float) | `1`, so the object's position is its base line |

A prop has no physics body. A wall rectangle on the `physics` layer under its base stops the hero, as described in [Collision](#collision).

### spawn

The place where the hero appears after coming through an exit. No extension handles it: the game scene finds it by name.

| Setting | Value |
| --- | --- |
| Object | A rectangle on the `game` layer, hidden in Tiled |
| Name | The name exits use as `targetSpawn`, such as `fromOutdoor2` |
| Type | `spawn` |

The hero's feet land on the rectangle's centre. When an exit names a spawn point the target map does not have, the hero is placed at 0,0, the top left corner of the map, and `WARNING: spawn point "<name>" was not found.` is printed to the console. Place a spawn point far enough from the exits that the hero's body does not touch one on arrival.

### exit

An invisible area that takes the hero to another map.

| Setting | Value |
| --- | --- |
| Object | A rectangle on the `physics` layer |
| Type | `exit` |
| `bodyType` (string) | `static` |
| `isSensor` (bool) | `true` |
| `targetMap` (string) | The map to go to, as a file name in `game/maps/` without `.json` |
| `targetSpawn` (string) | The name of the spawn point in the target map |
| `requiredFlag` (string) | Optional. The story variable that unlocks the exit, written without `$`, such as `doorOpen`. |
| `lockedMessage` (string) | The line shown at a locked exit. Needed when `requiredFlag` is set. |

When the hero walks into the exit, the screen fades to black and the game scene is built again with the target map, through the refresh scene. [transitionOverlay.md](transitionOverlay.md) covers the fade.

An exit with `requiredFlag` stays locked while that story variable is `false` or not set, and opens once the story sets it to any other value, such as `<<set $doorOpen = true>>`. While it is locked, walking into it shows `lockedMessage` in the dialogue window. The message is shown exactly as written, so a line the hero says starts with `You: `, as in the shipped maps. [dialogue.md](dialogue.md) covers story variables.

In the sample, the door to `indoor1` has `requiredFlag` `doorOpen`, and the passage `guideParcel` opens it:

```text
<<removeItem, parcel>>
<<addItem, key>>
<<set $doorOpen = true>>
Guide: Thanks. removeItem took the parcel and addItem gave you a key.
```

### zone

An invisible area that shows a line when the hero walks in.

| Setting | Value |
| --- | --- |
| Object | A rectangle on the `physics` layer |
| Name | A name no other zone on the same map has, when `once` is `true` |
| Type | `zone` |
| `bodyType` (string) | `static` |
| `isSensor` (bool) | `true` |
| `message` (string) | The line to show, exactly as written |
| `once` (bool) | `true` shows the line once per game. Otherwise it shows every time the hero walks back in. |

The record of `once` zones that have fired is saved with the game.

### wall

A solid area. See [Collision](#collision).

## Collision

Solid areas are rectangles on the `physics` layer with the property `bodyType` `static`. PonyTiled gives each a physics body, and the shipped maps give them the type `wall`, which no code reads.

- The tile layers have no collision of their own: draw a wall rectangle over every wall, fence and edge the hero must not cross.
- For a prop, draw a small rectangle at its base only, such as the trunk of a tree. The hero then stops at the base and can walk behind the top of the prop.
- The hero's body is a circle of `topDown.heroBodyRadius` on its feet, so it slides along wall corners. A gap needs to be wider than twice that radius for the hero to pass.
- PonyTiled also makes bodies from ellipses (with a `radius` property), polygons and polylines, and passes every custom property of an object to `physics.addBody`. [Physics properties](#physics-properties) lists them.

## Draw order

Objects on the `game` layer are drawn so that the one whose base is lower on the screen is in front. The game scene sorts the layer with `map:sortLayer( "game" )` when the map is built and on every frame while the hero can move.

- The sort compares each object's bottom edge, computed from its position, height and `anchorY`.
- Props get `anchorY` 1 in Tiled, so their position is the base line they sort by.
- The hero and NPCs sort by their feet. Their extensions set the display group's `anchorY` to 1 with the group's position on the feet row, which is `feetY` of `heroSheet` and `characterSheet` in `game/data/animations.lua`.
- When the art changes, set `feetY` to the row of pixels in a frame, counted from the top, where the middle of the feet is, and set `anchorY` on the hero and NPC objects in Tiled to `feetY` divided by the frame height.
- The layer is not sorted while a conversation or the inventory is open, so an NPC's hop does not move it behind the hero.

## Camera

The camera follows the hero by moving the whole map and stops at the map's edges. On an axis where the map is no larger than the screen, the map is centred on that axis and the camera does not move along it. `indoor1` (11 x 8 tiles) is smaller than the screen on both axes, so the camera stays still and black shows around the room. Set a colour for such a map in `topDown.mapBackground`, or the screen around it stays black. The bounds are worked out again when the window size changes. [camera.md](camera.md) covers the camera module.

## Map settings

These keys in the `topDown` block of `game/data/settingsTemplate.lua` depend on the tile size. The values are the current examples for 64 x 64 tiles.

- `heroSpeed` (320) is the hero's speed in content units per second, five tiles per second.
- `heroBodyRadius` (24) is the radius of the hero's round body on its feet, in content units.
- `interactReach` (8) places the point the interact key looks at, in content units in front of the edge of the hero's body, the way the hero faces. It starts at the body's edge, so it does not depend on `heroBodyRadius`. A larger value reaches further ahead.
- `interactRadius` (16) is how close the edge of an object's body must be to that point, in content units. The key acts on the NPC, sign or item whose body is closest to the point within that distance. A larger value forgives standing further away or off to the side, and a smaller one needs the hero to face the object squarely.
- `startMap` (`"outdoor1"`) is the map a new game starts on. The hero starts where the map's `hero` object is.

## Adding a map

1. In Tiled, make a new map with 64 x 64 tiles and the CSV tile layer format, embed the `tileset`, `characters`, `items` and `props` tilesets, and save it in `game/maps/`, such as `cave1.json`.
2. Add tile layers, an object layer named `game` and an object layer named `physics`, and hide `physics`.
3. Put a `hero` object and one `spawn` rectangle per entrance on the `game` layer, such as `fromOutdoor2`.
4. Draw the wall rectangles on the `physics` layer.
5. Add an `exit` rectangle on the new map's `physics` layer with `targetMap` and `targetSpawn` pointing at a spawn point on the map it leads to.
6. On that other map, add a spawn point named for the new map and an exit with `targetMap` set to the new map's name (`cave1`) and `targetSpawn` set to the spawn point from step 3.
7. Add the map to `topDown.music`, and to `topDown.mapBackground` if it is smaller than the screen.

## Screen size changes

The game scene stays open when the window size changes or the player toggles fullscreen, and its `onResize` function places everything that depends on the screen size again. A widget or window that places itself from `screen.*` needs its own `resize()` function, called from `onResize` in `game/scenes/game.lua`, or it stays where the old screen size put it. `hints`, `dialogue` and `inventoryPanel` each have one.

## PonyTiled reference

### Physics properties

A Tiled object with a `bodyType` property (`static`, `dynamic` or `kinematic`) gets a physics body, and all of its custom properties are passed to `physics.addBody`.

| Property | Type | What it does |
| --- | --- | --- |
| `bodyType` | string | Creates the body: `static`, `dynamic` or `kinematic` |
| `density`, `friction`, `bounce` | float | The body's physics values |
| `radius` | float | Makes the body a circle of this radius |
| `isSensor` | bool | The body reports collisions but does not block anything |
| `isBox` | bool | Tile objects: makes the body a box sized by `boxWidth`, `boxHeight`, `boxX`, `boxY` and `boxAngle` |
| `autoShape` | float | Tile objects: traces the body's outline from the image with this tolerance |

- Every custom property of an object, and of its layer, becomes a field of the display object, which is how the extensions read `frame`, `node` and `targetMap`.
- Body settings that are not `addBody` options, such as `isFixedRotation`, are set in an extension after the body exists.

### Map functions

`ponytiled.new` returns the map display group with these functions, among others.

| Function | What it does |
| --- | --- |
| `map:findObject( name [, type] )` | Returns the first object with the name, or `false` |
| `map:listTypes( type1 [, type2, ...] )` | Returns a table of every object of the given types |
| `map:findLayer( name )` | Returns the layer group with the name, or `false` |
| `map:sortLayer( name [, reverse] )` | Sorts one layer's objects by their bottom edge |
| `map:extend( type1 [, type2, ...] )` | Runs the extension module of each type, from the path in `map.extensions` |

### Writing an extension

An extension is a Lua module in `game/maps/extensions/` whose `new` function receives the display object PonyTiled made for each object of its type. Add the type to the `map:extend` call in `game/scenes/game.lua` to run it.

- An extension can replace the object: take its `parent`, `x` and `y`, remove it with `display.remove`, and build a new object into the same parent, as the hero, npc and item extensions do.
- Remove event listeners, transitions and timers in a `finalize` listener, because every map change removes the whole map.

## Troubleshooting

- An object does nothing: check its type (not its name) against the extension's file name or the type the game scene checks, and that the type is in the `map:extend` call. Both are case-sensitive.
- A wall or exit does not block or react: the object needs `bodyType` `static`, and an exit or zone also needs `isSensor` `true`. Property names are case-sensitive.
- The hero or an NPC floats above or sinks below its spot: the object's `anchorY` in Tiled does not match `feetY` divided by the frame height.
- Tiles are offset or show parts of their neighbours: the tileset's tile size, margin or spacing in Tiled does not match the image.
- A tile object whose tile is missing from the map's tilesets is not created at all.
- Every tile is its own display object, so a large map creates many objects. Split a large area into several maps joined with exits.
