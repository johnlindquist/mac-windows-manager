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
func setWindowFrame(_ window: AXUIElement, _ frame: CGRect) {
    print("Setting window frame to: \(frame)")
    
    let mainScreen = NSScreen.screens[0]
    // Always flip Y coordinate from macOS coordinate system
    let flippedY = mainScreen.frame.height - frame.maxY
    
    var position = CGPoint(x: frame.minX, y: flippedY)
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

// Helper function to calculate the squared distance between two points
func distanceSq(p1: CGPoint, p2: CGPoint) -> CGFloat {
    let dx = p1.x - p2.x
    let dy = p1.y - p2.y
    return dx * dx + dy * dy
}

// Helper function to calculate the shortest squared distance from a point to a rectangle
func distanceSqToRect(point: CGPoint, rect: CGRect) -> CGFloat {
    let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
    let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
    return dx * dx + dy * dy
}

// Updated function to find the target screen, with fallback to nearest screen
func getTargetScreen(for window: AXUIElement) -> NSScreen? {
    guard let windowPosition = getWindowPosition(window), // AX coords (top-left origin)
          let windowSize = getWindowSize(window) else {
        print("Error: Unable to get window position or size.")
        return nil
    }

    // Calculate window center in AX coordinates
    let windowCenterAX = CGPoint(x: windowPosition.x + windowSize.width / 2,
                                 y: windowPosition.y + windowSize.height / 2)

    // Convert window center to NS coordinates (bottom-left origin) for screen comparison
    // We need *a* screen's height for conversion; main screen is usually sufficient reference
    // unless coordinate systems are wildly different (unlikely for standard setups).
    let mainScreenHeight = NSScreen.screens.first?.frame.height ?? 0
    let windowCenterNS = CGPoint(x: windowCenterAX.x,
                                 y: mainScreenHeight - windowCenterAX.y)

    print("Debug: Window AX Position: \(windowPosition), AX Center: \(windowCenterAX), NS Center: \(windowCenterNS)")

    // First attempt: Find screen containing the window's center point (NS coords)
    if let containingScreen = NSScreen.screens.first(where: { $0.frame.contains(windowCenterNS) }) {
         print("Debug: Found screen containing window center directly: \(containingScreen.localizedName)")
         return containingScreen
    }

    // Fallback: Find the closest screen if the center isn't strictly inside any screen frame
    print("Debug: Window center not directly inside any screen frame. Falling back to nearest screen calculation.")

    var closestScreen: NSScreen? = nil
    var minDistanceSq: CGFloat = .greatestFiniteMagnitude

    for screen in NSScreen.screens {
        // Calculate distance from window center (NS coords) to the screen's frame rectangle
        let distSq = distanceSqToRect(point: windowCenterNS, rect: screen.frame)
        print("Debug: DistanceSq to screen '\(screen.localizedName)' (\(screen.frame)): \(distSq)")

        if distSq < minDistanceSq {
            minDistanceSq = distSq
            closestScreen = screen
             print("Debug: New closest screen found: \(screen.localizedName) (DistanceSq: \(minDistanceSq))")
        }
    }

    if let foundScreen = closestScreen {
         print("Debug: Determined closest screen via fallback: \(foundScreen.localizedName)")
    } else {
         print("Error: Could not determine closest screen. No screens available?")
    }

    return closestScreen
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

// Helper function to get the CGRect for a window element
// Handles the coordinate system conversion (AX uses top-left origin, CGRect often uses bottom-left)
func getFrame(for window: AXUIElement) -> CGRect? {
    guard let position = getWindowPosition(window),
          let size = getWindowSize(window) else {
        print("Debug: Failed to get position or size for window in getFrame.")
        return nil
    }

    // Convert AX Top-Left based Y coordinate to Bottom-Left based Y coordinate
    // Assuming screen[0] is representative enough for height calculation,
    // might need refinement if dealing with drastically different screen setups in edge cases.
    let mainScreenHeight = NSScreen.screens.first?.frame.height ?? 0
    let flippedY = mainScreenHeight - position.y - size.height

    let frame = CGRect(x: position.x, y: flippedY, width: size.width, height: size.height)
    print("Debug: Calculated frame for window: \(frame)")
    return frame
}

// Function to get the frames of all other relevant windows on a specific screen
func getOtherWindowFramesOnScreen(_ targetScreen: NSScreen, excluding activeWindow: AXUIElement) -> [CGRect] {
    var windowFrames: [CGRect] = []
    let runningApps = NSWorkspace.shared.runningApplications
    let ownPID = NSWorkspace.shared.frontmostApplication?.processIdentifier // Get PID of the currently active app

    print("Debug: Getting other windows on screen: \(targetScreen.localizedName)")

    for app in runningApps {
        // Skip the frontmost application itself
        if app.processIdentifier == ownPID {
            // print("Debug: Skipping self: \(app.localizedName ?? "Unknown")")
            continue
        }

        // Skip apps that aren't regular foreground apps (like background agents)
        if app.activationPolicy != .regular {
             // print("Debug: Skipping non-regular app: \(app.localizedName ?? "Unknown")")
            continue
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

        if error == .success, let windows = windowsRef as? [AXUIElement] {
            for window in windows {
                // Important: Skip the window if it's the same as the active one we're manipulating
                if window == activeWindow {
                    // print("Debug: Skipping the active window itself.")
                    continue
                }

                // Check if minimized
                var isMinimizedRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &isMinimizedRef)
                if let isMinimized = isMinimizedRef as? Bool, isMinimized {
                    // print("Debug: Skipping minimized window.")
                    continue
                }

                // Attempt to get the frame
                guard let frame = getFrame(for: window) else {
                    // print("Debug: Skipping window - could not get frame.")
                    continue
                }

                // Check if the window's center is on the target screen's *visible* frame
                // Using visibleFrame avoids issues with menu bars/docks
                let windowCenter = CGPoint(x: frame.midX, y: frame.midY)
                if targetScreen.visibleFrame.contains(windowCenter) {
                    print("Debug: Found relevant window for app '\(app.localizedName ?? "Unknown")' with frame: \(frame)")
                    windowFrames.append(frame)
                } else {
                     // print("Debug: Skipping window not on target screen. Center: \(windowCenter), Screen Visible Frame: \(targetScreen.visibleFrame)")
                }
            }
        } else if error != .success {
             // print("Debug: Error getting windows for app \(app.localizedName ?? "Unknown"): \(error.rawValue)")
        }
    }
    print("Debug: Found \(windowFrames.count) other relevant window frames on screen.")
    return windowFrames
}

// Finds the X-coordinate of the leftmost edge among windows strictly to the right of the active frame
func findNearestLeftEdge(to activeFrame: CGRect, in otherFrames: [CGRect]) -> CGFloat? {
    var nearestX: CGFloat? = nil
    let activeRightEdge = activeFrame.maxX

    print("Debug: Finding nearest left edge to the right of \(activeRightEdge)")

    for otherFrame in otherFrames {
        let otherLeftEdge = otherFrame.minX
        // Check if the other window is strictly to the right
        if otherLeftEdge > activeRightEdge {
            print("Debug: Considering window to the right with left edge at \(otherLeftEdge)")
            // If this is the first one found, or it's closer than the current nearest
            if nearestX == nil || otherLeftEdge < nearestX! {
                nearestX = otherLeftEdge
                print("Debug: Found new nearest left edge: \(nearestX!)")
            }
        }
    }
    if nearestX == nil { print("Debug: No window found strictly to the right.") }
    return nearestX
}

// Finds the X-coordinate of the rightmost edge among windows strictly to the left of the active frame
func findNearestRightEdge(to activeFrame: CGRect, in otherFrames: [CGRect]) -> CGFloat? {
    var nearestX: CGFloat? = nil
    let activeLeftEdge = activeFrame.minX

    print("Debug: Finding nearest right edge to the left of \(activeLeftEdge)")

    for otherFrame in otherFrames {
        let otherRightEdge = otherFrame.maxX
        // Check if the other window is strictly to the left
        if otherRightEdge < activeLeftEdge {
             print("Debug: Considering window to the left with right edge at \(otherRightEdge)")
            // If this is the first one found, or it's closer than the current nearest
            if nearestX == nil || otherRightEdge > nearestX! {
                nearestX = otherRightEdge
                print("Debug: Found new nearest right edge: \(nearestX!)")
            }
        }
    }
     if nearestX == nil { print("Debug: No window found strictly to the left.") }
    return nearestX
}

// MARK: - Command Implementations

// Performs the "snap right" action
func performSnapRight() {
    print("--- Starting performSnapRight ---")
    guard requestAccessibilityPermission() else { return }

    guard let activeWindow = getFrontmostWindowElement(),
          let activeFrame = getFrame(for: activeWindow), // Use our new helper
          let targetScreen = getTargetScreen(for: activeWindow) else {
        print("Error: Could not get active window, its frame, or its screen.")
        print("--- Aborted performSnapRight ---")
        return
    }

    print("Debug: Active window frame: \(activeFrame)")
    let otherFrames = getOtherWindowFramesOnScreen(targetScreen, excluding: activeWindow)

    if let nearestLeftEdgeX = findNearestLeftEdge(to: activeFrame, in: otherFrames) {
        let newWidth = nearestLeftEdgeX - activeFrame.minX
        if newWidth <= 0 {
             print("Error: Calculated negative or zero width (\(newWidth)). Aborting snap.")
             print("--- Aborted performSnapRight ---")
             return
        }
        // Construct the new frame using the original top-left Y (which getFrame converted for us)
        // and the original height. setWindowFrame will handle the Y-flip back to AX coordinates.
        let newFrame = CGRect(x: activeFrame.minX, y: activeFrame.minY, width: newWidth, height: activeFrame.height)

        print("Debug: Snapping right. Current frame: \(activeFrame), Target left edge: \(nearestLeftEdgeX)")
        print("Debug: Calculated New Frame (bottom-left origin): \(newFrame)")
        setWindowFrame(activeWindow, newFrame)
    } else {
        print("No window found to the right to snap to.")
    }
     print("--- Finished performSnapRight ---")
}

// Performs the "snap left" action
func performSnapLeft() {
    print("--- Starting performSnapLeft ---")
    guard requestAccessibilityPermission() else { return }

     guard let activeWindow = getFrontmostWindowElement(),
          let activeFrame = getFrame(for: activeWindow), // Use our new helper
          let targetScreen = getTargetScreen(for: activeWindow) else {
        print("Error: Could not get active window, its frame, or its screen.")
        print("--- Aborted performSnapLeft ---")
        return
    }

    print("Debug: Active window frame: \(activeFrame)")
    let otherFrames = getOtherWindowFramesOnScreen(targetScreen, excluding: activeWindow)

    if let nearestRightEdgeX = findNearestRightEdge(to: activeFrame, in: otherFrames) {
        let newX = nearestRightEdgeX
        let newWidth = activeFrame.maxX - newX
        if newWidth <= 0 {
             print("Error: Calculated negative or zero width (\(newWidth)). Aborting snap.")
             print("--- Aborted performSnapLeft ---")
             return
        }
        // Construct the new frame using the calculated left X, original top-left Y,
        // new width, and original height. setWindowFrame will handle the Y-flip.
        let newFrame = CGRect(x: newX, y: activeFrame.minY, width: newWidth, height: activeFrame.height)

        print("Debug: Snapping left. Current frame: \(activeFrame), Target right edge: \(nearestRightEdgeX)")
        print("Debug: Calculated New Frame (bottom-left origin): \(newFrame)")
        setWindowFrame(activeWindow, newFrame)
    } else {
        print("No window found to the left to snap to.")
    }
     print("--- Finished performSnapLeft ---")
}

// MARK: - Window enumeration for organize commands

struct WindowInfo {
    let app: NSRunningApplication
    let element: AXUIElement
    let frame: CGRect
}

func getWindowsOnScreen(_ targetScreen: NSScreen, includeActive: Bool = true) -> [WindowInfo] {
    var results: [WindowInfo] = []
    let running = NSWorkspace.shared.runningApplications
    let ownPID = includeActive ? nil : NSWorkspace.shared.frontmostApplication?.processIdentifier

    for app in running where app.activationPolicy == .regular {
        if let own = ownPID, app.processIdentifier == own { continue }
        let appEl = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appEl, kAXWindowsAttribute as CFString, &windowsRef) != .success { continue }
        guard let windows = windowsRef as? [AXUIElement] else { continue }

        for win in windows {
            var minimizedRef: CFTypeRef?
            AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &minimizedRef)
            if let isMin = minimizedRef as? Bool, isMin { continue }
            guard let frame = getFrame(for: win) else { continue }
            let center = CGPoint(x: frame.midX, y: frame.midY)
            if targetScreen.visibleFrame.contains(center) {
                results.append(WindowInfo(app: app, element: win, frame: frame))
            }
        }
    }

    // Optionally include the frontmost window last (so it lands top-left in grid/cascade)
    if includeActive, let active = getFrontmostWindowElement(),
       let frame = getFrame(for: active),
       let app = NSWorkspace.shared.frontmostApplication,
       let screen = getTargetScreen(for: active),
       screen == targetScreen {
        results.append(WindowInfo(app: app, element: active, frame: frame))
    }
    return results
}

