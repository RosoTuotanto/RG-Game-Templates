# Roso Games - Visual Novel Template

A Solar2D project base for a visual novel. The story is written in Twine and played with Spyric Story Weaver: backgrounds and characters are drawn on screen, the story text and its links appear in a text box along the bottom, and story commands show characters, change backgrounds, give and take items and money, and run minigames. The layer sits on the Roso Games core, which gives it the launch screen, the main menu, the options screen, save slots, music, the scene transition and the inventory.

The project ships with a short showcase story on grey placeholder art. It shows each feature once, so you can see how the parts connect before you replace them with your own game.

## Running the project

1. Open the `game/` folder in the Solar2D Simulator.
2. Press Play in the main menu to start a new game at the `start` passage.

To skip the launch screen and the menu while you work, copy `data/launchParams.example.json` to `data/launchParams.json` and set `debugMode` to `true` and `gotoScene` to `"game"`.

## Controls

- Tap or click anywhere outside the links to show the next line.
- Tap or click a link to open its passage.
- The Menu button in the top right corner and Escape open the pause menu.
- The inventory button in the top left corner and I open and close the inventory. Escape and the Menu button also close an open inventory.
- Tap or click a slot in the inventory to see its item's name and description.
- While a minigame round runs, the inventory button and the money are hidden and the inventory does not open.

## Project structure

The layer adds these files to the core:

```text
game/
|-- assets/
|   |-- audio/music/story.mp3 -- story music
|   |-- images/backgrounds/ -- indoor.png, outdoor.png
|   |-- images/characters/ -- template-male-*.png, template-female-*.png
|   |-- images/minigame/ -- target.png, target-hit.png
|   |-- images/items.png -- the item icons
|   |-- images/ui/ -- menu.png, the menu background with the layer banner
|-- classes/minigames/targetPractice.lua -- the sample minigame
|-- data/
|   |-- settingsTemplate.lua -- this layer's settings
|   |-- templateStory.json -- the story the game reads
|   |-- items.lua -- the inventory's items, in place of Core's empty list
|   |-- credits.lua -- the credits screen's entries
|-- libs/spyricStoryWeaver.lua -- the story engine (vendored, do not edit)
|-- scenes/game.lua -- the story scene
```

## Settings

The game reads its settings from `data/settingsCore.lua` (the core's defaults) and `data/settingsTemplate.lua` (this layer's overrides). The two are merged key by key, and a list, such as `controls`, is replaced as a whole, so write out every entry when you change one.

The top of `data/settingsTemplate.lua` overrides three core settings:

- `menu.buttons` shows the full main menu, with Load and Credits.
- `controls` has two actions, `inventory` on I and `menu` on Escape, because the story is played with taps and clicks.
- `inventory` sets `itemSheet`, the image sheet of the item icons, and the text an empty slot shows in the inventory panel.

The `visualNovel` block holds the settings of the story scene:

- `storyName`, `storyFile` and `startPassage` connect the game to the story. [story.md](../developmentFiles/docs/story.md) covers them.
- `music` is the track that plays while the story is on screen.
- `background` is the size a background is drawn at before it is scaled to cover the screen.
- `textBox` sets the text box's height, colour and padding, the font size, the link colour and the space between links, in content units.
- `characters` sets the character image folder, the image size in pixels and the drawn height in content units, the default expression, the positions and the default position, and the times and distances of the character animations.
- `money` sets how the amount of money is written beside the inventory button and in the inventory panel's title row (`format`), its font size, and the plate behind it.
- `minigames` holds one table of settings per minigame, by module name. `targetPractice` sets the round's length and goal, the target timing, images and size, the margins and the counter texts.

## The sample content

The story is `data/templateStory.json`, and its Twine source is `developmentFiles/story/templateStory.html`. It walks through two backgrounds and two characters, `template-male` and `template-female`, each with a `default` and an `excited` image. On the way it offers a choice of two links, puts a badge in the inventory, shows a link only while the badge is in the inventory, takes the badge back, and runs the `targetPractice` minigame, whose result the next passage reads. The player starts with 100 money, and reaching the minigame's goal pays 50. [story.md](../developmentFiles/docs/story.md) lists the passages.

## Starting your own game

- Template assets: the placeholder images and audio are in `assets/images/template/` and `assets/audio/template/`, and each folder's `license.txt` covers only the files in it. Put your own images and audio in your own folders under `assets/`, point the settings below at them, and delete a template file once nothing uses it.
- Story: write your own passages in Twine and replace `data/templateStory.json` and its Twine source, as [story.md](../developmentFiles/docs/story.md) describes. Keep the `variables` passage and a passage named as `visualNovel.startPassage`, and delete the sample passages.
- Characters: add your own images as `<name>-<expression>.png` in a folder of your own and set `visualNovel.characters.folder` to it. If your images are not 720 x 1080 pixels, set `visualNovel.characters.imageWidth` and `imageHeight` to their size.
- Backgrounds: add your own images and show them with `<<img>>` in your story. If they are not 1920 x 1080 pixels, set `visualNovel.background` to their size.
- Items: list your own items in `data/items.lua`, add your own image sheet, and set `inventory.itemSheet` to its file name, frame size and frame count ([inventory.md](../developmentFiles/docs/inventory.md)).
- Money: set the starting amount of `money` in the `variables` passage.
- Minigame: delete `classes/minigames/targetPractice.lua`, `assets/images/template/minigame/`, `visualNovel.minigames.targetPractice` and the `targetHits` and `targetGoalReached` variables, or keep the module as a model for your own minigame.
- Music: add your own file and name it in `visualNovel.music`.
- Credits: fill in `data/credits.lua` with your group's names and the third-party assets your game uses.

## Documentation

The docs are in `developmentFiles/docs/`, beside this `game/` folder.

- [story.md](../developmentFiles/docs/story.md): the story files, the story commands, items and money, the character and background images, minigames and what a save holds.
- [inventory.md](../developmentFiles/docs/inventory.md): the core's inventory and its panel.
- [saving.md](../developmentFiles/docs/saving.md) and [music.md](../developmentFiles/docs/music.md): the core modules the story scene uses.

## License

This template is licensed under the MIT License, Copyright (c) 2025-2026 Eetu Rantanen and Roso Games (Kukunori ry). The game a Roso Games group builds on it is the group's own: its code is not covered by this licence and stays in the group's own use.

Spyric Story Weaver (`libs/spyricStoryWeaver.lua`) is licensed under the MIT License, as its header states. The bundled Spyric Story Weaver is an old pre-release included for learning purposes, and projects outside this template should use the current Weaver.
