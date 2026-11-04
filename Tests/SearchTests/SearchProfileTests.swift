import Foundation
import XCTest
@testable import Search

/// A Search profile's spaces (SearchProfile.swift, ImportFile.swift): the
/// import restores only the sessions of spaces the file lists, and Personal
/// with its one space keeps no spaces.json — so the list has to travel
/// anyway, and a file without one still has to bring that space's tabs.
final class SearchProfileTests: XCTestCase {
    private static var world: String?

    override class func setUp() {
        super.setUp()
        let name = "profile-file-tests-\(UUID().uuidString.lowercased().prefix(8))"
        world = name
        setenv("SEARCH_PROBE", name, 1)
    }

    override class func tearDown() {
        Disk.drain()
        if let world, Store.world == world {
            try? FileManager.default.removeItem(at: Store.folder)
            UserDefaults(suiteName: "com.officecommun.search.test.\(world)")?.removePersistentDomain(forName: "com.officecommun.search.test.\(world)")
        }
        unsetenv("SEARCH_PROBE")
        super.tearDown()
    }

    private func shape() -> Session.Shape {
        Session.Shape(tabs: [
            Session.Entry(url: "https://a.example/", title: "A"),
            Session.Entry(url: "https://b.example/", title: "B"),
        ], active: 1)
    }

    func testPersonalAloneExportsItsSpaceAndImportBringsItsTabs() throws {
        try? FileManager.default.removeItem(at: Store.file("spaces.json"))
        Session.write(now: true, shape())
        XCTAssertFalse(FileManager.default.fileExists(atPath: Store.file("spaces.json").path))

        let staging = SearchProfile.collectCurrentProfile()
        defer { try? FileManager.default.removeItem(at: staging) }
        let listed = try JSONDecoder().decode([Space].self, from: Data(contentsOf: staging.appendingPathComponent("spaces.json")))
        XCTAssertEqual(listed.map(\.id), [Space.firstID])

        let incoming = ImportFile.readIncomingProfile(in: staging)
        XCTAssertEqual(incoming.spaces.map(\.id), [Space.firstID])
        XCTAssertEqual(incoming.sessions[Space.firstID.uuidString]?.tabs.map(\.url), ["https://a.example/", "https://b.example/"])
    }

    func testAFileWithoutASpacesListStillBringsTheFirstSpacesTabs() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("profile-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try JSONEncoder().encode(shape()).write(to: folder.appendingPathComponent("session.json"))

        let incoming = ImportFile.readIncomingProfile(in: folder)
        XCTAssertEqual(incoming.spaces.map(\.id), [Space.firstID])
        XCTAssertEqual(incoming.sessions[Space.firstID.uuidString]?.tabs.count, 2)
    }
}