// MARK: - Arrange helpers

func arrangeGrid(cols: Int, rows: Int, gap: CGFloat = 0) {
    guard let active = getFrontmostWindowElement(),
          let screen = getTargetScreen(for: active) else { return }
    let visible = screen.visibleFrame
    let windows = getWindowsOnScreen(screen, includeActive: true)
    if windows.isEmpty { return }

    let cellW = visible.width / CGFloat(cols)
    let cellH = visible.height / CGFloat(rows)

    for (i, info) in windows.enumerated() {
        if i >= cols * rows { break }
        let r = i / cols
        let c = i % cols
        var rect = CGRect(
            x: visible.minX + CGFloat(c) * cellW,
            y: visible.minY + CGFloat(r) * cellH,
            width: cellW,
            height: cellH
        )
        if gap > 0 { rect = rect.insetBy(dx: gap/2, dy: gap/2) }
        setWindowFrame(info.element, rect)
    }
}

func arrangeCascade(offset: CGFloat = 32) {
    guard let active = getFrontmostWindowElement(),
          let screen = getTargetScreen(for: active) else { return }
    let visible = screen.visibleFrame
    let windows = getWindowsOnScreen(screen, includeActive: true)
    if windows.isEmpty { return }

    let baseW = visible.width * 0.66
    let baseH = visible.height * 0.66
    for (i, info) in windows.enumerated() {
        var rect = CGRect(
            x: visible.minX + CGFloat(i) * offset,
            y: visible.minY + CGFloat(i) * offset,
            width: baseW,
            height: baseH
        )
        // keep inside bounds
        rect.origin.x = min(rect.origin.x, visible.maxX - baseW)
        rect.origin.y = min(rect.origin.y, visible.maxY - baseH)
        setWindowFrame(info.element, rect)
    }
}

