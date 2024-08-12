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
    
    let mouseLocation = NSEvent.mouseLocation
    guard let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) else {
        print("Unable to determine the screen with the mouse cursor.")
        return
    }
    
    guard let windowSize = getWindowSize(frontmostWindow) else {
        print("Unable to get window size.")
        return
    }
    
    let visibleFrame = targetScreen.visibleFrame
    let centerX = visibleFrame.minX + (visibleFrame.width - windowSize.width) / 2
    let centerY = visibleFrame.minY + (visibleFrame.height - windowSize.height) / 2
    
    let mainScreenHeight = NSScreen.screens[0].frame.height
    let flippedY = mainScreenHeight - (centerY + windowSize.height)
    let newPosition = CGPoint(x: centerX, y: flippedY)
    
    setWindowPosition(frontmostWindow, newPosition)
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

// MARK: - Main
if CommandLine.arguments.count > 1 {
    switch CommandLine.arguments[1] {
    case "center":
        centerFrontmostWindow()
    default:
        print("Unknown command. Available commands: center")
    }
} else {
    print("Usage: mac-windows-manager <command>")
    print("Available commands: center")
}