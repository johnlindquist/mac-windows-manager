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

// New window positioning functions
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
    
    let flippedY = mainScreenHeight - (newFrame.maxY)
    let newPosition = CGPoint(x: newFrame.minX, y: flippedY)
    
    setWindowPosition(frontmostWindow, newPosition)
    setWindowSize(frontmostWindow, CGSize(width: newFrame.width, height: newFrame.height))
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

// MARK: - Main
if CommandLine.arguments.count > 1 {
    switch CommandLine.arguments[1] {
    case "center":
        centerFrontmostWindow()
    case "left":
        positionFrontmostWindow(position: "left")
    case "right":
        positionFrontmostWindow(position: "right")
    case "left-third":
        positionFrontmostWindow(position: "left-third")
    case "center-third":
        positionFrontmostWindow(position: "center-third")
    case "right-third":
        positionFrontmostWindow(position: "right-third")
    default:
        print("Unknown command. Available commands: center, left, right, left-third, center-third, right-third")
    }
} else {
    print("Usage: mac-windows-manager <command>")
    print("Available commands: center, left, right, left-third, center-third, right-third")
}