func arrangeSlices(orientation: String, count: Int, gap: CGFloat = 0) {
    guard let active = getFrontmostWindowElement(),
          let screen = getTargetScreen(for: active) else { return }
    let visible = screen.visibleFrame
    let windows = getWindowsOnScreen(screen, includeActive: true)
    if windows.isEmpty { return }

    for (i, info) in windows.enumerated() {
        if i >= count { break }
        var rect: CGRect
        if orientation == "columns" {
            let w = visible.width / CGFloat(count)
            rect = CGRect(x: visible.minX + CGFloat(i)*w, y: visible.minY, width: w, height: visible.height)
        } else {
            let h = visible.height / CGFloat(count)
            rect = CGRect(x: visible.minX, y: visible.minY + CGFloat(i)*h, width: visible.width, height: h)
        }
        if gap > 0 { rect = rect.insetBy(dx: gap/2, dy: gap/2) }
        setWindowFrame(info.element, rect)
    }
}

// MARK: - Layouts

struct WindowLayout: Codable {
    let bundleId: String
    let title: String
    let screenIndex: Int
    let xRel: Double, yRel: Double, wRel: Double, hRel: Double
}

struct SavedLayout: Codable {
    let name: String
    let createdAt: Date
    let windows: [WindowLayout]
}

func layoutsDir() -> URL {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent(".mwm/layouts", isDirectory: true)
}

