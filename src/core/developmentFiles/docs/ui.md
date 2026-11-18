# UI images

Core's options screen, in-game Menu button and inventory button are drawn from image sheets in `game/assets/images/ui/`. To restyle them, replace the images and keep each frame's size and order, or change the sheet options listed below to match a new layout. General information about the project is in the [README](../../game/README.md).

## slider.png

The three volume sliders of the options screen. The sheet is 96 by 32 pixels and holds five frames from left to right: the left end, the middle, the right end and the fill, each 16 by 32 pixels, then the handle at 32 by 32 pixels. The frames are set in `sliderSheetOptions` in `game/scenes/options.lua`, and the slider takes its frame and handle sizes from them.

## toggle.png

The Fullscreen checkbox of the options screen. The sheet is 128 by 32 pixels and holds two frames of 64 by 32 pixels side by side: off, then on. The frames are set in `toggleSheetOptions` in `game/scenes/options.lua`.

## menuButton.png

The Menu button in the top right corner of the game scene. The sheet is 256 by 48 pixels and holds two frames of 128 by 48 pixels side by side: the button as it is drawn normally, then while it is pressed. The button draws its "Menu" label on top of the image. Its settings are in the `menuButton` block of `game/data/settingsCore.lua`: `filename`, `frameWidth` and `frameHeight` for the sheet, `margin` for the distance from the screen's top and right edges, and `fontSize` for the label.

## inventoryButton.png

The inventory button in the top left corner, for a game that opens the inventory with the mouse. The sheet is 128 by 64 pixels and holds two frames of 64 by 64 pixels side by side: the button as it is drawn normally, then while it is pressed. The button draws both frames at `size` content units square, so a larger image only makes it sharper. Its settings are in the `inventoryButton` block of `game/data/settingsCore.lua`: `filename`, `frameWidth` and `frameHeight` for the sheet, and `size`. It sits as far from the screen's top and left edges as the Menu button's `margin`.

## menu.png

The same folder holds `menu.png`, the background of the menu, load and credits scenes, set in `menu.background` in `game/data/settingsCore.lua`. It is a single image, not a sheet. Core has a plain `menu.png`, and each template replaces it with its own at the same path.

## Solar2D documentation

- Sliders: [widget.newSlider()](https://docs.coronalabs.com/api/library/widget/newSlider.html), Visual Customization.
- The checkbox: [widget.newSwitch()](https://docs.coronalabs.com/api/library/widget/newSwitch.html), Visual Customization.
- The Menu button and the inventory button: [widget.newButton()](https://docs.coronalabs.com/api/library/widget/newButton.html), 2-Frame Construction.
