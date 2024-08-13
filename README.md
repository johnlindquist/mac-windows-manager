# mwm (Mac Windows Manager)

mwm is a powerful macOS command-line tool that allows you to precisely control window positioning and sizing on your screen.

## Requirements

- macOS 10.15 or later
- Swift 5.5 or later

## Installation

You can download the latest release of mwm from the [Releases](https://github.com/johnlindquist/mac-windows-manager/releases) page.

After downloading, you may need to make the file executable:

```
chmod +x mwm
```

## Usage

The general syntax for using mwm is:

```
mwm <command> [width-<size>] [height-<size>]
```

### Available Commands

1. Positioning Commands:

   - `center`: Center the window on the screen
   - `left`, `right`: Position the window on the left or right side of the screen
   - `top-left`, `top-right`, `bottom-left`, `bottom-right`: Position the window in the corners of the screen
   - `center-left`, `center-top`, `center-right`, `center-bottom`: Position the window centered on each edge of the screen
   - `left-third`, `center-third`, `right-third`: Divide the screen into thirds and position the window accordingly

2. Sizing Commands:

   - `fullscreen`: Toggle fullscreen mode for the window
   - `maximize`: Maximize the window to fill the screen
   - `maximize-height`: Maximize the window's height while maintaining its width
   - `maximize-width`: Maximize the window's width while maintaining its height

3. Movement Commands:

   - `move-up`, `move-down`, `move-left`, `move-right`: Move the window to the respective edge of the screen

4. Custom Sizing:

   - `center-<percentage>`: Center the window and resize it to the specified percentage of the screen size

5. Display Movement Commands:
   - `display-next`: Move the window to the next display, maintaining its relative position and size
   - `display-previous`: Move the window to the previous display, maintaining its relative position and size

### Size Specifications

You can specify custom sizes for width and height using the following format:

- Percentage: e.g., `width-50%` (50% of screen width)
- Pixels: e.g., `height-800px` (800 pixels high)

If no size is specified, the current window size is maintained.

### Examples

1. Center the window and set it to 80% of screen width and 70% of screen height:

   ```
   mwm center width-80% height-70%
   ```

2. Move the window to the top-right corner and set its width to 1000 pixels:

   ```
   mwm top-right width-1000px
   ```

3. Position the window on the left side of the screen and maximize its height:

   ```
   mwm left maximize-height
   ```

4. Center the window and set its size to 60% of the screen:

   ```
   mwm center-60
   ```

5. Move the window to the next display:

   ```
   mwm display-next
   ```

6. Move the window to the previous display:
   ```
   mwm display-previous
   ```

### Help

You can access the help information by running the tool with the `-h` or `--help` flag:

```
mwm -h
```

or

```
mwm --help
```

This will display the available commands, size specifications, and examples.

## How it works

mwm uses the macOS Accessibility API to identify the frontmost application and its frontmost window. It then calculates the appropriate position and size based on the command and arguments provided, and applies these changes to the window.

## Permissions

This tool requires accessibility permissions to function. You may need to grant permission in System Preferences > Security & Privacy > Privacy > Accessibility.

## License

[Your chosen license, e.g., MIT License]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
