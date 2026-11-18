# Dialogue

Conversations and story flags come from a Story Weaver story written in Twine. `game/classes/dialogue.lua` loads the story into Spyric Story Weaver (`game/libs/spyricStoryWeaver.lua`), draws the dialogue window and hands the story's commands to the game scene. This document covers the contract between the story and the game. The top-down and platformer templates use the module, and the examples come from the top-down template. [inventory.md](inventory.md) covers the items the story can read, give and take. General information about the project is in the [README](../../game/README.md).

## Story files

| File | What it is |
| --- | --- |
| `developmentFiles/story/templateStory.html` | The Twine story, in the Weaver story format. Groups edit this one. |
| `game/data/templateStory.json` | The JSON that Twine's Weaver format downloads. The game reads only this file. |

These are the shipped templates' file names. The game never reads the `.html` file, so every change made in Twine reaches the game only through a new JSON download.

### Editing the story in Twine

1. In Twine, choose Import from the Library tab and pick `developmentFiles/story/templateStory.html` ([Twine reference](https://twinery.org/reference/en/story-library/creating.html)). Twine needs the Weaver story format installed, as in the courses.
2. Edit the passages.
3. Choose Build > Play and press Download JSON on the page that opens.
4. Replace `game/data/templateStory.json` with the downloaded file. Keep the file name, or point `story.source` at the new name.
5. Choose Publish to File from the Build tab and save it over `developmentFiles/story/templateStory.html` ([Twine reference](https://twinery.org/reference/en/story-library/exporting.html)), so the repository holds the same story as the JSON.

Twine keeps its own copy of the story in its library. Save the `.html` back to the repository after every edit, or the next person who imports it gets the old version.

## Story settings

The `story` block of the settings connects the game to the story. Core's defaults in `game/data/settingsCore.lua` name a file no template ships, so a template that uses the dialogue overrides both keys in `game/data/settingsTemplate.lua`. The values are the top-down template's.

| Key | Value | What it does |
| --- | --- | --- |
| `name` | `"Template Story"` | The name Weaver knows the story by. It becomes part of Lua code, so use only letters, digits and spaces. |
| `source` | `"data/templateStory.json"` | The story file, as a path from the `game/` folder. It must end in `.json`. |

A template can add its own keys to the block, such as the top-down template's `introPassage` and `npcPassage`.

## Opening a dialogue

The game scene calls `dialogue.init()` once for a new game, or `dialogue.setState( savedState )` for a loaded one, and then opens passages by name:

```lua
dialogue.open( "guide", uiGroup, onDialogueCommand, onDialogueClosed )
```

| Function | What it does |
| --- | --- |
| `dialogue.init()` | Loads the story from `story.source` and starts it from its starting values |
| `dialogue.open( nodeName, parentGroup, onCommand, onClose )` | Opens the window at the passage in `parentGroup`, which must not move with the camera. `onCommand` handles the story's own commands, and `onClose` runs once after the window closes. Both are optional. Does nothing while the window is open. |
| `dialogue.showMonologue( text, parentGroup )` | Shows one line without a passage, such as a line at a locked door |
| `dialogue.isOpen()` | Returns `true` while the window is on the screen |
| `dialogue.handleKey( action, phase )` | Handles a key action from `game/classes/controls.lua` while the window is open |
| `dialogue.close( skipHandler )` | Closes the window and then runs `onClose`. `dialogue.close( true )` closes it without running `onClose`, which a scene that is being left uses so nothing new is built into it. |
| `dialogue.resize()` | Builds the open window again at the new screen size, on the same line and choice. The game scene calls it from `onResize`. |
| `dialogue.getFlag( name )` | Returns the value of a story variable, written without `$`. Returns `nil` before `init`. |
| `dialogue.getState()` | Returns a copy of the story's state for a save |
| `dialogue.setState( state )` | Starts the story from its starting values and writes a saved state over them |

`onClose` can open a new dialogue of its own, because it is cleared before it runs. The platformer template uses it to act once a conversation ends.

## The dialogue window

- A passage's text lines are shown one at a time, and the `interact` action moves to the next one.
- The links of a passage become choices under its last text line. The `up` and `down` actions pick a choice, and `interact` opens its passage.
- A link inside a longer text line also becomes a choice, and its label stays in the text.
- On the last line of a passage with no links, `interact` closes the window.
- A passage whose conditions leave no text shows an empty line, with its choices straight away.
- The game scene sends every key action to `dialogue.handleKey` while the window is open. The shipped scenes keep the hero, the inventory and the pause menu waiting meanwhile.

### Links

| Link | Shows | Opens |
| --- | --- | --- |
| `[[Give the parcel\|guideParcel]]` | Give the parcel | `guideParcel` |
| `[[Give the parcel->guideParcel]]` | Give the parcel | `guideParcel` |
| `[[guideParcel<-Give the parcel]]` | Give the parcel | `guideParcel` |
| `[[goodbye]]` | goodbye | `goodbye` |

## Story commands

A `<<...>>` line that is not one of Weaver's own commands is passed to the `onCommand` function as a table, such as `{ "addItem", "key" }`. The top-down and platformer game scenes look the first value up in their `storyCommands` table and call the function with the rest as its arguments. A command with no function in the table is skipped.

| Command | What it does | Example |
| --- | --- | --- |
| `<<addItem, id>>` | Puts the item in the first free inventory slot | `<<addItem, key>>` |
| `<<removeItem, id>>` | Removes the first item with that id | `<<removeItem, parcel>>` |

- Separate the command and its arguments with commas. An argument made only of digits arrives as a number, and any other argument as a string.
- `<<addItem>>` does nothing when every slot is full, and the item is lost. Give items in passages the player reaches with room in the inventory.
- `if`, `elseif`, `else`, `end`, `set`, `shuffle`, `link` and `print` are Weaver's own commands. `<<print ...>>` writes to the console and reaches the game as `{ "print" }`, which no function handles.

### When commands run

All of a passage's commands and `<<set>>` lines run in order when the passage opens, before its first line is on the screen. Weaver runs the conditions and `<<set>>` lines first, and the game runs the commands after that, so a condition in the same passage still sees the inventory as it was when the passage opened.

### Adding a command

1. Add a function to the `storyCommands` table in `game/scenes/game.lua`, named as the command. It receives the command's arguments.
2. Write the command in a passage, such as `<<log, guideVisited>>`.
3. Download the JSON again and replace the story's `.json` file in `game/data/`.

```lua
local storyCommands = {
	-- ...

	log = function( message )
		print( "Story: " .. tostring( message ) )
	end,
}
```

## Variables and flags

The passage titled `variables`, with the tag `options`, gives the story variables their starting values as JSON. The top-down sample story has one flag:

```json
{ "doorOpen": false }
```

- A new game starts every variable from these values. The values are saved with the game.
- `<<set $doorOpen = true>>` changes a variable, and `<<if $doorOpen>>`, `<<elseif ...>>`, `<<else>>` and `<<end>>` pick lines by it. A condition must give `true` or `false`.
- A condition that reads a variable that does not exist counts as false.
- `$visits` is how many times the passage was opened before, so `<<if $visits == 0>>` picks the lines of the first visit.
- `node`, `temp`, `visits`, `previousNode`, `previousNodes` and `currentNode` are taken by Weaver. `inventory` is taken by the game.
- The game reads any variable with `dialogue.getFlag( name )`, such as the top-down template's flag-locked exits.

### Reading the inventory

Before every passage, the dialogue writes the held items into the story variable `$inventory`, with each held item's id as a key set to `true`. `<<if $inventory.parcel>>` is true while the parcel is in the inventory, and false when it is not. This is why an item id must be a valid Lua identifier ([inventory.md](inventory.md)).

## Saving

A save holds the story's state from `dialogue.getState()`: every story variable and each passage's visit count. Loading a save starts the story from its starting values and writes the saved state over them, so a passage or a variable added after the save was made starts from its starting value. [saving.md](saving.md) covers the save slots.

## Troubleshooting

- The game stops with a Lua error in `dialogue.lua` when a conversation opens: the passage does not exist, or the passage's `<<if>>` and `<<end>>` lines do not pair up. Weaver's warning above the error names the passage.
- A change made in Twine does not show in the game: the JSON was not downloaded again into `game/data/`.
- A command does nothing: its name in the passage does not match a key in `storyCommands`, or the comma after the name is missing. Both are case-sensitive.
- `(either: ...)` options cannot contain commas, because Weaver splits the options at every comma.
