# Roso Games - Core Template (RG CORE)

A Solar2D game project base by Roso Games. Core gives every template a working game skeleton: a launch screen, a main menu, an options screen with audio settings and rebindable controls, a save/load system with slots and screenshots, background music with fades, a fade-to-black scene transition, an in-game Menu button and pause menu, an inventory, a dialogue window for Story Weaver stories, a keyboard controls tooltip, and a set of utility libraries. Your game goes into `scenes/game.lua`; the rest is ready.

This template is licensed under the MIT License, Copyright (c) 2025-2026 Eetu Rantanen and Roso Games (Kukunori ry). The game a Roso Games group builds on it is the group's own: its code is not covered by this licence and stays in the group's own use. Third-party components keep their own licences, in the licence files shipped beside them.

## Prerequisites

- [Solar2D](https://solar2d.com/) (latest build)
- A code editor, e.g. VS Code with a Lua extension
- Basic Lua and Solar2D knowledge

## Getting started

1. Open the `game/` folder in the Solar2D Simulator (point it at `main.lua`).
2. The game boots to the launch screen and then the menu. Press Play to enter `scenes/game.lua`, which in Core is an empty placeholder that a template's game scene replaces.
3. Read through `data/settingsCore.lua` and `data/settingsTemplate.lua`. Game configuration lives there, not in code.

## Core and templates

Core is one half of every template. A build copies Core's `game/` and `developmentFiles/` folders and then a template's own folders on top of them, so a template file with the same path replaces the Core file. A game group copies the built `game/` and `developmentFiles/` folders into its own repository.

A template replaces at least `scenes/game.lua`, `data/settingsTemplate.lua`, `data/credits.lua` and this README, and adds its own modules, assets and docs. A template that uses the inventory also replaces the stub `data/items.lua` with its items.

## Folders

`game/` holds everything that ships with the game:

- `assets/` - images, audio, and fonts. The placeholder images and audio that come with the template are in `assets/images/template/` and `assets/audio/template/`, so your own files go in your own folders beside them.
- `classes/` - reusable modules with state (screen, loadsave, saveManager, music, transitionOverlay, camera, controls, inventory, dialogue).
- `data/` - configuration and data files (settings, credits, items).
- `libs/` - libraries and bootstrap code (initGame, settings, launchParams, utils, audioHandles, spyricStoryWeaver).
- `scenes/` - Composer scenes (launchScreen, menu, options, load, credits, refresh, game).
- `widgets/` - self-contained UI pieces (pause menu, Menu button, scene title, menu background, inventory panel, inventory button, keyboard controls tooltip).

`developmentFiles/`, beside `game/`, holds what does not ship, such as the docs in `developmentFiles/docs/`.

## Configuration files

The project has three configuration files with strict roles.

### data/settingsCore.lua

The Core defaults. Every key has a comment in the file; this table says what each one is for.

| Key | What it changes |
| --- | --- |
| `suppressErrors` | Hides runtime errors on devices when not in debug mode. Keep it `false` while you develop. |
| `usesPixelArt` | Draws images with sharp pixels instead of smoothing them. |
| `sampleImageSheetsInsideFrame` | Stops neighbouring frames of a sprite sheet or tileset from bleeding into each other. Turn it on for pixel art drawn from image sheets. |
| `startScene` | The scene the launch screen continues to (`"menu"`). |
| `fonts` | The font files of all game text: `regular` and `bold`, each a path to a file in a family folder under `assets/fonts/`. The values are Rubik's `Rubik-Regular.ttf` and `Rubik-Medium.ttf`. |
| `splashScreen` | The launch screen's logo image, its size and position, the copyright footer text, and how the logo fades in and out. |
| `menu.buttons` | Which menu buttons exist and in what order: `"play"`, `"load"`, `"options"`, `"credits"`, `"exit"`. |
| `menu.playScene` | The scene the Play button opens (`"game"`). |
| `menu.music` | The music track of the menu. |
| `menu.background` | The background image of the menu, load and credits scenes, and how far and how slowly it pans. |
| `sceneTitle` | The font size of the heading in the load, save, options, credits and pause views. |
| `saveSlots` | The slot screen's title position, how far the slot buttons sit from the slot's edges, and the text and timing of the panel shown after a save. |
| `options` | Where the audio controls of the options screen start (`audioTop`). |
| `music` | How long a track takes to fade out (`fadeOutTime`) and in (`fadeInTime`), in milliseconds. |
| `menuButton` | The Menu button's image sheet and frame size, its distance from the screen corner, and its font size. |
| `inventoryButton` | The inventory button's image sheet and frame size, and the size it is drawn at. |
| `transition` | How long the transition overlay takes to fade to black (`fadeInTime`) and back (`fadeOutTime`), in milliseconds. |
| `controls` | The game's keyboard actions and their default keys (see Controls below). |
| `hints` | Whether the keyboard controls tooltip shows, and its rows. See `developmentFiles/docs/hints.md`. |
| `inventory` | The inventory grid's size, the starting items, the item image sheet, and the panel's layout, font sizes and description lines. See `developmentFiles/docs/inventory.md`. |
| `story` | The Story Weaver story file (`source`) and its name (`name`). See `developmentFiles/docs/dialogue.md`. |
| `defaultUserdata` | The player's starting settings: the three volumes and whether the game starts in fullscreen. |

### data/settingsTemplate.lua

The template's and your game's overrides. Anything set here wins over `settingsCore.lua`. Merge rules: key-value tables merge per key; array-style lists (menu buttons, controls) are replaced wholesale, so restate the full list when you override one. Core's own copy is an empty stub, and each template's copy holds that template's settings. You can add your game's own settings here too.

Example override:

```lua
return {
	usesPixelArt = true,
	menu = {
		buttons = { "play", "load", "options", "credits", "exit" },
	},
}
```

### data/launchParams.json

Your PERSONAL testing flags. This file is gitignored and excluded from builds: it never affects anyone else, so you can freely set the game to boot straight into a scene you are working on. Copy `data/launchParams.example.json` to `data/launchParams.json` to use it. When the file is missing, safe defaults apply (all flags false, normal boot). A key with an unknown name or a wrong type prints a warning and is ignored.

| Field | Type | Default | Effect |
| --- | --- | --- | --- |
| `debugMode` | boolean | false | Skips the launch screen and goes directly to `gotoScene`. On HTML5, also sends `print` output to the browser console. Sets the `_debugMode` global. |
| `cleanLaunch` | boolean | false | Simulates a fresh install at launch: deletes `userdata.json` and every file in the `saves/` folder. |
| `muteGame` | boolean | false | Sets master volume to zero at launch. |
| `gotoScene` | string | (startScene) | The scene name (without `scenes.`) that `debugMode` boots into. |
| `launchParams` | object | `{}` | Custom values passed to the first scene as `event.params.launchParams`. |

## Scene flow

`main.lua` reads the settings and launch parameters, calls `libs/initGame.lua` (which sets up every Core system), and then goes to the launch screen, which fades the logo in and out and continues to `settings.startScene` (the menu by default).

The menu's buttons are defined by `settings.menu.buttons`:

- Play goes to `settings.menu.playScene`.
- Load opens the save slots (`scenes/load.lua`).
- Options opens the options screen as an overlay.
- Credits opens the scrolling credits from `data/credits.lua`. The text fades out when the scroll reaches its end, and touching the credits brings it back. `endFadeTime` in `data/credits.lua` sets the fade's length; `0` keeps the text visible.
- Exit quits the game. The Exit button hides itself on HTML5, where quitting is not supported.

The menu, load and credits scenes share the background from `widgets/menuBackground.lua`. It covers the screen from the image's top left corner and pans slowly, so keep the important part of `assets/images/template/ui/menu.png` near its top left corner. Core has a plain `menu.png`, and each template replaces it with its own at the same path.

Going to the scene that is already showing runs its hide and show events again but keeps its view, so `create` does not run and the scene is not rebuilt. `scenes/refresh.lua` rebuilds a scene from scratch: go to `scenes.refresh` and it removes the scene you came from and enters it again with the params you passed. Loading a save while the game is running goes through it.

`build.settings` holds build settings for Windows, macOS and HTML5.

## In-game UI

- `widgets/menuButton.lua` builds the Menu button in the top right corner. Every template's game scene places it and also opens its pause menu with the keys of the `menu` action (Esc by default).
- `widgets/pause.lua` is the pause menu. It shows Save, Load and Options buttons only when you give it their callbacks. When the player presses Save, it takes the save slot's screenshot and passes its path to your `onSave` callback.
- `widgets/sceneTitle.lua` draws the heading of the load, save, options, credits and pause views.
- `widgets/hints.lua` is the keyboard controls tooltip in the bottom left corner. See `developmentFiles/docs/hints.md`.
- `widgets/inventoryPanel.lua` draws the inventory of `classes/inventory.lua`, and `widgets/inventoryButton.lua` is a button that opens it with the mouse. See `developmentFiles/docs/inventory.md`.
- `classes/dialogue.lua` shows the passages of a Story Weaver story in a dialogue window and passes the story's commands to the game scene. See `developmentFiles/docs/dialogue.md`.

The images these widgets and the options screen are drawn from are described in `developmentFiles/docs/ui.md`.

## Save system

`classes/loadsave.lua` writes Lua tables to JSON files and reads them back. `classes/saveManager.lua` uses it to keep four save slots in the `saves/` folder, each with a screenshot. `scenes/load.lua` is the slot screen for both saving and loading, and after a save it shows a `Game saved.` panel before it returns to the game. Every slot stores a save version (`SAVE_VERSION` in `classes/saveManager.lua`), and a slot saved with another version reads as an empty slot. Raise the number whenever the shape of your saved game state changes.

Your game scene decides what a saved game contains: it builds a game state table, opens the slot screen in save mode, and reads `event.params.savedState` when it is entered from a loaded slot. See `developmentFiles/docs/saving.md`.

The player's settings (volumes, key bindings, fullscreen) are kept in `userdata.json`, and every file in the game can read them as `loadsave.userdata`. The first launch creates the file from `settings.defaultUserdata` and the default keys in `settings.controls`. On later launches the game adds any setting the file lacks, so a setting you add to `defaultUserdata` reaches players who already have the file.

## Audio

Audio uses the stock Solar2D [`audio.*` API](https://docs.coronalabs.com/api/library/audio/index.html), so the official documentation applies verbatim.

`libs/initGame.lua` calls `audio.reserveChannels( 1 )` at boot, so channel 1 is reserved for music. Sound effects play with no channel option and get channels 2 to 32.

`classes/music.lua` plays one looping music track on channel 1 and fades between tracks. The menu plays `settings.menu.music` every time it is shown, so a game scene that plays its own track gets the menu music back when the player returns to the menu. See `developmentFiles/docs/music.md`.

`libs/audioHandles.lua` loads the Core click sound once. Require it wherever you need the click and pass the handle to `audio.play`:

```lua
local audioHandles = require( "libs.audioHandles" )
audio.play( audioHandles.click )
```

The options screen's sliders follow the channel split: Master calls `audio.setVolume( value / 100 )` to scale every channel, Music sets the volume of channel 1, and SFX sets the volume of channels 2 to 32. The volume changes while the player drags a slider and is saved when they let go, and letting go of the SFX slider plays the click at the new volume. The values are kept in `userdata.json` under `audio.volume` (`master`, `music`, `sfx`, each 0 to 100). The Fullscreen checkbox below the sliders switches the window mode and saves the choice as `fullscreen`.

## Controls

Keyboard actions are defined in the `controls` list in the settings: each action has an id, a label, and up to two keys (main + secondary). `classes/controls.lua` turns them into per-frame movement vectors and action callbacks for your game scene. The movement vector comes from the actions with the ids `up`, `down`, `left` and `right`. While both directions of one axis are held, the one pressed last wins.

```lua
local controls = require( "classes.controls" )
controls.start( onMovement, onKeyAction )
```

The options screen's Controls tab lists every action from the same list and scrolls when there are more actions than fit. An action with no secondary key shows `-`. The main key always comes from the settings, and the player can rebind only the secondary key:

- A key that is already some action's main key cannot be a secondary key: the capture stays open and says the key is already in use.
- Binding a key that another action uses as its secondary key moves it to the new action.
- Pressing the action's current secondary key again clears it.
- The `menu` action's main key (Esc by default) or a tap outside closes the capture without a change.
- Reset to Defaults restores the keys from the settings.

The player's bindings are kept in `userdata.json`. At every launch they are matched to the current `controls` list: an action you add gets its default keys, an action you remove is dropped, and a secondary key that has become a main key is cleared.

## Transition overlay

`classes/transitionOverlay.lua` fades the screen to black, lets you change the scene behind it, and stays black until the next scene fades it away. Its default fade times come from `settings.transition`. See `developmentFiles/docs/transitionOverlay.md`.

## Camera

`classes/camera.lua` provides parallax layers, smooth target following with bounds, and screen shake for game scenes that need a scrolling world. See `developmentFiles/docs/camera.md`. Core does not activate it anywhere; it is a library for your game scene.
