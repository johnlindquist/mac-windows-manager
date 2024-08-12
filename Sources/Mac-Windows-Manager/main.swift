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
    
    // Convert the y-coordinate to the coordinate system used by the Accessibility API
    let flippedCenterY = NSScreen.screens[0].frame.height - (centerY + newHeight)
    print("Flipped center Y: \(flippedCenterY)")
    
    let newPosition = CGPoint(x: centerX, y: flippedCenterY)
    print("New position: \(newPosition)")
    
    if let currentPosition = getWindowPosition(frontmostWindow) {
        print("Current window position: \(currentPosition)")
    } else {
        print("Unable to get current window position")
    }
    
    setWindowPosition(frontmostWindow, newPosition)
    setWindowSize(frontmostWindow, CGSize(width: newWidth, height: newHeight))
    
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

// Modified window positioning function
func positionFrontmostWindow(position: String) {
    guard requestAccessibilityPermission() else {
        return
    }

    guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
          let frontmostWindow = getFrontmostWindow(for: frontmostApp.processIdentifier) else {
        print("No frontmost window found.")
        return
    }
    
    guard let windowPosition = getWindowPosition(frontmostWindow) else {
        print("Unable to get window position.")
        return
    }
    
    // Debug print
    print("Window position: \(windowPosition)")
    
    // Convert window position to screen coordinates
    let mainScreenHeight = NSScreen.screens[0].frame.height
    let screenPosition = CGPoint(x: windowPosition.x, y: mainScreenHeight - windowPosition.y)
    
    // Debug print
    print("Converted screen position: \(screenPosition)")
    
    guard let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(screenPosition) }) else {
        print("Unable to determine the screen with the frontmost window.")
        print("Available screens:")
        for (index, screen) in NSScreen.screens.enumerated() {
            print("Screen \(index): \(screen.frame)")
        }
        return
    }
    
    guard getWindowSize(frontmostWindow) != nil else {
        print("Unable to get window size.")
        return
    }
    
    let visibleFrame = targetScreen.visibleFrame
    var newFrame = CGRect.zero
    
    if position.starts(with: "center-") {
        if let percentage = parsePercentage(from: position) {
            let width = visibleFrame.width * CGFloat(percentage) / 100.0
            let height = visibleFrame.height * CGFloat(percentage) / 100.0
            let x = visibleFrame.minX + (visibleFrame.width - width) / 2
            let y = visibleFrame.minY + (visibleFrame.height - height) / 2
            newFrame = CGRect(x: x, y: y, width: width, height: height)
        } else {
            print("Invalid center percentage")
            return
        }
    } else {
        switch position {
        case "left":
            newFrame = CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width / 2, height: visibleFrame.height)
        case "right":
            newFrame = CGRect(x: visibleFrame.midX, y: visibleFrame.minY, width: visibleFrame.width / 2, height: visibleFrame.height)
        case "left-third":
            newFrame = CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width / 3, height: visibleFrame.height)
        case "center-third":
            newFrame = CGRect(x: visibleFrame.minX + visibleFrame.width / 3, y: visibleFrame.minY, width: visibleFrame.width / 3, height: visibleFrame.height)
        case "right-third":
            newFrame = CGRect(x: visibleFrame.maxX - visibleFrame.width / 3, y: visibleFrame.minY, width: visibleFrame.width / 3, height: visibleFrame.height)
        default:
            print("Invalid position")
            return
        }
    }
    
    let flippedY = mainScreenHeight - (newFrame.maxY)
    let newPosition = CGPoint(x: newFrame.minX, y: flippedY)
    
    setWindowPosition(frontmostWindow, newPosition)
    setWindowSize(frontmostWindow, CGSize(width: newFrame.width, height: newFrame.height))
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

func setWindowSize(_ window: AXUIElement, _ size: CGSize) {
    print("Setting window size to: \(size)")
    var sizeCopy = size
    guard let sizeValue = AXValueCreate(.cgSize, &sizeCopy) else {
        print("Failed to create AXValue for size")
        return
    }
    let error = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    if error != .success {
        print("Failed to set window size. Error: \(error)")
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

func setWindowPosition(_ window: AXUIElement, _ position: CGPoint) {
    print("Setting window position to: \(position)")
    var positionCopy = position
    guard let positionValue = AXValueCreate(.cgPoint, &positionCopy) else {
        print("Failed to create AXValue for position")
        return
    }
    let error = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
    if error != .success {
        print("Failed to set window position. Error: \(error)")
    }
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
func moveWindowUp() {
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

func moveWindowDown() {
    guard let frontmostWindow = getFrontmostWindowElement(),
          let targetScreen = getTargetScreen(for: frontmostWindow),
          let currentPosition = getWindowPosition(frontmostWindow),
          let currentSize = getWindowSize(frontmostWindow) else { return }
    
    let visibleFrame = targetScreen.visibleFrame
    let newFrame = CGRect(x: currentPosition.x,
                          y: visibleFrame.maxY - currentSize.height,
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
    setWindowFrame(frontmostWindow, newFrame)
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
    setWindowFrame(frontmostWindow, newFrame)
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

func getTargetScreen(for window: AXUIElement) -> NSScreen? {
    guard let windowPosition = getWindowPosition(window) else {
        print("Unable to get window position.")
        return nil
    }
    
    let mainScreenHeight = NSScreen.screens[0].frame.height
    let screenPosition = CGPoint(x: windowPosition.x, y: mainScreenHeight - windowPosition.y)
    
    guard let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(screenPosition) }) else {
        print("Unable to determine the screen with the frontmost window.")
        return nil
    }
    
    return targetScreen
}

func setWindowFrame(_ window: AXUIElement, _ frame: CGRect) {
    let flippedY = NSScreen.screens[0].frame.height - (frame.maxY)
    setWindowPosition(window, CGPoint(x: frame.minX, y: flippedY))
    setWindowSize(window, CGSize(width: frame.width, height: frame.height))
}

// MARK: - Main
if CommandLine.arguments.count > 1 {
    let command = CommandLine.arguments[1]
    if command == "center" {
        var widthSpec: String?
        var heightSpec: String?
        
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
        centerFrontmostWindow(widthSpec: widthSpec, heightSpec: heightSpec)
    } else {
        switch command {
        case "left", "right", "left-third", "center-third", "right-third":
            positionFrontmostWindow(position: command)
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
        default:
            if command.starts(with: "center-") {
                positionFrontmostWindow(position: command)
            } else {
                print("Unknown command. Available commands: center [width-<size>] [height-<size>], left, right, left-third, center-third, right-third, center-[percentage], fullscreen, maximize, maximize-height, maximize-width, move-up, move-down, move-left, move-right")
            }
        }
    }
} else {
    print("Usage: mac-windows-manager <command>")
    print("Available commands: center [width-<size>] [height-<size>], left, right, left-third, center-third, right-third, center-[percentage], fullscreen, maximize, maximize-height, maximize-width, move-up, move-down, move-left, move-right")
    print("Size can be specified as a percentage (e.g., 50%) or in pixels (e.g., 500px)")
}