# Roso Games - Platformer Template

A Solar2D project base for a side-view platformer. The hero runs, jumps, double jumps, climbs ropes and bounces on trampolines in areas made in [Tiled](https://www.mapeditor.org/), moves between areas through doors, picks up items into an inventory and talks to characters through a story written in Twine. The layer sits on the Roso Games core, which gives it the launch screen, the main menu, the options screen, save slots, music, the scene transition, the inventory, the dialogue window and the keyboard controls tooltip.

The project ships with a small showcase on grey placeholder art. It shows each feature once, so you can see how the parts connect before you replace them with your own game.

## Running the project

1. Open the `game/` folder in the Solar2D Simulator.
2. Press Play in the main menu to start a new game in the `outdoor` area.

To skip the launch screen and the menu while you work, copy `data/launchParams.example.json` to `data/launchParams.json` and set `debugMode` to `true` and `gotoScene` to `"game"`.

## Controls

| Action | Keys |
| --- | --- |
| Run | Left and Right arrows, or A and D |
| Jump and double jump | Space |
| Climb a rope | Up and Down arrows, or W and S |
| Go through a door | Up arrow or W, while standing in the door |
| Talk to a character | Up arrow or W, while close to the character |
| Open and close the inventory | I |
| Pause menu | Escape, or the Menu button on the screen |

- The first key of each action is fixed, and the player can bind a second key to each action in the options.
- While a conversation is open, the hero stands still, Space shows the next line and confirms the selected choice, and Up and Down move between the choices. Escape and the Menu button do nothing until the conversation closes.
- While the inventory is open, the game is paused, the movement keys move the cursor, Space picks up and puts down an item, and I or Escape closes the inventory and resumes the game.
- A tooltip in the bottom left corner lists the keys of the main actions. The `hints` block of `data/settingsTemplate.lua` sets its rows, and `enabled = false` there hides it.

## Settings

The game reads its settings from `data/settingsCore.lua` (the core's defaults) and `data/settingsTemplate.lua` (this layer's overrides). The two are merged key by key, and a list, such as `controls` or `platformer.backdrop`, is replaced as a whole, so write out every entry when you change one.

`data/settingsTemplate.lua` overrides these core settings:

- `sampleImageSheetsInsideFrame` keeps neighbouring tiles of an image sheet from bleeding into each other.
- `menu.buttons` shows the full main menu, with Load and Credits.
- `controls` lists the game's actions and their keys.
- `story` names the story file and the name Spyric Story Weaver knows it by. [story.md](../developmentFiles/docs/story.md) covers them.
- `inventory.itemSheet` is the image sheet of the item icons. The inventory panel and the items lying on the map draw from it.
- `hints` lists the rows of the keyboard controls tooltip.

The `platformer` block holds the settings of the platformer game. The values below are the current examples:

- `startArea` and `startSpawn` name the area a new game starts in (a file name in `assets/maps/` without `.json`) and the object on that area's `objects` layer where the hero appears.
- `gravity` sets how strongly gravity pulls, in metres per second squared, where Solar2D counts 30 content units as one metre.
- `fallMargin` is how far below an area's bottom edge, in content units, the hero may fall before it is put back at the last door or spawn.
- `hero` sets the running and climbing speeds, the jump speed, how many jumps the hero gets before landing (`maxJumps = 2` gives the double jump), how far below a platform's top the feet may be and still count as standing on it (`landingTolerance`), and the size of the hero's physics body, all in content units.
- `trampoline` sets how many times the normal jump speed a jump off a trampoline gets (`jumpMultiplier`) and how many milliseconds the trampoline shows its pressed frame.
- `spikes` sets the share of a spike tile's width and height, from its bottom edge, that sends the hero back.
- `camera` sets how smoothly the camera follows the hero and how far below the screen's centre it keeps the hero (`yOffset`).
- `backdrop` lists the images drawn behind the map, from the farthest to the nearest, with each image's size in pixels and its parallax: 0 stays still and 1 moves with the map.
- `music` gives the music file each area plays, by area name. Areas that share a file keep the track playing across a door.
- `noBackdrop` lists the areas drawn without the backdrop, such as `room = true`, so the screen around an area smaller than the screen stays black.
- `item.size` is the width and height, in content units, of an item lying on the map.
- `prompt` sets the look of the bubbles over map objects, such as "Up / W: talk", and `reachX` and `reachY` set the largest sideways and vertical gap between the hero's body and an object at which a bubble shows and a talk starts.

## The sample content

| Area | Size in tiles | What is on it |
| --- | --- | --- |
| `outdoor` | 60 x 20 | The start spawn, ground with pits, spikes in one pit, a rope, a trampoline, two one-way platforms, two solid blocks with the parcel on the higher one, an Up sign with a prompt bubble and a door to `indoor`. |
| `indoor` | 26 x 14 | The door back out, a door to `room`, spikes on the floor, three one-way platforms and a solid block. |
| `room` | 12 x 8 | The door back to `indoor` and a character to talk to. |

- The tiles are 48 x 48 pixels, so `outdoor` and `indoor` are larger than the screen and the camera follows the hero there.
- `room` is smaller than the screen, so the camera stays still, and `platformer.noBackdrop` leaves the screen around it black.
- Touching spikes or falling out of an area puts the hero back at the door or spawn it last arrived at.
- The character in `room` asks for the parcel. Talking to her with the parcel in the inventory offers to hand it over, which takes it out of the inventory. The story is `data/templateStory.json`, and its passages are listed in [story.md](../developmentFiles/docs/story.md#the-sample-story).

## Starting your own game

- Template assets: the placeholder images and audio are in `assets/images/template/` and `assets/audio/template/`, and each folder's `license.txt` covers only the files in it. Put your own images and audio in your own folders under `assets/`, point the settings below at them, and delete a template file once nothing uses it.
- Maps: delete `assets/maps/outdoor.json`, `indoor.json` and `room.json`, make your own areas in Tiled ([maps.md](../developmentFiles/docs/maps.md)), and set `platformer.startArea`, `platformer.startSpawn`, `platformer.music` and `platformer.noBackdrop` to the new names.
- Tileset: replace `assets/maps/tileset.png`. A new image with another tile size, margin or spacing needs the same values in the tileset of every map, and the rope, trampoline and spike tiles need their properties in the new tileset ([maps.md](../developmentFiles/docs/maps.md#tiles-with-behaviour)).
- Hero: add your own image sheet, set `heroSheet.filename` in `data/animations.lua` to it, and update `heroSheet` and `heroSequences` to match it: the frame size, the row of the feet (`feetY`) and the frames of each animation. Size the physics body in `platformer.hero.body` to the new character.
- Characters: add your own image sheet, set `npcSheet.filename` in `data/animations.lua` to it, and update `npcSheet` and `npcSequences`. `classes/npc.lua` plays the sequences by the names `idle`, `raise` and `lower`, so keep those three.
- Items: list your own items in `data/items.lua`, add your own image sheet, and set `inventory.itemSheet` to its file name, frame size and frame count ([inventory.md](../developmentFiles/docs/inventory.md)).
- Story: write your own passages in Twine and replace `data/templateStory.json` and its Twine source, as [story.md](../developmentFiles/docs/story.md) describes. Keep the `variables` passage and delete the sample passages.
- Backdrops: add your own images and list them in `platformer.backdrop`.
- Music and sounds: add your own music files and name them in `platformer.music`. The sound file names are in `classes/player.lua` (jump) and `scenes/game.lua` (hurt).
- Credits: fill in `data/credits.lua` with your group's names and the third-party assets your game uses.

## Documentation

The docs are in `developmentFiles/docs/`, beside this `game/` folder.

- [maps.md](../developmentFiles/docs/maps.md): building an area in Tiled, the layers and object types, and what the code reads from a map.
- [story.md](../developmentFiles/docs/story.md): the story file and its Twine source, the story commands and the sample story.
- [inventory.md](../developmentFiles/docs/inventory.md), [dialogue.md](../developmentFiles/docs/dialogue.md) and [hints.md](../developmentFiles/docs/hints.md): the core's inventory and its panel, the dialogue window and the keyboard controls tooltip.
- [camera.md](../developmentFiles/docs/camera.md), [music.md](../developmentFiles/docs/music.md), [saving.md](../developmentFiles/docs/saving.md) and [transitionOverlay.md](../developmentFiles/docs/transitionOverlay.md): the core modules the game scene uses.

## License

This template is licensed under the MIT License, Copyright (c) 2025-2026 Eetu Rantanen and Roso Games (Kukunori ry). The game a Roso Games group builds on it is the group's own: its code is not covered by this licence and stays in the group's own use.

- PonyTiled (`com/ponywolf/ponytiled.lua`) is licensed under the MIT License, in `com/ponywolf/LICENSE`.
- Spyric Story Weaver (`libs/spyricStoryWeaver.lua`) is licensed under the MIT License, as its header states.
