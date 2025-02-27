import Carbon
import XCTest

class MaccyUITests: XCTestCase {
  let app = XCUIApplication()
  let pasteboard = NSPasteboard.general

  let copy1 = UUID().uuidString
  let copy2 = UUID().uuidString

  var statusItem: XCUIElement {
    return app.statusItems.firstMatch
  }

  var popUpEvents: [CGEvent] {
    let eventDown = CGEvent(keyboardEventSource: nil, virtualKey: UInt16(kVK_ANSI_C), keyDown: true)!
    eventDown.flags = [.maskCommand, .maskShift]

    let eventUp = CGEvent(keyboardEventSource: nil, virtualKey: UInt16(kVK_ANSI_C), keyDown: false)!
    eventUp.flags = [.maskCommand, .maskShift]

    return [eventDown, eventUp]
  }

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app.launchArguments.append("ui-testing")
    app.launch()

    pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
    copyToClipboard(copy2)
    copyToClipboard(copy1)
  }

  override func tearDown() {
    super.tearDown()
    app.terminate()
  }

  func testPopupWithHotkey() {
    popUpWithHotkey()
    XCTAssertTrue(app.menuItems[copy1].exists)
    XCTAssertTrue(app.menuItems[copy2].exists)
  }

  func testPopupWithMenubar() {
    popUpWithMouse()
    XCTAssertTrue(app.menuItems[copy1].exists)
    XCTAssertTrue(app.menuItems[copy2].exists)
  }

  func testSearch() {
    popUpWithHotkey()
    app.typeText(copy1)
    XCTAssertTrue(app.menuItems[copy1].exists)
    XCTAssertFalse(app.menuItems[copy2].exists)
  }

  func testCopyWithClick() {
    popUpWithHotkey()
    app.menuItems.matching(identifier: copy2).element(boundBy: 0).click()
    XCTAssertEqual(pasteboard.string(forType: NSPasteboard.PasteboardType.string), copy2)
  }

  func testCopyWithEnter() {
    popUpWithHotkey()
    app.menuItems.matching(identifier: copy2).element(boundBy: 0).hover()
    app.typeKey(.enter, modifierFlags: [])
    XCTAssertEqual(pasteboard.string(forType: NSPasteboard.PasteboardType.string), copy2)
  }

  func testDownArrow() {
    popUpWithHotkey()
    app.typeKey(.downArrow, modifierFlags: [])
    app.typeKey(.enter, modifierFlags: [])
    XCTAssertEqual(pasteboard.string(forType: NSPasteboard.PasteboardType.string), copy2)
  }

  func testCommandDownArrow() {
    popUpWithHotkey()
    app.typeKey(.downArrow, modifierFlags: [.command]) // "Quit"
    app.typeKey(.downArrow, modifierFlags: []) // copy1
    app.typeKey(.downArrow, modifierFlags: []) // copy2
    app.typeKey(.enter, modifierFlags: [])
    XCTAssertEqual(pasteboard.string(forType: NSPasteboard.PasteboardType.string), copy2)
  }

  func testUpArrow() {
    popUpWithHotkey()
    app.typeKey(.upArrow, modifierFlags: []) // "Quit"
    app.typeKey(.upArrow, modifierFlags: []) // "About"
    app.typeKey(.upArrow, modifierFlags: []) // "Clear"
    app.typeKey(.upArrow, modifierFlags: [])
    app.typeKey(.enter, modifierFlags: [])
    XCTAssertEqual(pasteboard.string(forType: NSPasteboard.PasteboardType.string), copy2)
  }

  func testCommandUpArrow() {
    popUpWithHotkey()
    app.typeKey(.upArrow, modifierFlags: []) // "Quit"
    app.typeKey(.upArrow, modifierFlags: [.command]) // copy1
    app.typeKey(.downArrow, modifierFlags: [])
    app.typeKey(.enter, modifierFlags: [])
    XCTAssertEqual(pasteboard.string(forType: NSPasteboard.PasteboardType.string), copy2)
  }

  private func popUpWithHotkey() {
    for event in popUpEvents {
      event.post(tap: .cghidEventTap)
    }
    sleep(1) // give Maccy some time to popup
  }

  private func popUpWithMouse() {
    statusItem.click()
    sleep(1) // give Maccy some time to popup
  }

  private func copyToClipboard(_ content: String) {
    pasteboard.clearContents()
    pasteboard.setString(content, forType: NSPasteboard.PasteboardType.string)
    sleep(3) // make sure Maccy knows about new item
  }
}
