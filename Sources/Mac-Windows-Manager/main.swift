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
func centerFrontmostWindow() {
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
    
    guard let windowSize = getWindowSize(frontmostWindow) else {
        print("Unable to get window size.")
        return
    }
    
    let visibleFrame = targetScreen.visibleFrame
    let centerX = visibleFrame.minX + (visibleFrame.width - windowSize.width) / 2
    let centerY = visibleFrame.minY + (visibleFrame.height - windowSize.height) / 2
    
    let flippedY = mainScreenHeight - (centerY + windowSize.height)
    let newPosition = CGPoint(x: centerX, y: flippedY)
    
    setWindowPosition(frontmostWindow, newPosition)
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
    var sizeCopy = size
    guard let sizeValue = AXValueCreate(.cgSize, &sizeCopy) else { return }
    AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
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
    var positionCopy = position
    guard let positionValue = AXValueCreate(.cgPoint, &positionCopy) else { return }
    AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
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
    setWindowPosition(window, CGPoint(x: frame.minX, y: frame.minY))
    setWindowSize(window, CGSize(width: frame.width, height: frame.height))
}

// MARK: - Main
if CommandLine.arguments.count > 1 {
    let command = CommandLine.arguments[1]
    if command.starts(with: "center-") {
        positionFrontmostWindow(position: command)
    } else {
        switch command {
        case "center":
            centerFrontmostWindow()
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
            print("Unknown command. Available commands: center, left, right, left-third, center-third, right-third, center-[percentage], fullscreen, maximize, maximize-height, maximize-width, move-up, move-down, move-left, move-right")
        }
    }
} else {
    print("Usage: mac-windows-manager <command>")
    print("Available commands: center, left, right, left-third, center-third, right-third, center-[percentage], fullscreen, maximize, maximize-height, maximize-width, move-up, move-down, move-left, move-right")
}