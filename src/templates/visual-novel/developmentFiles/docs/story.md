# Story

The visual novel is a Story Weaver story written in Twine. `game/scenes/game.lua` loads the story into Spyric Story Weaver (`game/libs/spyricStoryWeaver.lua`), shows its text and links in the text box, and runs the story's commands for backgrounds, characters, items, money and minigames. This document covers the contract between the story and the game. General information about the project is in the [README](../../game/README.md).

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
4. Replace `game/data/templateStory.json` with the downloaded file. Keep the file name, or point `visualNovel.storyFile` at the new name.
5. Choose Publish to File from the Build tab and save it over `developmentFiles/story/templateStory.html` ([Twine reference](https://twinery.org/reference/en/story-library/exporting.html)), so the repository holds the same story as the JSON.

Twine keeps its own copy of the story in its library. Save the `.html` back to the repository after every edit, or the next person who imports it gets the old version.

## Story settings

The `visualNovel` block of `game/data/settingsTemplate.lua` connects the game to the story. The values are the current examples.

| Key | Value | What it does |
| --- | --- | --- |
| `storyName` | `"Template Story"` | The name Weaver knows the story by. It becomes part of Lua code with its spaces removed, so use only letters, digits and spaces. Saves store it with the game state. |
| `storyFile` | `"data/templateStory.json"` | The story file, as a path from the `game/` folder. It must end in `.json`. |
| `startPassage` | `"start"` | The passage a new game starts at. |

The passage titled `variables`, with the tag `options`, gives the story variables their starting values as JSON. The sample story has three:

```json
{ "money": 100, "targetHits": 0, "targetGoalReached": false }
```

A new game starts every variable from these values.

## How a passage plays

- When a passage opens, the game first copies the items in the inventory into `$inventory`. Weaver then works out the passage's `<<if>>` conditions and runs its `<<set>>` lines, so a condition sees the variables and the inventory as they were when the passage opened.
- The game then goes through the passage's lines in order. Each text line replaces the text on screen and waits for a tap.
- The game's own commands run in order between the text lines, so a command written after a text line runs when the player taps past that line.
- The links of a passage appear under its last text line, in the link colour. Tapping a link opens its passage.
- A passage with no links leaves the player on its last line, with only the Menu button and Escape left to press.
- A tap while a character animation runs ends the animation at once and moves on.
- Characters and the background stay on screen from passage to passage until a command changes them.

## Story commands

A `<<...>>` line that is not one of Weaver's own commands is passed to the game as a table, such as `{ "minigame", "targetPractice" }`. `getContent` in `game/scenes/game.lua` looks the first value up in the `storyCommands` table and calls the function with the rest as its arguments. A command with no function in the table is skipped.

| Command | What it does | Example from the sample story |
| --- | --- | --- |
| `<<character, show, name, expression, position>>` | Shows a character, or changes the expression or position of one on screen | `<<character, show, template-male, default, left>>` |
| `<<character, hide, name>>` | Fades a character out | `<<character, hide, template-male>>` |
| `<<img, "path">>` | Shows a background image, as a path from the `game/` folder, in place of the one on screen | `<<img, "assets/images/template/backgrounds/indoor.png">>` |
| `<<del background>>` | Removes the background image | Not used in the sample story |
| `<<minigame, name>>` | Runs a minigame round and continues the passage when it ends | `<<minigame, targetPractice>>` |
| `<<addItem, id>>` | Puts the item with that id from `game/data/items.lua` in the first free slot of the inventory. Nothing is added when every slot is full. | `<<addItem, badge>>` |
| `<<removeItem, id>>` | Takes the item with that id out of the inventory | `<<removeItem, badge>>` |
| `<<money, amount>>` | Adds a whole number to `$money`. A negative amount takes money away. | `<<money, 50>>` |

- Separate the command and its arguments with commas. An argument made only of digits arrives as a number, and any other argument as a string.
- To add a command, add a function named as the command to `storyCommands`. A function that returns `true` holds the passage until something calls `getContent` again, as the minigame command does.

### Characters

- `position` is `left`, `center` or `right`: a quarter, half or three quarters of the screen width from its left edge. The fractions are in `visualNovel.characters.positions`, and a new key there adds a position.
- A character shown without a position enters at `center` (`defaultPosition`).
- A character shown without an expression enters with `default` (`defaultExpression`), and a character already on screen keeps its current expression.
- A character that enters slides in from its side of the screen and fades in. A character entering at `center` slides in from the right.
- A character stays on screen across passages until `<<character, hide, name>>` hides it.
- Showing a character already on screen with another expression swaps its image in place, with a short pop.
- Showing a character already on screen with another position slides it there. To move a character without changing its expression, write its current expression: `<<character, show, template-male, default, left>>`.
- A character that enters later is drawn in front of the ones already on screen.

## Images

### Characters

- A character image is `<name>-<expression>.png` in the folder that `visualNovel.characters.folder` names, which is `game/assets/images/template/characters/` in the template, so `<<character, show, template-female, excited>>` shows `template-female-excited.png`. Every expression a passage names needs its file, or the game stops with a Lua error in `game.lua`.
- Every character image is drawn 520 content units tall, out of the 640 content units of the screen's height (`visualNovel.characters.height`).
- The drawn width comes from `imageWidth` and `imageHeight`, 720 and 1080 now, which match the sample images of 720 x 1080 pixels. Give all character images that shape, or set the two keys to the size of your own images.
- The bottom edge of the image stands on the bottom edge of the screen, and its horizontal centre is on the character's position. Draw all images of one character on the same canvas with the same framing, so an expression swap does not make the character jump.

### Backgrounds

- A background is drawn at the size in `visualNovel.background`, 1920 x 1080 now, then scaled to cover the whole screen and centred. On a screen of another shape, the edges of the image are cut off.
- The sample backgrounds are 1920 x 1080 pixels. Draw backgrounds of another shape at their own size and set `visualNovel.background` to it.
- The background is always drawn behind the characters.

## Minigames

`<<minigame, name>>` loads the module `game/classes/minigames/<name>.lua` and starts a round. Its settings are in `visualNovel.minigames.<name>`.

### The module contract

- The module returns a table with the function `start( parent, onComplete )`.
- `start` draws the round into `parent`, a group the scene puts above the story, and returns the round.
- The round has the methods `pause()`, `resume()`, `resize()` and `remove()`.
- When the round ends, the module calls `onComplete( result )`, where `result` is a table of story variables by name without `$`, such as `{ targetHits = 4, targetGoalReached = false }`.

### While a round runs

- The text box and its text are hidden, and taps no longer advance the story.
- The inventory button and the money are hidden, and the inventory does not open.
- The Menu button and Escape open the pause menu, and the scene calls `pause()` on the round. Resume calls `resume()`.
- The pause menu offers no Save while a round runs, because a save would load at the start of the passage.
- A change of the window size calls `resize()`.
- Quitting to the main menu calls `remove()`.

When the module calls `onComplete`, the scene calls `remove()`, writes each value of `result` into the story variable of that name, shows the text box again and continues the passage from the line after the minigame command.

### The sample minigame

`targetPractice` shows targets one at a time for 10 seconds (`duration`), and the player touches as many as they can. It writes two story variables:

- `targetHits`: how many targets the player hit.
- `targetGoalReached`: `true` when the hits reached `goal`, 6 now, and `false` otherwise.

Weaver works out a passage's conditions when the passage opens, so the rest of the minigame's own passage cannot read the result. The story reads the variables from the next passage on, as `result` does. It also pays 50 money when the goal was reached:

```text
<<if $targetGoalReached == true>>
<<character, show, template-male, excited>>
<<money, 50>>
You reached the goal with $targetHits hits.
<<else>>
You missed the goal with $targetHits hits.
<<end>>
```

### Adding a minigame

1. Create `game/classes/minigames/<name>.lua` with a `start( parent, onComplete )` function that fulfils the contract above. `targetPractice.lua` is a working model, and its `roundTag` shows how one tag lets `pause`, `resume` and `remove` reach every timer and transition of the round.
2. Put the minigame's settings in a new table under `visualNovel.minigames` in `game/data/settingsTemplate.lua`, and read them in the module from `settings.visualNovel.minigames.<name>`.
3. Add the variables the module passes to `onComplete` to the `variables` passage with their starting values.
4. Write `<<minigame, name>>` in a passage, and read the variables in a passage that a link after it opens.
5. Download the JSON again and replace `game/data/templateStory.json`.

## Items and money

### Items

The items are listed in `game/data/items.lua`, each by its id with a name, a description and its frame in the image sheet `inventory.itemSheet`. The id is the name the story uses, so it must be a valid Lua identifier. [inventory.md](inventory.md) covers the item list and the inventory panel.

A condition reads `$inventory.<id>`, which is `true` while the item is in the inventory. In the sample, `badge` gives the badge with `<<addItem, badge>>`, and `badgeLinks` shows the link to `giveBadge` only while the badge is in the inventory, and the link to the minigame always:

```text
<<if $inventory.badge>>
The next link only shows while the badge is in your inventory.
[[Give the badge back|giveBadge]]
<<else>>
You gave the badge back, so its link is gone.
<<end>>
[[Play the minigame|minigame]]
```

`giveBadge` takes the badge back with `<<removeItem, badge>>` and links back to `badgeLinks`, which then shows the `<<else>>` lines.

### Money

The money is the story variable `$money`. Its starting amount is in the `variables` passage, 100 in the sample.

- The amount shows beside the inventory button and at the right end of the inventory panel's title row, written as `visualNovel.money.format` sets it, such as `$ 100`.
- `<<money, 50>>` adds 50, and `<<money, -50>>` takes 50 away. The amount may go below zero.
- An amount that is missing, not a number or not a whole number prints a warning with the passage's name to the console, and the command is skipped.
- A condition reads the amount like any variable, such as `<<if $money >= 50>>`.

### When a change shows

`<<addItem>>`, `<<removeItem>>` and `<<money>>` run after Weaver has worked out the passage's conditions and filled in its `$variables`. So the passage that runs one of them still sees the old inventory and the old amount, in `<<if>>` conditions and in text such as `$money`, and the change shows from the next passage on. The money beside the inventory button changes at once.

## Going back to the first passage

A link back to the first passage, such as the sample's `[[Start again|start]]`, opens it as any other passage. The story variables and the visit counts keep their values, so a story that can be played through again sets every variable before a passage reads it.

## Saving

A save holds the passage on screen and what was in place when the player entered it:

- The story's save data: every story variable, `$money` among them, and each passage's visit count.
- The inventory.
- The background on screen.
- The characters on screen, with their expressions and positions.

Loading a save shows that background and those characters at once, writes the saved values over the story's starting values and opens the passage again from its first line. A passage or a variable added after the save was made starts from its starting value. [saving.md](saving.md) covers the save slots.

## Window size changes

The scene follows a change of the window size, such as a fullscreen toggle in the options. It lays out the text box and its text again, scales the background to cover the new screen, puts the characters on their positions on the new screen and calls `resize()` on a running minigame round. A character animation that is running when the window size changes ends at once at its end position.

## The sample story

Delete these passages, except `variables` and the passage `visualNovel.startPassage` names, when you write your own story.

| Passage | What it shows |
| --- | --- |
| `variables` | The starting values of `money`, `targetHits` and `targetGoalReached` |
| `start` | The first background, and a character entering with the default expression and position |
| `expression` | An expression swap |
| `indoors` | A background change, and a character moving to `left` |
| `secondCharacter` | A second character entering at `right`, and two links |
| `firstChoice`, `secondChoice` | One passage per link, both leading to `badge` |
| `badge` | `<<addItem>>` putting the badge in the inventory |
| `badgeLinks` | A link shown only while the badge is in the inventory |
| `giveBadge` | `<<removeItem>>` taking the badge back |
| `minigame` | A `targetPractice` round inside a passage |
| `result` | Lines picked by the minigame's result, and `<<money, 50>>` when the goal was reached |
| `ending` | Both characters hidden, and a link back to `start` |