func saveLayout(name: String) {
    guard let active = getFrontmostWindowElement(),
          let screen = getTargetScreen(for: active) else { return }
    let visible = screen.visibleFrame
    var records: [WindowLayout] = []
    let windows = getWindowsOnScreen(screen, includeActive: true)

    for info in windows {
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(info.element, kAXTitleAttribute as CFString, &titleRef)
        let title = (titleRef as? String) ?? ""
        let bundleId = info.app.bundleIdentifier ?? info.app.localizedName ?? "unknown"
        let screenIndex = NSScreen.screens.firstIndex(of: screen) ?? 0
        let xRel = Double((info.frame.minX - visible.minX) / visible.width)
        let yRel = Double((info.frame.minY - visible.minY) / visible.height)
        let wRel = Double(info.frame.width / visible.width)
        let hRel = Double(info.frame.height / visible.height)
        records.append(WindowLayout(bundleId: bundleId, title: title, screenIndex: screenIndex,
                                    xRel: xRel, yRel: yRel, wRel: wRel, hRel: hRel))
    }

    do {
        try FileManager.default.createDirectory(at: layoutsDir(), withIntermediateDirectories: true)
        let layout = SavedLayout(name: name, createdAt: Date(), windows: records)
        let data = try JSONEncoder().encode(layout)
        let url = layoutsDir().appendingPathComponent("\(name).json")
        try data.write(to: url)
        print("Saved layout '\(name)' to \(url.path)")
    } catch {
        print("Failed to save layout: \(error)")
    }
}

