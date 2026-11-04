import AppKit
import XCTest
@testable import Search

@MainActor
final class TabGroupCollapseTests: XCTestCase {
    override class func setUp() {
        setenv("SEARCH_PROBE", "tab-group-collapse-\(getpid())", 1)
        super.setUp()
    }

    func testHiddenCountAndActiveMembership() throws {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        let browser = Browser(record: WindowRecord())
        let grouped = browser.prefs.usesTabGroups
        defer { browser.prefs.usesTabGroups = grouped }
        browser.prefs.usesTabGroups = true
        for number in 0..<4 {
            if number > 0 { browser.newTab() }
            browser.tabs.last?.restore(url: URL(string: "https://\(number).example/")!, title: "\(number)")
        }
        let tabs = browser.tabs
        let group = browser.addTabGroup(containing: tabs[0])
        for tab in tabs[1...2] { browser.move(tab, toGroup: group) }
        let folded = try XCTUnwrap(browser.tabGroups.first { $0.id == group })

        // Expanded: nothing hidden, however many members it has.
        XCTAssertEqual(browser.hiddenTabCount(in: folded), 0)

        browser.toggleTabGroup(group)
        let collapsed = try XCTUnwrap(browser.tabGroups.first { $0.id == group })
        XCTAssertTrue(collapsed.collapsed)
        // Hidden = members that stand in a row minus the ones still visible.
        XCTAssertEqual(browser.hiddenTabCount(in: collapsed) + browser.visibleTabs(in: collapsed).count,
                       browser.tabs(in: group).count)

        // Active membership follows the tab in front.
        if let active = browser.active, browser.group(of: active) == group {
            XCTAssertTrue(browser.groupContainsActive(collapsed))
            XCTAssertEqual(browser.visibleTabs(in: collapsed).map(\.id), [active.id])
            XCTAssertEqual(browser.hiddenTabCount(in: collapsed), browser.tabs(in: group).count - 1)
        } else {
            XCTAssertFalse(browser.groupContainsActive(collapsed))
            XCTAssertEqual(browser.hiddenTabCount(in: collapsed), browser.tabs(in: group).count)
        }

        browser.toggleTabGroup(group)
        let reopened = try XCTUnwrap(browser.tabGroups.first { $0.id == group })
        XCTAssertFalse(reopened.collapsed)
        XCTAssertEqual(browser.hiddenTabCount(in: reopened), 0)
    }
}
