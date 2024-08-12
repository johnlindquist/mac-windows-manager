# Mac-Windows-Manager

Mac-Windows-Manager is a macOS command-line tool that allows you to center the frontmost window on the screen where the mouse cursor is located.

## Requirements

- macOS 10.15 or later
- Swift 5.5 or later

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/Mac-Windows-Manager.git
   ```
2. Navigate to the project directory:
   ```
   cd Mac-Windows-Manager
   ```
3. Build the project:
   ```
   swift build -c release
   ```
4. The executable will be located at `.build/release/Mac-Windows-Manager`. You can move it to a directory in your PATH for easy access.

## Usage

To center the frontmost window:

```
mac-windows-manager center
```

## How it works

Mac-Windows-Manager uses the macOS Accessibility API to identify the frontmost application and its frontmost window. It then calculates the center position of the screen where the mouse cursor is located and moves the window to that position.

## Permissions

This tool requires accessibility permissions to function. You may need to grant permission in System Preferences > Security & Privacy > Privacy > Accessibility.

## License

[Your chosen license, e.g., MIT License]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.