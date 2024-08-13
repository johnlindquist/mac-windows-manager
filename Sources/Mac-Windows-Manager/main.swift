import Foundation
import AppKit
import ApplicationServices

// MARK: - Accessibility Permissions
func requestAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
    if !accessibilityEnabled {
        print("Accessibility permission is not granted. Please enable it in System Preferences > Security & Privacy > Privacy > Accessibility.")
        return false
    }
    return true
}

// MARK: - Window Management
func centerFrontmostWindow(widthSpec: String? = nil, heightSpec: String? = nil) {
    print("--- Starting centerFrontmostWindow ---")
    print("Width spec: \(widthSpec ?? "nil"), Height spec: \(heightSpec ?? "nil")")
    guard requestAccessibilityPermission() else {
        print("Accessibility permission not granted.")
        return
    }

    guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
          let frontmostWindow = getFrontmostWindow(for: frontmostApp.processIdentifier) else {
        print("No frontmost window found.")
        return
    }
    
    print("Frontmost app: \(frontmostApp.localizedName ?? "Unknown")")
    
    guard let targetScreen = getTargetScreen(for: frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else {
        print("Unable to get window information.")
        return
    }
    
    print("Target screen: \(targetScreen)")
    print("Current window size: \(currentSize)")
    
    let visibleFrame = targetScreen.visibleFrame
    print("Screen visible frame: \(visibleFrame)")
    
    let newWidth = parseSize(spec: widthSpec, currentSize: currentSize.width, availableSize: visibleFrame.width)
    let newHeight = parseSize(spec: heightSpec, currentSize: currentSize.height, availableSize: visibleFrame.height)
    print("Parsed new width: \(newWidth), Parsed new height: \(newHeight)")
    
    let centerX = visibleFrame.minX + (visibleFrame.width - newWidth) / 2
    let centerY = visibleFrame.minY + (visibleFrame.height - newHeight) / 2
    print("Calculated center: (\(centerX), \(centerY))")
    
    let newFrame = CGRect(x: centerX, y: centerY, width: newWidth, height: newHeight)
    setWindowFrame(frontmostWindow, newFrame)
    
    // Verify the new position and size
    if let newActualPosition = getWindowPosition(frontmostWindow),
       let newActualSize = getWindowSize(frontmostWindow) {
        print("New actual position: \(newActualPosition)")
        print("New actual size: \(newActualSize)")
    } else {
        print("Unable to verify new window position and size")
    }
    
    print("--- Finished centerFrontmostWindow ---")
}

func parseSize(spec: String?, currentSize: CGFloat, availableSize: CGFloat) -> CGFloat {
    print("Parsing size - Spec: \(spec ?? "nil"), Current size: \(currentSize), Available size: \(availableSize)")
    guard let spec = spec else {
        print("No spec provided, returning current size: \(currentSize)")
        return currentSize
    }
    
    if spec.hasSuffix("%") {
        if let percentage = Double(spec.dropLast()) {
            let newSize = availableSize * CGFloat(percentage) / 100.0
            print("Parsed percentage: \(percentage)%, New size: \(newSize)")
            return newSize
        }
    } else if spec.hasSuffix("px") {
        if let pixels = Double(spec.dropLast(2)) {
            print("Parsed pixels: \(pixels)px")
            return CGFloat(pixels)
        }
    }
    
    print("Invalid size specification: \(spec). Using current size: \(currentSize)")
    return currentSize
}

enum WindowPosition {
    case left, right, topLeft, topRight, bottomLeft, bottomRight
    case centerLeft, centerTop, centerRight, centerBottom
    case custom(String)
}

func positionFrontmostWindow(position: WindowPosition, widthSpec: String? = nil, heightSpec: String? = nil) {
    guard requestAccessibilityPermission() else {
        return
    }

    guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
          let frontmostWindow = getFrontmostWindow(for: frontmostApp.processIdentifier) else {
        print("No frontmost window found.")
        return
    }
    
    guard let targetScreen = getTargetScreen(for: frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else {
        print("Unable to get window information.")
        return
    }
    
    let frame = targetScreen.frame // Use frame instead of visibleFrame to ignore the dock
    print("Screen frame: \(frame)")
    
    let newWidth = parseSize(spec: widthSpec, currentSize: currentSize.width, availableSize: frame.width)
    let newHeight = parseSize(spec: heightSpec, currentSize: currentSize.height, availableSize: frame.height)
    print("Parsed new width: \(newWidth), Parsed new height: \(newHeight)")
    
    var newFrame: CGRect
    
    switch position {
    case .left:
        newFrame = CGRect(x: frame.minX, y: frame.minY, width: newWidth, height: newHeight)
    case .right:
        newFrame = CGRect(x: frame.maxX - newWidth, y: frame.minY, width: newWidth, height: newHeight)
    case .topLeft:
        newFrame = CGRect(x: frame.minX, y: frame.maxY - newHeight, width: newWidth, height: newHeight)
    case .topRight:
        newFrame = CGRect(x: frame.maxX - newWidth, y: frame.maxY - newHeight, width: newWidth, height: newHeight)
    case .bottomLeft:
        newFrame = CGRect(x: frame.minX, y: frame.minY, width: newWidth, height: newHeight)
    case .bottomRight:
        newFrame = CGRect(x: frame.maxX - newWidth, y: frame.minY, width: newWidth, height: newHeight)
    case .centerLeft:
        newFrame = CGRect(x: frame.minX, 
                          y: frame.midY - newHeight / 2, 
                          width: newWidth, 
                          height: newHeight)
    case .centerTop:
        newFrame = CGRect(x: frame.midX - newWidth / 2, 
                          y: frame.maxY - newHeight, 
                          width: newWidth, 
                          height: newHeight)
    case .centerRight:
        newFrame = CGRect(x: frame.maxX - newWidth, 
                          y: frame.midY - newHeight / 2, 
                          width: newWidth, 
                          height: newHeight)
    case .centerBottom:
        newFrame = CGRect(x: frame.midX - newWidth / 2, 
                          y: frame.minY, 
                          width: newWidth, 
                          height: newHeight)
    case .custom(let customPosition):
        if customPosition.starts(with: "center-") {
            if let percentage = parsePercentage(from: customPosition) {
                let width = frame.width * CGFloat(percentage) / 100.0
                let height = frame.height * CGFloat(percentage) / 100.0
                let x = frame.minX + (frame.width - width) / 2
                let y = frame.minY + (frame.height - height) / 2
                newFrame = CGRect(x: x, y: y, width: width, height: height)
            } else {
                print("Invalid center percentage")
                return
            }
        } else {
            switch customPosition {
            case "left-third":
                newFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width / 3, height: frame.height)
            case "center-third":
                newFrame = CGRect(x: frame.minX + frame.width / 3, y: frame.minY, width: frame.width / 3, height: frame.height)
            case "right-third":
                newFrame = CGRect(x: frame.maxX - frame.width / 3, y: frame.minY, width: frame.width / 3, height: frame.height)
            default:
                print("Invalid position")
                return
            }
        }
    }
    
    setWindowFrame(frontmostWindow, newFrame)
}

// Helper function to parse percentage from command
func parsePercentage(from command: String) -> Int? {
    let components = command.split(separator: "-")
    guard components.count == 2, components[0] == "center",
          let percentage = Int(components[1]),
          percentage > 0 && percentage <= 100 else {
        return nil
    }
    return percentage
}

// Replace setWindowPosition and setWindowSize with this new function
func setWindowFrame(_ window: AXUIElement, _ frame: CGRect, skipYFlipping: Bool = false) {
    print("Setting window frame to: \(frame)")
    
    let mainScreen = NSScreen.screens[0]
    // Correct the Y-coordinate conversion if not skipping
    let yPosition = skipYFlipping ? frame.minY : mainScreen.frame.height - frame.maxY
    
    var position = CGPoint(x: frame.minX, y: yPosition)
    var size = frame.size
    
    guard let positionValue = AXValueCreate(.cgPoint, &position),
          let sizeValue = AXValueCreate(.cgSize, &size) else {
        print("Failed to create AXValues for position and size")
        return
    }
    
    let positionError = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
    let sizeError = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    
    if positionError != .success || sizeError != .success {
        print("Failed to set window frame. Position error: \(positionError), Size error: \(sizeError)")
    }
}

func getFrontmostWindow(for pid: pid_t) -> AXUIElement? {
    let app = AXUIElementCreateApplication(pid)
    var frontmostWindow: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &frontmostWindow)
    guard error == .success else { return nil }
    return (frontmostWindow as! AXUIElement)
}

