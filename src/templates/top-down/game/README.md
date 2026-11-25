# Roso Games - Top-Down Template

A Solar2D project base for a top-down adventure game. The hero walks around maps made in [Tiled](https://www.mapeditor.org/), talks to characters and reads signs whose lines come from a Story Weaver story, picks up items into an inventory, and moves between maps through exits. The layer sits on the Roso Games core, which gives it the launch screen, the main menu, the options screen, save slots, music and the scene transition.

The project ships with a small showcase on grey placeholder art. It shows each feature once, so you can see how the parts connect before you replace them with your own game.

## Running the project

1. Open the `game/` folder in the Solar2D Simulator.
2. Press Play in the main menu to start a new game on the `outdoor1` map.

To skip the launch screen and the menu while you work, set `debugMode` to `true` and `gotoScene` to `"game"` in `data/launchParams.json`, which the Simulator creates the first time you run the game.

## Settings

The game reads its settings from `data/settingsCore.lua` (the core's defaults) and `data/settingsTemplate.lua` (this layer's overrides). The two are merged key by key, and a list, such as `controls`, is replaced as a whole, so write out every entry when you change one.

`data/settingsTemplate.lua` overrides these core settings:

- `sampleImageSheetsInsideFrame` keeps neighbouring tiles of an image sheet from bleeding into each other.
- `menu.buttons` shows the full main menu, with Load and Credits.
- `controls` lists the game's actions and their keys, with `inventory` added to Core's actions. The first key of each action is fixed, and the player can bind the second key in the options.
- `story` names the story file (`source`), the name Story Weaver knows it by (`name`), the passage a new game opens (`introPassage`) and the passage an NPC without a `node` property opens (`npcPassage`). [dialogue.md](../developmentFiles/docs/dialogue.md) covers the story.
- `inventory` sets the item ids a new game puts in the inventory (`startingItems`) and the item image sheet (`itemSheet`), which the inventory panel and the map items both draw from. [inventory.md](../developmentFiles/docs/inventory.md) lists the other inventory settings.
- `hints` lists the rows of the keyboard controls tooltip in the bottom left corner, and `enabled = false` hides it. [hints.md](../developmentFiles/docs/hints.md) covers the rows.

The `topDown` block holds the settings of the top-down game:

- `startMap` is the map a new game starts on, as a file name in `maps/` without `.json`.
- `heroSpeed` and `heroBodyRadius` set how fast the hero walks and the size of its round physics body, in content units.
- `interactReach` sets how far in front of the edge of the hero's body the interact key looks, and `interactRadius` how close an object's body must be to that point, in content units. Both are measured from body edges, so they do not depend on the size of the hero's body. [maps.md](../developmentFiles/docs/maps.md) explains how they relate to the maps.
- `inventoryFullMessage` is the hero's line when the interact key finds an item but every inventory slot is taken.
- `music` gives the music file each map plays, by map name. Maps that share a file keep the track playing across a map change.
- `mapBackground` gives the colour behind a map narrower or shorter than the screen, by map name, as red, green and blue from 0 to 1. A map without a colour has a black background.

## The sample content

| Map | Size in tiles | What is on it |
| --- | --- | --- |
| `outdoor1` | 30 x 20 | The start map: the guide NPC, a sign, a message zone, a locked door to `indoor1` and an exit east to `outdoor2`. |
| `outdoor2` | 24 x 24 | A second NPC, the parcel item and the exit back west. |
| `indoor1` | 11 x 8 | A room with a sign and the door back out. It is smaller than the screen, so the camera stays still and black shows around it. |

The story is `data/templateStory.json`, and its Twine source is `developmentFiles/story/templateStory.html`. The guide asks for the parcel from `outdoor2`. Once the parcel is in the inventory, the guide's dialogue offers to take it: the passage removes the parcel, gives a key and sets the story flag `doorOpen`, which unlocks the door to `indoor1`.

`data/items.lua` defines three items: the parcel on `outdoor2`, the key the story gives, and the note the player starts with.

The story's passages, which you can delete when you write your own story, except `variables` and the ones `story` names:

| Passage | What it shows |
| --- | --- |
| `intro` | The passage a new game opens |
| `variables` | The starting value of the `doorOpen` flag |
| `guide` | Lines picked by a flag, and choices shown only while an item is held |
| `guideParcel` | `removeItem`, `addItem` and `set` together, which open the locked door |
| `npc2` | Lines picked by the flag and by the inventory |
| `npc2Parcel` | A passage reached only through a choice that depends on the inventory |
| `goodbye` | One passage that choices of both NPCs open |
| `signOutdoor1`, `signIndoor1` | Passages that signs open |
| `npcBackground` | `(either: ...)`, which picks one line at random each visit. No NPC in the shipped maps opens it. |

## Starting your own game

- Template assets: the placeholder images and audio are in `assets/images/template/` and `assets/audio/template/`, and each folder's `license.txt` covers only the files in it. Put your own images and audio in your own folders under `assets/`, point the settings below at them, and delete a template file once nothing uses it.
- Maps: delete `maps/outdoor1.json`, `outdoor2.json` and `indoor1.json`, make your own in Tiled ([maps.md](../developmentFiles/docs/maps.md)), and set `topDown.startMap`, `topDown.music` and `topDown.mapBackground` to the new map names.
- Map art: replace `maps/tileset.png`, `maps/characters.png`, `maps/items.png` and the images in `maps/props/`, keeping the frame sizes in `data/animations.lua` and `inventory.itemSheet` in step with the new images.
- Hero: add your own image sheet and set `heroSheet.filename` in `data/animations.lua` to it. The sheet's layout (5 columns and 3 rows of 64 x 96 pixel frames, rows facing south, north and west) and the row of the hero's feet are in `heroSheet` too.
- Story: replace `data/templateStory.json` and its Twine source with your own story, or point `story.source` at a new file, and keep an `intro` passage and an `npcBackground` passage or rename them in `story`. [dialogue.md](../developmentFiles/docs/dialogue.md) covers the story file.
- Items: replace the entries in `data/items.lua` and the ids in `inventory.startingItems`. [inventory.md](../developmentFiles/docs/inventory.md) covers adding an item.
- Music and sounds: add your own music files and name them in `topDown.music`. The interact sound's file name is in `scenes/game.lua`.
- Credits: fill in `data/credits.lua` with your group's names and the third-party assets your game uses.

## Documentation

The docs are in `developmentFiles/docs/`, beside this `game/` folder.

- [maps.md](../developmentFiles/docs/maps.md): building a map in Tiled, the object types and what the code reads from a map.
- [dialogue.md](../developmentFiles/docs/dialogue.md), [inventory.md](../developmentFiles/docs/inventory.md), [hints.md](../developmentFiles/docs/hints.md), [camera.md](../developmentFiles/docs/camera.md), [music.md](../developmentFiles/docs/music.md), [saving.md](../developmentFiles/docs/saving.md) and [transitionOverlay.md](../developmentFiles/docs/transitionOverlay.md): the core modules the game scene uses.
- [ui.md](../developmentFiles/docs/ui.md): the images of the Menu button and the options screen.

## License

This template is licensed under the MIT License, Copyright (c) 2025-2026 Eetu Rantanen and Roso Games (Kukunori ry). The game a Roso Games group builds on it is the group's own: its code is not covered by this licence and stays in the group's own use.

- PonyTiled (`com/ponywolf/ponytiled.lua`) is licensed under the MIT License, in `com/ponywolf/LICENSE`.
- Spyric Story Weaver (`libs/spyricStoryWeaver.lua`) is licensed under the MIT License, as its header states.
