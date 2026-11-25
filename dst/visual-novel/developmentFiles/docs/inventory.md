# Inventory

The inventory is a grid of slots that holds item ids. `game/data/items.lua` describes each item, `game/classes/inventory.lua` keeps the slots and the record of map items already picked up, `game/widgets/inventoryPanel.lua` draws the grid, and `game/widgets/inventoryButton.lua` is an optional button that opens it with the mouse. Core provides the modules, and the game scene of a template decides when the panel opens, which keys reach it and what goes into a save. The examples come from the top-down template. [dialogue.md](dialogue.md) covers the story commands and conditions that use items. General information about the project is in the [README](../../game/README.md).

## Item data

Core ships `game/data/items.lua` as an empty stub, and a template that uses the inventory replaces it with its own items. Each entry is one item, and its key is the item's id, which `inventory.startingItems`, the story and the template's own objects use.

```lua
parcel = {
	name = "Parcel",
	description = "An item picked up from the map. The guide's dialogue asks for it.",
	frame = 1,
},
```

| Field | What it does |
| --- | --- |
| `name` | The name in the panel's info box |
| `description` | The text under the name in the info box |
| `frame` | The item's icon, as a frame number in the item image sheet |

An id must be a valid Lua identifier (letters, digits and underscores, not starting with a digit), because the story reads it as `$inventory.<id>`.

### Item images

`inventory.itemSheet` in the settings names the image the icons come from: `filename`, and the `frameWidth`, `frameHeight` and `frameCount` of its frames, numbered from 1. Core gives only the frame values, so a template that uses the inventory sets `filename`. The top-down template uses `maps/items.png` with three frames of 64 x 64, and its map items draw from the same sheet through `inventory.getItemSheet()`.

## Settings

The `inventory` block of `game/data/settingsCore.lua` holds Core's defaults, and a template overrides keys in `game/data/settingsTemplate.lua`. The values are Core's.

| Key | Value | What it does |
| --- | --- | --- |
| `columns`, `rows` | `4`, `2` | The size of the grid in slots. The panel sizes itself from them. |
| `startingItems` | `{}` | The item ids a new game puts in the inventory. It is a list, so an override replaces it whole. |
| `itemSheet` | 64 x 64 frames | The item image sheet, as above |
| `slotSize`, `slotGap` | `96`, `18` | The size of a slot and the gap between slots, in content units |
| `padding`, `titleHeight`, `sectionGap` | `26`, `34`, `18` | The space inside the panel's edge, the height of the title row, and the gaps between the title, the grid and the info box |
| `iconSize` | `64` | The size of an item's icon in its slot |
| `titleFontSize`, `nameFontSize`, `descriptionFontSize` | `30`, `26`, `20` | The font sizes of the title, the item's name and its description |
| `descriptionLines` | `4` | How many lines of description the info box holds. The info box and the panel grow to fit them. |
| `emptySlotDescription` | `"Move the cursor with the arrow keys."` | The description shown for an empty slot, under the name "Empty slot" |

The panel's key is the `inventory` action in `controls`, such as `{ id = "inventory", label = "Inventory", keys = { "i" } }`. Core's `controls` has no such action, so a template that uses the inventory adds it, and a `hints` row can show its key ([hints.md](hints.md)).

## Picking up, giving away and saving

- `inventory.add` puts an item in the first free slot and returns `false` when every slot is full. The top-down template then leaves the item on the map and the hero says `topDown.inventoryFullMessage`.
- The record of picked up items holds each map item by its map and its object name, so the item does not come back on a later visit. The game scene calls `inventory.setMap` before it builds a map.
- The top-down and platformer game scenes handle the story commands `<<addItem, id>>` and `<<removeItem, id>>` with `inventory.add` and `inventory.remove`. An item that `<<addItem>>` cannot fit is lost.
- A new game calls `inventory.reset()` and then `inventory.addStartingItems()`.
- The module keeps its state when the game scene is built again, so the game scene does not hand the inventory over on a map change.
- A save holds what the game scene puts in its game state. The top-down template saves a copy of `inventory.slots` under the key `inventory` and a copy of `inventory.getCollected()` under `collected`, and passes both to `inventory.restore` when a save is loaded. [saving.md](saving.md) covers the save slots.

## The inventory panel