func restoreLayout(name: String) {
    do {
        let url = layoutsDir().appendingPathComponent("\(name).json")
        let data = try Data(contentsOf: url)
        let layout = try JSONDecoder().decode(SavedLayout.self, from: data)

        // Build live window lookup table
        var live: [(AXUIElement, NSRunningApplication, NSScreen)] = []
        for screen in NSScreen.screens {
            for info in getWindowsOnScreen(screen, includeActive: true) {
                live.append((info.element, info.app, screen))
            }
        }

        for w in layout.windows {
            let targetScreen = NSScreen.screens.indices.contains(w.screenIndex) ? NSScreen.screens[w.screenIndex] : NSScreen.screens[0]
            let vis = targetScreen.visibleFrame
            let rect = CGRect(
                x: vis.minX + CGFloat(w.xRel) * vis.width,
                y: vis.minY + CGFloat(w.yRel) * vis.height,
                width: CGFloat(w.wRel) * vis.width,
                height: CGFloat(w.hRel) * vis.height
            )
            // Find best match (bundle id + fuzzy title)
            if let (el, _, _) = live.first(where: { elem, app, _ in
                let matchBundle = (app.bundleIdentifier ?? app.localizedName ?? "") == w.bundleId
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(elem, kAXTitleAttribute as CFString, &titleRef)
                let t = (titleRef as? String) ?? ""
                return matchBundle && (w.title.isEmpty || t.contains(w.title.prefix(min(12, w.title.count))))
            }) {
                setWindowFrame(el, rect)
            }
        }
    } catch {
        print("Failed to restore layout '\(name)': \(error)")
    }
}