func getWindowSize(_ window: AXUIElement) -> CGSize? {
    var sizeRef: CFTypeRef?
    guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
          CFGetTypeID(sizeRef!) == AXValueGetTypeID() else {
        return nil
    }
    
    var size = CGSize.zero
    AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
    return size
}

// New function to get window position
func getWindowPosition(_ window: AXUIElement) -> CGPoint? {
    var positionRef: CFTypeRef?
    guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
          CFGetTypeID(positionRef!) == AXValueGetTypeID() else {
        return nil
    }
    
    var position = CGPoint.zero
    AXValueGetValue(positionRef as! AXValue, .cgPoint, &position)
    return position
}

// New functions for Fullscreen and Maximize commands
func toggleFullscreen() {
    guard let frontmostWindow = getFrontmostWindowElement() else { return }
    
    AXUIElementPerformAction(frontmostWindow, "AXZoom" as CFString)
}

func maximizeWindow() {
    guard let frontmostWindow = getFrontmostWindowElement(),
          let targetScreen = getTargetScreen(for: frontmostWindow) else { return }
    
    let visibleFrame = targetScreen.visibleFrame
    setWindowFrame(frontmostWindow, visibleFrame)
}

func maximizeWindowHeight() {
    guard let frontmostWindow = getFrontmostWindowElement(),
          let targetScreen = getTargetScreen(for: frontmostWindow),
          let currentPosition = getWindowPosition(frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else { return }
    
    let visibleFrame = targetScreen.visibleFrame
    let newFrame = CGRect(x: currentPosition.x,
                          y: visibleFrame.minY,
                          width: currentSize.width,
                          height: visibleFrame.height)
    setWindowFrame(frontmostWindow, newFrame)
}

func maximizeWindowWidth() {
    guard let frontmostWindow = getFrontmostWindowElement(),
          let targetScreen = getTargetScreen(for: frontmostWindow),
          let currentPosition = getWindowPosition(frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else { return }
    
    let visibleFrame = targetScreen.visibleFrame
    let newFrame = CGRect(x: visibleFrame.minX,
                          y: currentPosition.y,
                          width: visibleFrame.width,
                          height: currentSize.height)
    setWindowFrame(frontmostWindow, newFrame)
}

// New movement functions
func moveWindowDown() {
    guard let frontmostWindow = getFrontmostWindowElement(),
          let targetScreen = getTargetScreen(for: frontmostWindow),
          let currentPosition = getWindowPosition(frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else { return }
    
    let visibleFrame = targetScreen.visibleFrame
    let newFrame = CGRect(x: currentPosition.x,
                          y: visibleFrame.minY,
                          width: currentSize.width,
                          height: currentSize.height)
    setWindowFrame(frontmostWindow, newFrame)
}

func moveWindowUp() {
    guard let frontmostWindow = getFrontmostWindowElement(),
          let targetScreen = getTargetScreen(for: frontmostWindow),
          let currentPosition = getWindowPosition(frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else { return }
    
    let visibleFrame = targetScreen.visibleFrame
    let newFrame = CGRect(x: currentPosition.x,
                          y: (visibleFrame.maxY - currentSize.height),
                          width: currentSize.width,
                          height: currentSize.height)
    setWindowFrame(frontmostWindow, newFrame)
}

func moveWindowLeft() {
    guard let frontmostWindow = getFrontmostWindowElement(),
          let targetScreen = getTargetScreen(for: frontmostWindow),
          let currentPosition = getWindowPosition(frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else { return }
    
    let visibleFrame = targetScreen.visibleFrame
    let newFrame = CGRect(x: visibleFrame.minX,
                          y: currentPosition.y,
                          width: currentSize.width,
                          height: currentSize.height)
    setWindowFrame(frontmostWindow, newFrame, skipYFlipping: true)
}

func moveWindowRight() {
    guard let frontmostWindow = getFrontmostWindowElement(),
          let targetScreen = getTargetScreen(for: frontmostWindow),
          let currentPosition = getWindowPosition(frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else { return }
    
    let visibleFrame = targetScreen.visibleFrame
    let newFrame = CGRect(x: visibleFrame.maxX - currentSize.width,
                          y: currentPosition.y,
                          width: currentSize.width,
                          height: currentSize.height)
    setWindowFrame(frontmostWindow, newFrame, skipYFlipping: true)
}

// Helper functions
func getFrontmostWindowElement() -> AXUIElement? {
    guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
          let frontmostWindow = getFrontmostWindow(for: frontmostApp.processIdentifier) else {
        print("No frontmost window found.")
        return nil
    }
    return frontmostWindow
}

// Update this function to use visibleFrame instead of frame
func getTargetScreen(for window: AXUIElement) -> NSScreen? {
    guard let windowPosition = getWindowPosition(window) else {
        print("Unable to get window position.")
        return nil
    }
    
    let mainScreenHeight = NSScreen.screens[0].visibleFrame.height
    let screenPosition = CGPoint(x: windowPosition.x, y: mainScreenHeight - windowPosition.y)
    
    guard let targetScreen = NSScreen.screens.first(where: { $0.visibleFrame.contains(screenPosition) }) else {
        print("Unable to determine the screen with the frontmost window.")
        print("Available screens:")
        for (index, screen) in NSScreen.screens.enumerated() {
            print("Screen \(index): \(screen.visibleFrame)")
        }
        return nil
    }
    
    return targetScreen
}

func moveWindowToNextDisplay() {
    moveWindowToAdjacentDisplay(forward: true)
}

func moveWindowToPreviousDisplay() {
    moveWindowToAdjacentDisplay(forward: false)
}

// Update moveWindowToAdjacentDisplay function
func moveWindowToAdjacentDisplay(forward: Bool) {
    guard let frontmostWindow = getFrontmostWindowElement(),
          let currentScreen = getTargetScreen(for: frontmostWindow),
          let currentPosition = getWindowPosition(frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else {
        print("Unable to get window information.")
        return
    }

    let screens = NSScreen.screens
    guard let currentIndex = screens.firstIndex(of: currentScreen) else {
        print("Current screen not found in screen list.")
        return
    }

    let nextIndex = forward ? (currentIndex + 1) % screens.count : (currentIndex - 1 + screens.count) % screens.count
    let nextScreen = screens[nextIndex]

    let currentVisibleFrame = currentScreen.visibleFrame
    let nextVisibleFrame = nextScreen.visibleFrame

    // Calculate relative position
    let relativeX = (currentPosition.x - currentVisibleFrame.minX) / currentVisibleFrame.width
    let relativeY = (currentPosition.y - currentVisibleFrame.minY) / currentVisibleFrame.height

    // Calculate new position on next screen
    var newX = nextVisibleFrame.minX + relativeX * nextVisibleFrame.width
    var newY = nextVisibleFrame.minY + relativeY * nextVisibleFrame.height

    // Calculate new size, constrained to next screen's bounds
    let newWidth = min(currentSize.width, nextVisibleFrame.width)
    let newHeight = min(currentSize.height, nextVisibleFrame.height)

    // Adjust position if the window would be partially off-screen
    newX = max(nextVisibleFrame.minX, min(newX, nextVisibleFrame.maxX - newWidth))
    newY = max(nextVisibleFrame.minY, min(newY, nextVisibleFrame.maxY - newHeight))

    // Set new position and size
    let newFrame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    setWindowFrame(frontmostWindow, newFrame)
}

func listAvailableScreens() {
    let screens = NSScreen.screens
    print("Available screens:")
    for (index, screen) in screens.enumerated() {
        let screenNumber = index + 1
        let frame = screen.frame
        let visibleFrame = screen.visibleFrame
        let scale = screen.backingScaleFactor
        
        print("Screen \(screenNumber):")
        print("  Frame: \(frame)")
        print("  Visible Frame: \(visibleFrame)")
        print("  Scale Factor: \(scale)")
        
        if screen == NSScreen.main {
            print("  (Main Display)")
        }

        let localizedName = screen.localizedName
        print("  Name: \(localizedName)")

        print() // Empty line for better readability
    }
}

func applyPreset(monitor: Int? = nil, splitType: String, appConfigs: [(String, Double)]) {
    let screens = NSScreen.screens
    let targetScreen: NSScreen
    if let monitor = monitor, monitor > 0 && monitor <= screens.count {
        targetScreen = screens[monitor - 1]
    } else {
        targetScreen = screens[0] // Default to main screen
    }
    
    let visibleFrame = targetScreen.visibleFrame
    var currentPosition: CGFloat = 0.0

    for (appName, percentage) in appConfigs {
        print("Processing app: \(appName) with \(percentage)% of space")
        
        // Open the app or bring it to front if already running
        let openTask = Process()
        openTask.launchPath = "/usr/bin/open"
        openTask.arguments = ["-a", appName]
        openTask.launch()
        openTask.waitUntilExit()
        
        // Wait for the app to launch or come to foreground
        Thread.sleep(forTimeInterval: 1.0)
        
        // Get the frontmost window
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let frontmostWindow = getFrontmostWindow(for: frontmostApp.processIdentifier) else {
            print("Failed to get window for \(appName)")
            continue
        }
        
        // Check if the window is in full-screen mode and attempt to exit if it is
        var isFullScreen: CFTypeRef?
        AXUIElementCopyAttributeValue(frontmostWindow, "AXFullScreen" as CFString, &isFullScreen)
        if let isFullScreen = isFullScreen as? Bool, isFullScreen {
            print("App is in full-screen mode. Attempting to exit...")
            AXUIElementSetAttributeValue(frontmostWindow, "AXFullScreen" as CFString, false as CFTypeRef)
            Thread.sleep(forTimeInterval: 1.0) // Wait for full-screen exit animation
        }
        
        // Calculate new frame
        let newSize: CGSize
        let newOrigin: CGPoint
        if splitType.lowercased() == "horizontal" {
            let width = visibleFrame.width * CGFloat(percentage / 100.0)
            newSize = CGSize(width: width, height: visibleFrame.height)
            newOrigin = CGPoint(x: visibleFrame.minX + currentPosition, y: visibleFrame.minY)
            currentPosition += width
        } else { // vertical
            let height = visibleFrame.height * CGFloat(percentage / 100.0)
            newSize = CGSize(width: visibleFrame.width, height: height)
            newOrigin = CGPoint(x: visibleFrame.minX, y: visibleFrame.minY + currentPosition)
            currentPosition += height
        }
        
        let newFrame = CGRect(origin: newOrigin, size: newSize)
        setWindowFrame(frontmostWindow, newFrame)
        
        // Verify if the window was resized and repositioned correctly
        if let actualPosition = getWindowPosition(frontmostWindow),
           let actualSize = getWindowSize(frontmostWindow) {
            if actualPosition != newOrigin || actualSize != newSize {
                print("Warning: Window for \(appName) may not have been positioned or sized correctly.")
                print("Expected: origin \(newOrigin), size \(newSize)")
                print("Actual: origin \(actualPosition), size \(actualSize)")
            }
        }
    }
}

// MARK: - Main
func printHelp() {
    print("""
    Usage: mwm <command> [width-<size>] [height-<size>]

    Available commands:
      Positioning:
        center               Center the window on the screen
        left, right          Position the window on the left or right side of the screen
        top-left, top-right, bottom-left, bottom-right
                             Position the window in the corners of the screen
        center-left, center-top, center-right, center-bottom
                             Position the window centered on each edge of the screen
        left-third, center-third, right-third
                             Divide the screen into thirds and position the window accordingly

      Sizing:
        fullscreen           Toggle fullscreen mode for the window
        maximize             Maximize the window to fill the screen
        maximize-height      Maximize the window's height while maintaining its width
        maximize-width       Maximize the window's width while maintaining its height

      Movement:
        move-up, move-down, move-left, move-right
                             Move the window to the respective edge of the screen

      Display Movement:
        display-next         Move the window to the next display
        display-previous     Move the window to the previous display

      Custom:
        center-<percentage>  Center the window and resize it to the specified percentage of the screen size

    Size specifications:
      width-<size>, height-<size>
        <size> can be specified as a percentage (e.g., 50%) or in pixels (e.g., 500px)
        If not specified, the current window size is maintained.

    Examples:
      mwm center width-80% height-70%
      mwm top-right width-1000px
      mwm left maximize-height
      mwm center-60

    Note: This tool requires accessibility permissions to function.
    """)
}

if CommandLine.arguments.count > 1 {
    let command = CommandLine.arguments[1].lowercased() // Convert to lowercase for case-insensitive matching
    var widthSpec: String?
    var heightSpec: String?
    
    // Check for help flags first
    if command == "-h" || command == "--help" || command == "help" {
        printHelp()
        exit(0)
    }
    
    for arg in CommandLine.arguments.dropFirst(2) {
        let parts = arg.split(separator: "-")
        if parts.count == 2 {
            if parts[0] == "width" {
                widthSpec = String(parts[1])
            } else if parts[0] == "height" {
                heightSpec = String(parts[1])
            }
        }
    }
    
    print("Parsed width spec: \(widthSpec ?? "nil"), height spec: \(heightSpec ?? "nil")")
    
    switch command {
    case "center":
        centerFrontmostWindow(widthSpec: widthSpec, heightSpec: heightSpec)
    case "left":
        positionFrontmostWindow(position: .left, widthSpec: widthSpec, heightSpec: heightSpec)
    case "right":
        positionFrontmostWindow(position: .right, widthSpec: widthSpec, heightSpec: heightSpec)
    case "top-left":
        positionFrontmostWindow(position: .topLeft, widthSpec: widthSpec, heightSpec: heightSpec)
    case "top-right":
        positionFrontmostWindow(position: .topRight, widthSpec: widthSpec, heightSpec: heightSpec)
    case "bottom-left":
        positionFrontmostWindow(position: .bottomLeft, widthSpec: widthSpec, heightSpec: heightSpec)
    case "bottom-right":
        positionFrontmostWindow(position: .bottomRight, widthSpec: widthSpec, heightSpec: heightSpec)
    case "center-left":
        positionFrontmostWindow(position: .centerLeft, widthSpec: widthSpec, heightSpec: heightSpec)
    case "center-top":
        positionFrontmostWindow(position: .centerTop, widthSpec: widthSpec, heightSpec: heightSpec)
    case "center-right":
        positionFrontmostWindow(position: .centerRight, widthSpec: widthSpec, heightSpec: heightSpec)
    case "center-bottom":
        positionFrontmostWindow(position: .centerBottom, widthSpec: widthSpec, heightSpec: heightSpec)
    case "left-third", "center-third", "right-third":
        positionFrontmostWindow(position: .custom(command), widthSpec: nil, heightSpec: nil)
    case "fullscreen":
        toggleFullscreen()
    case "maximize":
        maximizeWindow()
    case "maximize-height":
        maximizeWindowHeight()
    case "maximize-width":
        maximizeWindowWidth()
    case "move-up":
        moveWindowUp()
    case "move-down":
        moveWindowDown()
    case "move-left":
        moveWindowLeft()
    case "move-right":
        moveWindowRight()
    case "display-next":
        moveWindowToNextDisplay()
    case "display-previous":
        moveWindowToPreviousDisplay()
    case "list-screens":
        listAvailableScreens()
    case "preset":
        if CommandLine.arguments.count < 5 {
            print("Usage: mwm preset [monitor] <split-type> <app1>:<percentage> <app2>:<percentage> ...")
            exit(1)
        }
        
        var argIndex = 2
        var monitor: Int? = nil
        if let monitorArg = Int(CommandLine.arguments[argIndex]) {
            monitor = monitorArg
            argIndex += 1
        }
        
        let splitType = CommandLine.arguments[argIndex]
        argIndex += 1
        
        var appConfigs: [(String, Double)] = []
        for arg in CommandLine.arguments[argIndex...] {
            let parts = arg.split(separator: ":")
            if parts.count == 2, let percentage = Double(parts[1]) {
                appConfigs.append((String(parts[0]), percentage))
            }
        }
        
        applyPreset(monitor: monitor, splitType: splitType, appConfigs: appConfigs)    
    default:
        if command.starts(with: "center-") {
            positionFrontmostWindow(position: .custom(command), widthSpec: nil, heightSpec: nil)
        } else {
            print("Unknown command. Use -h or --help for usage information.")
            printHelp()
        }
    }
} else {
    printHelp()
}