- The panel opens in the middle of the screen over a dimmed background that blocks every touch to the game behind it.
- The arrow keys move the cursor and wrap around the grid's edges. A tap on a slot moves the cursor there.
- The info box shows the name and description of the item under the cursor. A name wider than the box and a description longer than `descriptionLines` lines are cut after the last whole word that fits and end in `...`, by `display.fitText` in `game/libs/utils.lua`.
- The `interact` action picks up the item under the cursor, drawn faded, and the next press puts it down. In another slot the two items swap places. An item picked up and not put down stays in its own slot when the panel closes.
- The `inventory` action closes the panel. The game scene sends every key to `inventoryPanel.handleKey` while the panel is open, and the top-down and platformer scenes also close it with the `menu` action.
- The top-down and platformer scenes pause the game world while the panel is open, as the pause menu does, and resume it from the `onClose` function they pass to `inventoryPanel.open`. The controls keep running, so a movement key held when the panel closes moves the hero at once.
- The optional status text at the right end of the title row shows a value such as the player's money, which the visual novel template uses.

## inventory.lua functions

| Function | What it does |
| --- | --- |
| `inventory.add( itemId )` | Puts the item in the first free slot. Returns `true`, or `false` when every slot is full. |
| `inventory.remove( itemId )` | Removes the first item with that id and leaves its slot empty |
| `inventory.has( itemId )` | Returns `true` while at least one item with that id is held |
| `inventory.getHeldItems()` | Returns a table with each held item's id as a key set to `true`. The dialogue writes it into `$inventory`. |
| `inventory.getSlot( slotIndex )` | Returns the item id in that slot, or `nil` |
| `inventory.move( fromSlot, toSlot )` | Moves an item to another slot, swapping when that slot holds an item |
| `inventory.addStartingItems()` | Adds every item in `inventory.startingItems` |
| `inventory.getItemSheet()` | Returns the item image sheet, built from `inventory.itemSheet` the first time it is asked for |
| `inventory.setMap( mapName )` | Sets the map the record of picked up items refers to |
| `inventory.markCollected( objectName )` | Records the object on the current map as picked up |
| `inventory.isCollected( objectName )` | Returns `true` when the object on the current map was picked up |
| `inventory.getCollected()` | Returns the record of picked up items, by map and object name. It is the module's own table, so save a copy. |
| `inventory.restore( savedSlots, savedCollected )` | Replaces the slots and the record with saved ones |
| `inventory.reset()` | Empties the slots and the record |

- `inventory.slots` holds the items by slot, with the slot numbers as string keys (`slots["1"] = "note"`), so the slots come back from a JSON save unchanged.
- `inventory.slotCount` is `columns` times `rows`.

## inventoryPanel.lua functions

| Function | What it does |
| --- | --- |
| `inventoryPanel.open( parentGroup, status, onClose )` | Opens the panel in `parentGroup`, which must not move with the camera. `status` is the optional text at the right end of the title row. `onClose` is an optional function that runs once when the panel closes. Does nothing while the panel is open. |
| `inventoryPanel.isOpen()` | Returns `true` while the panel is on the screen |
| `inventoryPanel.handleKey( action, phase )` | Handles a key action from `game/classes/controls.lua` while the panel is open |
| `inventoryPanel.refresh()` | Draws the slots and the info box again after the game adds or removes an item while the panel is open. Does nothing while it is closed. |
| `inventoryPanel.setStatus( status )` | Changes the status text while the panel is open |
| `inventoryPanel.resize()` | Stretches the dimmed background over the screen after a window size change. The game scene calls it from `onResize`. |
| `inventoryPanel.close( skipHandler )` | Removes the panel and runs `onClose`. `close( true )` skips `onClose`; a game scene uses it when the scene is being left. |

## The inventory button

`inventoryButton.new( { parent = group, onPress = openInventory } )` places a button in the top left corner, as far from the edges as the Menu button is from its corner, and calls `onPress` when it is tapped. It follows window size changes by itself. `inventoryButton.getPosition()` returns the button's centre, so the scene can place things beside it. The `inventoryButton` settings block sets its image sheet and its drawn `size`, and [ui.md](ui.md) describes the image.

## Adding an item

The steps use the top-down template's files.

1. Draw the icon as a new 64 x 64 frame at the right end of `maps/items.png`, which makes the image 256 wide with four frames.
2. In `inventory.itemSheet` in `game/data/settingsTemplate.lua`, set `frameCount` to `4`.
3. Add the item to `game/data/items.lua` with a new id, a `name`, a `description` and `frame = 4`.
4. Place it in the game, such as with an item object on a map (the template's `maps.md`), or give it through the story with `<<addItem, id>>` ([dialogue.md](dialogue.md)).

## Troubleshooting

- A slot looks empty but is taken: its item id has no entry in `game/data/items.lua`, so the panel draws no icon.
- Two items with the same object name on one map count as one: picking up either keeps both away on the next visit.
