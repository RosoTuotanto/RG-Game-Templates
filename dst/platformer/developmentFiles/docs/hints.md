# Keyboard controls tooltip

`game/widgets/hints.lua` draws a small see-through box in the bottom left corner of the screen that tells the player which keys do what. General information about the project is in the [README](../../game/README.md).

## Settings

The `hints` block of the settings sets the tooltip. Core's defaults in `game/data/settingsCore.lua` are `enabled = true` and no rows, and a template sets its rows in `game/data/settingsTemplate.lua`.

| Key | What it does |
| --- | --- |
| `enabled` | `false` hides the tooltip: `hints.create` then draws nothing and returns `nil`, and the other functions do nothing. |
| `rows` | The tooltip's lines, from the top. Each row is `{ actions = { ... }, label = "..." }`, where `actions` are action ids from `controls`. It is a list, so an override replaces it whole. |

The top-down template's rows:

```lua
rows = {
	{ actions = { "up", "left", "down", "right" }, label = "Move" },
	{ actions = { "interact" }, label = "Interact" },
	{ actions = { "inventory" }, label = "Inventory" },
},
```

## How keys are shown

A row shows the keys bound to its actions, then ` - ` and its label, so the rows above read `WASD / Arrows - Move`, `E / Space - Interact` and `I - Inventory`.

- The keys come from the player's own bindings in `userdata.json`, so a secondary key the player rebinds in the options shows up after the next `hints.refresh()`.
- Single-letter keys are joined into one word in capitals, in the order of the row's actions and their keys, and the word comes before the other keys.
- The four arrow keys show as one `Arrows`, and a name that repeats in a row shows once.
- Other keys show by `hints.getKeyName`: `Esc`, `Space`, `Up`, `Down`, `Left` and `Right` for those keys, and any other key name in capitals.

## Functions

| Function | What it does |
| --- | --- |
| `hints.create( sceneGroup )` | Draws the tooltip into `sceneGroup`, which must not move with the camera, and returns its group |
| `hints.refresh()` | Draws the rows again from the player's current bindings. Call it after the pause menu closes, because the player can rebind keys in the options. |
| `hints.resize()` | Keeps the tooltip in the corner after a window size change. The game scene calls it from `onResize`. |
| `hints.getKeyName( keyName )` | Returns the name the player sees for one key, such as `"W"` or `"Space"`. Use it in any other text that names a key, so every key reads the same way. |
