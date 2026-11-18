# Maps

Each area of the game is a map made in [Tiled](https://www.mapeditor.org/) and built into Solar2D display objects by PonyTiled (`com/ponywolf/ponytiled.lua`). This document covers how an area is built for the platformer and what the code reads from it. General information about the project is in the [README](../../game/README.md).

## Map files

- Areas are Tiled JSON files in `game/assets/maps/`, and an area's name is its file name without `.json`: `outdoor.json` is the area `outdoor`. Doors, `platformer.startArea` and `platformer.music` refer to areas by that name.
- The maps use one tileset, `assets/maps/tileset.png`, embedded in each map file. PonyTiled reads tile properties, tile animations, margin and spacing only from an embedded tileset, so an external `.tsx` tileset loses the rope, trampoline and spike behaviour.
- The tiles are 48 x 48 pixels and draw 48 content units wide. The tileset image has a margin of 2 pixels and a spacing of 4 pixels between tiles, and the tileset settings in Tiled must match the image.
- Save the tile layer format as CSV. PonyTiled does not read Base64 or compressed tile data.

## Layers

Every area has three tile layers and one object layer, in this order from the back to the front:

| Layer | Type | What it is for |
| --- | --- | --- |
| `background` | tile layer | Walls and decoration behind the hero |
| `level` | tile layer | The ground, walls and platforms the hero meets, and the rope, trampoline and spike tiles. The scene puts the hero on this layer. |
| `foreground` | tile layer | Decoration drawn in front of the hero |
| `objects` | object layer | Spawns, doors, items, characters, prompt bubbles and the collision shapes. Keep it hidden, so the shapes do not draw in the game. |

- The scene finds the `level` layer by its name, so an area without a `level` layer stops with a Lua error.
- Behind the map, the scene draws the backdrop images listed in `platformer.backdrop`. They are not part of the map: each one repeats sideways, scrolls at its own parallax against the camera and stays fixed vertically. The backdrop shows wherever the tile layers leave empty cells, so an area whose `background` layer is filled, such as `indoor`, hides it.
- An area named in `platformer.noBackdrop`, such as `room`, gets no backdrop, so the screen around an area smaller than the screen stays black.

## Collision

Ground, wall and ceiling tiles have no physics body of their own. The `solid` and `oneWay` objects on the `objects` layer are the collision, because a body per tile lets the hero catch on the joins between tiles.

After you change tiles in Tiled, move or redraw the matching objects on the `objects` layer. A ground, wall or ceiling tile with no object over it is only a picture: the hero passes through it.

### Solid objects

A `solid` object is a rectangle, or one closed polygon drawn around a whole solid area, such as the ground with its pits. Each needs these custom properties:

| Property | Type | Value |
| --- | --- | --- |
| `id` | string | `platform` |
| `bodyType` | string | `static` |
| `friction` | float | `0` |
| `bounce` | float | `0` |

- PonyTiled passes the properties to `physics.addBody`. A polygon becomes a closed chain, which collides only along its edges, so the hero must stay on the open side of the outline.
- The hero's ground sensor reacts only to objects with `id` `platform`. A shape without it still blocks the hero, but landing on it never gives the jumps back.
- The type `solid` (the Class field in Tiled, as described in the [Tiled manual](https://doc.mapeditor.org/en/stable/manual/custom-properties/)) is a label for you: the code reads the properties, not the type.

### One-way platforms

A `oneWay` object is a rectangle with the same four properties as a solid object plus `oneWay` (bool) set to `true`. The hero passes through it from below and from the sides and lands on it from above. The feet count as above the platform when they are at most `platformer.hero.landingTolerance` content units below its top edge.

### Map edges

Each area has a solid rectangle just outside its left edge and another just outside its right edge, as tall as the map, so the hero cannot run off either side. A ceiling or a room's outline is drawn with solid objects like any other wall.

## Spawns and doors

### Spawns

A spawn is an object on the `objects` layer that the code finds by its name. A new game puts the hero at the object named in `platformer.startSpawn` (`start` in the `outdoor` area), and a door puts the hero at the object named in its `targetSpawn`.

- The hero's frame (96 x 96 pixels in the sample) is centred on the object's centre, and the hero's feet are at the bottom of the frame. A 48 x 96 rectangle whose bottom edge sits on the floor puts the feet on the floor.
- The scene stops with a Lua error when the named object is missing from the area.
- The type `spawn` on the start object is a label for you; any object with the right name works.

### Doors

A door is a rectangle with the type `door`. The hero goes through it when the player presses Up while the hero's centre is inside the rectangle: the screen fades to black, the target area is built from scratch, and the hero appears at the target spawn.

| Property | Type | Value |
| --- | --- | --- |
| `targetMap` | string | The target area's name, such as `indoor` |
| `targetSpawn` | string | The name of the object in the target area where the hero appears |

A door's own name can serve as the other area's target spawn. In the sample, the door `toIndoor` in `outdoor` leads to the object `toOutdoor` in `indoor`, which is the door back out, and that door leads to `toIndoor`. The door `toRoom` in `indoor` and the door `toIndoor` in `room` lead to each other the same way.

A character in reach wins over a door: when the hero stands in a door and close to a character, Up starts the talk.

## Items, characters and prompt bubbles

### Items

An item lying on the map is a rectangle with the type `item`. The hero picks it up by touching it, and it goes into the first free slot of the inventory. `classes/item.lua` builds it.

| Property | Type | Value |
| --- | --- | --- |
| `item` | string | The item's id in `data/items.lua`, such as `parcel` |
| `frame` | int | The item's frame in the image sheet `inventory.itemSheet`, the same frame as the item's entry in `data/items.lua`. Without it, frame 1 is drawn. |

- The item is drawn `platformer.item.size` content units wide and tall, centred sideways on the object, with its bottom edge on the object's bottom edge.
- The object's name is the key of the record of picked up items, so give every item object a name of its own within its area. The sample's parcel is named `parcel`.
- A picked up item stays gone when the hero comes back to the area and after a save is loaded, because the record is kept per area and goes into the save.
- When every slot is full, the item stays on the map. The hero picks it up by moving off it and touching it again once a slot is free.
- The item ids and the inventory panel are covered in [inventory.md](inventory.md).

### Characters

A character is a rectangle with the type `npc`. `classes/npc.lua` draws it with its feet at the object's bottom centre, so a 48 x 96 rectangle whose bottom edge sits on the floor puts her feet on the floor.

| Property | Type | Value |
| --- | --- | --- |
| `node` | string | The story passage the talk opens, such as `npc` |
| `prompt` | string | Optional: the text of the bubble over the character, such as `{up}: talk` |

- Every character is drawn from the same image sheet, `npcSheet` in `data/animations.lua`, with the sequences `idle`, `raise` and `lower` from `npcSequences`.
- A character has no physics body, so the hero walks past her.
- The hero is in reach of an object while the gap between the hero's physics body and the object's rectangle is at most `platformer.prompt.reachX` content units sideways and at most `reachY` vertically. The gap is 0 while they overlap, so an object of any size is in reach while the hero touches it.
- The hero starts a talk with Up while a character is in reach. With several characters in reach, one the hero faces or overlaps wins over one behind the hero, and among those the one with the smallest sideways gap to the hero's body. A character also turns to face the hero while the hero is in reach.
- When the talk starts, she plays `raise` and holds her arm up. When the dialogue closes, she plays `lower` and goes back to `idle`.
- The story passages are covered in [story.md](story.md), and the dialogue window in [dialogue.md](dialogue.md).

### Prompt bubbles

Any object on the `objects` layer with a `prompt` property (string) gets a bubble with that text over its top edge. `widgets/prompt.lua` draws it.

- The bubble shows while the hero is in reach of the object, the same reach a talk uses, and hides while a conversation or the inventory is open.
- `{action}` in the text becomes the keys bound to that action in `controls`, so `{up}: talk` shows as "Up / W: talk". The bubbles are drawn again with the current keys when the game resumes from the pause menu, so a key changed in the options shows at once.
- The bubble's look and the reach are in `platformer.prompt` in `data/settingsTemplate.lua`.
- In `outdoor`, the object `signDoors` with the type `sign` lies over the Up sign before the door and carries the prompt `{up}: enter doors`. The type `sign` is a label for you; the code reads only the `prompt` property.

## Tiles with behaviour

A few tiles in the embedded tileset have an `id` property. In Tiled, open the tileset, select a tile and look at its custom properties. Place these tiles on the `level` layer.

| Tile `id` | Other properties | What it does |
| --- | --- | --- |
| `rope` | `bodyType` `static`, `isSensor` `true` | While the hero touches a rope, gravity stops, Up and Down climb, and the jumps are given back. Jumping leaves the rope. |
| `trampoline` | `bodyType` `static`, `isSensor` `true` | A jump started with the hero's feet on the trampoline gets `platformer.trampoline.jumpMultiplier` times the normal jump speed, and the tile shows its pressed frame. |
| `spikes` | none | Touching the lower part of the tile plays the hurt sound, fades the screen to black and puts the hero back at the last door or spawn. |

- Rope and trampoline tiles get their sensor bodies from the tileset properties. Spike tiles get theirs from `classes/spikes.lua`, which covers the share of the tile set in `platformer.spikes`.
- The trampoline tile has a two-frame tile animation in Tiled: the rest frame, then the pressed frame. `classes/trampoline.lua` stops the animation and shows the pressed frame only after a jump, for `platformer.trampoline.pressedTime` milliseconds.
- The tileset also holds a tile with `isVisible` set to `false`. It never draws in the game; the `outdoor` area uses it along its top row, where the ceiling's solid object is, so the ceiling shows in Tiled.
- The ground sensor finds a trampoline only through the feet, so touching it from the side does nothing.

## Falling and the camera

- When the hero falls more than `platformer.fallMargin` content units below the area's bottom edge, the screen fades and the hero is put back at the last door or spawn, as with spikes.
- The camera follows the hero within the map's edges, so nothing past them shows. An area no larger than the screen on an axis is centred on that axis, so in an area smaller than the screen on both axes, such as `room`, the camera stays still. The camera settings are in `platformer.camera`, and [camera.md](camera.md) covers the camera module.
- The scene follows window size changes, such as a resized window or a fullscreen toggle in the options: it rebuilds the backdrop for the new size and recalculates the camera's bounds.

## Music

Each area plays the music file named for it in `platformer.music` in `data/settingsTemplate.lua`. Areas that share a file keep the track playing through a door, and a different file fades over to the new track. [music.md](music.md) covers the music module.

## Saving

A save slot holds the area, the last door or spawn the hero arrived at, the hero's position, the inventory, the record of picked up items and the story's state. Loading the slot builds that area without the items already picked up and puts the hero at the saved position, and spikes and falls then put the hero back at the saved spawn. [saving.md](saving.md) covers the save system, and [transitionOverlay.md](transitionOverlay.md) the fade used for doors and respawns.

## Adding an area

The steps go in this order, because the door in step 5 names objects made in step 4:

1. Copy an existing area's JSON file in `assets/maps/` and give the copy the new area's name, such as `cave.json`. The copy keeps the embedded tileset with its tile properties.
2. Open the copy in Tiled, resize the map and redraw the `background`, `level` and `foreground` layers.
3. On the `objects` layer, draw `solid` and `oneWay` objects over every surface the hero should meet, and the solid rectangles just outside the left and right edges.
4. Add a door that leads back, with `targetMap` set to the area it comes from and `targetSpawn` set to the name of the door in that area. Give the new door a name, such as `toOutdoor`.
5. In the area it comes from, add a door with `targetMap` set to the new area's name and `targetSpawn` set to the new door's name.
6. Add the new area's music file to `platformer.music` in `data/settingsTemplate.lua`.
7. If the area is smaller than the screen and the screen around it should be black, add the area's name to `platformer.noBackdrop`.
8. Save the map as JSON in `assets/maps/`.
