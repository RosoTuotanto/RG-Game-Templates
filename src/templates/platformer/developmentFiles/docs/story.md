# Story

The platformer's conversations are a Story Weaver story written in Twine. A character on the map opens one of its passages, and Core's `game/classes/dialogue.lua` shows the passage in the dialogue window. This document covers the template's story file, the commands the game scene runs and the sample story. The dialogue window, its keys and the `$inventory` conditions are covered in [dialogue.md](dialogue.md), and general information about the project is in the [README](../../game/README.md).

## Story files

| File | What it is |
| --- | --- |
| `developmentFiles/story/templateStory.html` | The Twine story, in the Weaver story format. Groups edit this one. |
| `game/data/templateStory.json` | The JSON that Twine's Weaver format downloads. The game reads only this file. |

The game never reads the `.html` file, so every change made in Twine reaches the game only through a new JSON download.

### Editing the story in Twine

1. In Twine, choose Import from the Library tab and pick `developmentFiles/story/templateStory.html` ([Twine reference](https://twinery.org/reference/en/story-library/creating.html)). Twine needs the Weaver story format installed, as in the courses.
2. Edit the passages.
3. Choose Build > Play and press Download JSON on the page that opens.
4. Replace `game/data/templateStory.json` with the downloaded file. Keep the file name, or point `story.source` at the new name.
5. Choose Publish to File from the Build tab and save it over `developmentFiles/story/templateStory.html` ([Twine reference](https://twinery.org/reference/en/story-library/exporting.html)), so the repository holds the same story as the JSON.

Twine keeps its own copy of the story in its library. Save the `.html` back to the repository after every edit, or the next person who imports it gets the old version.

## Story settings

The `story` block of `game/data/settingsTemplate.lua` connects the game to the story. The values are the current examples.

| Key | Value | What it does |
| --- | --- | --- |
| `name` | `"Template Story"` | The name Weaver knows the story by. It becomes part of Lua code with its spaces removed, so use only letters, digits and spaces. |
| `source` | `"data/templateStory.json"` | The story file, as a path from the `game/` folder. |

The passage titled `variables`, with the tag `options`, gives the story variables their starting values as JSON. The sample story has one:

```json
{ "parcelGiven": false }
```

A new game starts the story from the beginning, with every variable at its starting value. The story has no start passage of its own: each talk opens the passage named in the character's `node` property on the map ([maps.md](maps.md#characters)).

## Story commands

A `<<...>>` line that is not one of Weaver's own commands is passed to the game as a table, such as `{ "removeItem", "parcel" }`. `onDialogueCommand` in `game/scenes/game.lua` looks the first value up in the `storyCommands` table and calls the function with the rest as its arguments. A command with no function in the table is skipped.

| Command | What it does | Example from the sample story |
| --- | --- | --- |
| `<<addItem, id>>` | Puts the item with that id from `game/data/items.lua` in the first free slot of the inventory. Nothing is added when every slot is full. | Not used in the sample story |
| `<<removeItem, id>>` | Takes the item with that id out of the inventory | `<<removeItem, parcel>>` |

- Separate the command and its arguments with commas.
- The commands of a passage run when the passage opens, before its first line shows.
- `$inventory` is filled in and the passage's `<<if>>` conditions are worked out when the passage opens, before its commands run. So `<<if $inventory.parcel>>` sees an item that `addItem` or `removeItem` changed only from the next passage on, never in the passage that runs the command.
- To add a command, add a function named as the command to `storyCommands`.

## Saving

A save holds the story's state with the rest of the game: every story variable and each passage's visit count. Loading a save starts the story from the beginning and writes the saved values over the starting values, so a passage or a variable added after the save was made starts from its starting value. [saving.md](saving.md) covers the save slots.

## The sample story

Delete these passages, except `variables`, when you write your own story, and point the `node` property of your characters at your own passages.

| Passage | What it shows |
| --- | --- |
| `variables` | The starting value of `parcelGiven` |
| `npc` | The passage the character in `room` opens. Its `<<if>>`, `<<elseif>>` and `<<else>>` branches pick the lines by `$parcelGiven` and `$inventory.parcel`, and while the parcel is held it offers two links. |
| `npcParcel` | `<<removeItem, parcel>>` and `<<set $parcelGiven = true>>` when the parcel is handed over |
| `npcNotYet` | The other link, which keeps the parcel |