// MARK: - Vertical Snapping

func findNearestTopEdge(to activeFrame: CGRect, in otherFrames: [CGRect]) -> CGFloat? {
    var nearestY: CGFloat?
    let activeTop = activeFrame.maxY
    for f in otherFrames {
        let otherBottom = f.minY
        if otherBottom > activeTop {
            if nearestY == nil || otherBottom < nearestY! { nearestY = otherBottom }
        }
    }
    return nearestY
}

func findNearestBottomEdge(to activeFrame: CGRect, in otherFrames: [CGRect]) -> CGFloat? {
    var nearestY: CGFloat?
    let activeBottom = activeFrame.minY
    for f in otherFrames {
        let otherTop = f.maxY
        if otherTop < activeBottom {
            if nearestY == nil || otherTop > nearestY! { nearestY = otherTop }
        }
    }
    return nearestY
}

func performSnapUp() {
    guard requestAccessibilityPermission() else { return }
    guard let active = getFrontmostWindowElement(),
          let frame = getFrame(for: active),
          let screen = getTargetScreen(for: active) else { return }
    let others = getOtherWindowFramesOnScreen(screen, excluding: active)
    if let nearest = findNearestTopEdge(to: frame, in: others) {
        let newH = nearest - frame.minY
        if newH > 0 {
            let newFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: newH)
            setWindowFrame(active, newFrame)
        }
    }
}

func performSnapDown() {
    guard requestAccessibilityPermission() else { return }
    guard let active = getFrontmostWindowElement(),
          let frame = getFrame(for: active),
          let screen = getTargetScreen(for: active) else { return }
    let others = getOtherWindowFramesOnScreen(screen, excluding: active)
    if let nearest = findNearestBottomEdge(to: frame, in: others) {
        let newY = nearest
        let newH = frame.maxY - newY
        if newH > 0 {
            let newFrame = CGRect(x: frame.minX, y: newY, width: frame.width, height: newH)
            setWindowFrame(active, newFrame)
        }
    }
}

// MARK: - Nudge and Grow

func nudge(dx: CGFloat, dy: CGFloat) {
    guard let w = getFrontmostWindowElement(),
          let pos = getWindowPosition(w),
          let size = getWindowSize(w),
          let screen = getTargetScreen(for: w) else { return }
    let vis = screen.visibleFrame
    var rect = CGRect(x: pos.x + dx, y: pos.y + dy, width: size.width, height: size.height)
    rect.origin.x = max(vis.minX, min(rect.origin.x, vis.maxX - rect.width))
    rect.origin.y = max(vis.minY, min(rect.origin.y, vis.maxY - rect.height))
    setWindowFrame(w, rect)
}

func grow(width dw: CGFloat, height dh: CGFloat) {
    guard let w = getFrontmostWindowElement(),
          let pos = getWindowPosition(w),
          let size = getWindowSize(w),
          let screen = getTargetScreen(for: w) else { return }
    let vis = screen.visibleFrame
    var rect = CGRect(x: pos.x, y: pos.y, width: max(50, size.width + dw), height: max(50, size.height + dh))
    rect.size.width = min(rect.size.width, vis.width)
    rect.size.height = min(rect.size.height, vis.height)
    setWindowFrame(w, rect)
}

// MARK: - Display Under Mouse

func displayUnderMouse() {
    guard let w = getFrontmostWindowElement(),
          let current = getTargetScreen(for: w),
          let pos = getWindowPosition(w),
          let size = getWindowSize(w) else { return }
    let mouse = NSEvent.mouseLocation
    let target = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? current
    let curVis = current.visibleFrame
    let tgtVis = target.visibleFrame
    let relX = (pos.x - curVis.minX) / curVis.width
    let relY = (pos.y - curVis.minY) / curVis.height
    let relW = min(1.0, size.width / curVis.width)
    let relH = min(1.0, size.height / curVis.height)
    let newRect = CGRect(
        x: tgtVis.minX + relX * tgtVis.width,
        y: tgtVis.minY + relY * tgtVis.height,
        width: relW * tgtVis.width,
        height: relH * tgtVis.height
    )
    setWindowFrame(w, newRect)
}

// MARK: - List Windows

struct WindowRow: Codable {
    let app: String
    let bundleId: String
    let title: String
    let screen: Int
    let x: Int
    let y: Int
    let w: Int
    let h: Int
}

func listWindows(json: Bool) {
    var rows: [WindowRow] = []
    for (si, screen) in NSScreen.screens.enumerated() {
        for info in getWindowsOnScreen(screen, includeActive: true) {
            var tRef: CFTypeRef?
            AXUIElementCopyAttributeValue(info.element, kAXTitleAttribute as CFString, &tRef)
            let t = (tRef as? String) ?? ""
            rows.append(WindowRow(
                app: info.app.localizedName ?? "Unknown",
                bundleId: info.app.bundleIdentifier ?? "",
                title: t,
                screen: si,
                x: Int(info.frame.minX), y: Int(info.frame.minY),
                w: Int(info.frame.width), h: Int(info.frame.height)
            ))
        }
    }
    if json {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? enc.encode(rows), let s = String(data: data, encoding: .utf8) {
            print(s)
        }
    } else {
        for r in rows {
            print("[S\(r.screen)] \(r.app) — \(r.title) @ (\(r.x),\(r.y)) \(r.w)x\(r.h)")
        }
    }
}

// MARK: - Display Management

// MARK: - Help and Argument Parsing
func printHelp() {
    print("""
    Usage: mwm <command> [width-<size>] [height-<size>]

    Available commands:
      Positioning:
        center               Center the window on the screen
        top-left, top-right, bottom-left, bottom-right
                             Position the window in the specified corner
        left-half, right-half, top-half, bottom-half
                             Position the window to occupy the specified half
        left-third, center-third, right-third
                             Position the window to occupy the specified third horizontally
        center-<percentage>% Center the window with the specified percentage of screen size

      Sizing:
        fullscreen           Toggle fullscreen mode for the window
        maximize             Maximize the window (fill screen vertically)
        maximize-height      Maximize the window height only
        maximize-width       Maximize the window width only

      Movement:
        move-up, move-down, move-left, move-right
                             Move the window to the respective edge of the screen

      Snapping:
        snap-left            Resize window's left edge to nearest window on the left
        snap-right           Resize window's right edge to nearest window on the right
        snap-up              Resize window's top edge to nearest window above
        snap-down            Resize window's bottom edge to nearest window below

      Organize:
        arrange grid <COLS>x<ROWS> [gap-<px>]   Tile all windows on the screen
        arrange cascade [offset-<px>]           Fan out windows
        arrange columns <N> [gap-<px>]          Equal-width columns
        arrange rows <N> [gap-<px>]             Equal-height rows

      Layouts:
        layout save <name>                      Save current layout (relative)
        layout restore <name>                   Restore layout (resolution-proof)

      Fine Control:
        nudge <left|right|up|down> <px>        Move window by pixels without resizing
        grow <width|height> <±px>               Resize window by pixels

      Display Movement:
        display-next         Move the window to the next display
        display-previous     Move the window to the previous display
        display-under-mouse  Move window to display under cursor

      Information:
        list-screens         List all available screens
        list-windows [--json]   List all visible windows

      Misc:
        help                 Show this help message
        --version, version   Show the version number

    Size Specifications (for 'center' and positioning commands):
      width-<value>        Set the width (e.g., width-50%, width-800px)
      height-<value>       Set the height (e.g., height-75%, height-600px)
      If not specified, the current size is maintained.
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
    case "--version", "version":
        print("mwm 1.0.0")
        exit(0)
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
    case "left-half":
        positionFrontmostWindow(position: .left, widthSpec: "50%", heightSpec: "100%")
    case "right-half":
        positionFrontmostWindow(position: .right, widthSpec: "50%", heightSpec: "100%")
    case "top-half":
        positionFrontmostWindow(position: .centerTop, widthSpec: "100%", heightSpec: "50%")
    case "bottom-half":
        positionFrontmostWindow(position: .centerBottom, widthSpec: "100%", heightSpec: "50%")
    case "left-third":
        positionFrontmostWindow(position: .custom("left-third"), widthSpec: nil, heightSpec: nil)
    case "center-third":
        positionFrontmostWindow(position: .custom("center-third"), widthSpec: nil, heightSpec: nil)
    case "right-third":
        positionFrontmostWindow(position: .custom("right-third"), widthSpec: nil, heightSpec: nil)
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
    case "snap-left":
        performSnapLeft()
    case "snap-right":
        performSnapRight()
    case "snap-up":
        performSnapUp()
    case "snap-down":
        performSnapDown()
    case "display-next":
        moveWindowToNextDisplay()
    case "display-previous":
        moveWindowToPreviousDisplay()
    case "display-under-mouse":
        displayUnderMouse()
    case "list-screens":
        listAvailableScreens()
    case "list-windows":
        let json = CommandLine.arguments.dropFirst(2).contains("--json")
        listWindows(json: json)
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
    case "arrange":
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard let mode = args.first else { print("Usage: mwm arrange <grid|cascade|columns|rows> ..."); break }
        if mode == "grid", args.count >= 2, let xIndex = args[1].firstIndex(of: "x") {
            let cols = Int(args[1][..<xIndex]) ?? 2
            let rows = Int(args[1][args[1].index(after: xIndex)...]) ?? 2
            let gapArg = args.first(where: { $0.hasPrefix("gap-") })?.replacingOccurrences(of: "gap-", with: "").replacingOccurrences(of: "px", with: "")
            let gap = CGFloat(Double(gapArg ?? "0") ?? 0)
            arrangeGrid(cols: cols, rows: rows, gap: gap)
        } else if mode == "cascade" {
            let offArg = args.first(where: { $0.hasPrefix("offset-") })?.replacingOccurrences(of: "offset-", with: "").replacingOccurrences(of: "px", with: "")
            let offset = CGFloat(Double(offArg ?? "32") ?? 32)
            arrangeCascade(offset: offset)
        } else if (mode == "columns" || mode == "rows"), args.count >= 2, let n = Int(args[1]) {
            let gapArg = args.first(where: { $0.hasPrefix("gap-") })?.replacingOccurrences(of: "gap-", with: "").replacingOccurrences(of: "px", with: "")
            let gap = CGFloat(Double(gapArg ?? "0") ?? 0)
            arrangeSlices(orientation: mode, count: n, gap: gap)
        } else {
            print("Invalid arrange usage.")
        }
    case "layout":
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard args.count >= 2 else { print("Usage: mwm layout <save|restore> <name>"); break }
        if args[0] == "save" { saveLayout(name: args[1]) }
        else if args[0] == "restore" { restoreLayout(name: args[1]) }
        else { print("Usage: mwm layout <save|restore> <name>") }
    case "nudge":
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard args.count >= 2, let px = Double(args[1]) else { print("Usage: mwm nudge <left|right|up|down> <px>"); break }
        switch args[0] {
        case "left": nudge(dx: CGFloat(-px), dy: 0)
        case "right": nudge(dx: CGFloat(px), dy: 0)
        case "up": nudge(dx: 0, dy: CGFloat(px))
        case "down": nudge(dx: 0, dy: CGFloat(-px))
        default: print("Usage: mwm nudge <left|right|up|down> <px>")
        }
    case "grow":
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard args.count >= 2, let px = Double(args[1]) else { print("Usage: mwm grow <width|height> <±px>"); break }
        switch args[0] {
        case "width": grow(width: CGFloat(px), height: 0)
        case "height": grow(width: 0, height: CGFloat(px))
        default: print("Usage: mwm grow <width|height> <±px>")
        }
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