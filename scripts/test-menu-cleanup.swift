import Foundation

let fm = FileManager.default
let fixture = fm.temporaryDirectory.appendingPathComponent("MizzeCleanupTests-\(UUID().uuidString)")
try fm.createDirectory(at: fixture, withIntermediateDirectories: true)
defer { try? fm.removeItem(at: fixture) }

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

for bundleID in ["com.dts.freefireth", "com.dts.freefiremax"] {
    var refreshCount = 0
    let metadataValues: [String?] = [nil, "", bundleID]
    for metadata in metadataValues {
        let path = MenuGameContainerResolver.resolve(
            bundleID: bundleID,
            lookup: { "/resolved-by-existing-lookup" },
            metadataIdentifier: { _ in metadata },
            refresh: { refreshCount += 1; return nil }
        )
        expect(path == "/resolved-by-existing-lookup", "Missing metadata incorrectly blocked a working container")
    }
    expect(refreshCount == 0, "A valid existing lookup should not require refresh")
    let otherBundleID = bundleID == "com.dts.freefireth" ? "com.dts.freefiremax" : "com.dts.freefireth"
    let refreshed = MenuGameContainerResolver.resolve(
        bundleID: bundleID,
        lookup: { "/stale-other-game" },
        metadataIdentifier: { $0 == "/stale-other-game" ? otherBundleID : bundleID },
        refresh: { refreshCount += 1; return "/correct-game" }
    )
    expect(refreshed == "/correct-game" && refreshCount == 1, "A stale cross-game cache was not refreshed")
    let rejected = MenuGameContainerResolver.resolve(
        bundleID: bundleID,
        lookup: { "/other-game" },
        metadataIdentifier: { _ in otherBundleID },
        refresh: { "/still-other-game" }
    )
    expect(rejected == nil, "A known different game container was accepted")
    let retried = MenuGameContainerResolver.resolve(
        bundleID: bundleID,
        lookup: { nil },
        metadataIdentifier: { _ in nil },
        refresh: { "/newly-resolved-game" }
    )
    expect(retried == "/newly-resolved-game", "A failed initial lookup was not retried")
}
print("PASS: existing FF/FF MAX lookups without metadata, stale cache refresh and conflicting identity rejection")

func documents(_ game: String) throws -> URL {
    let url = fixture.appendingPathComponent(game).appendingPathComponent("Documents")
    try fm.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

let expectedNames = ["Assembly-CSharp-patch.bytes", "localConfig.json", "config.bin", "beetalk_session.db", "game_sound_config", "ShaderStripSettings"]
for game in ["com.dts.freefireth", "com.dts.freefiremax"] {
    let selected = try documents(game)
    for name in expectedNames + ["unrelated.txt", "ShaderStripSettings.backup"] {
        try Data("keep or remove \(name)".utf8).write(to: selected.appendingPathComponent(name))
    }
    let otherGame = try documents("other-\(game)")
    let otherFile = otherGame.appendingPathComponent("beetalk_session.db")
    try Data("other game".utf8).write(to: otherFile)
    try MenuFileCleanup.removeFiles(in: selected)
    for name in expectedNames {
        expect(!fm.fileExists(atPath: selected.appendingPathComponent(name).path), "Target still exists: \(game)/\(name)")
    }
    expect(fm.fileExists(atPath: selected.appendingPathComponent("unrelated.txt").path), "Unrelated file was removed")
    expect(fm.fileExists(atPath: selected.appendingPathComponent("ShaderStripSettings.backup").path), "Lookalike filename was removed")
    expect(fm.fileExists(atPath: otherFile.path), "The other game's file was removed")
    try MenuFileCleanup.removeFiles(in: selected)
}

let directoryCase = try documents("directory-case")
let namedDirectory = directoryCase.appendingPathComponent("ShaderStripSettings")
try fm.createDirectory(at: namedDirectory, withIntermediateDirectories: true)
try Data("keep".utf8).write(to: namedDirectory.appendingPathComponent("keep.txt"))
do {
    try MenuFileCleanup.removeFiles(in: directoryCase)
    fatalError("A directory target should have been rejected")
} catch {
    expect(fm.fileExists(atPath: namedDirectory.appendingPathComponent("keep.txt").path), "Directory contents were removed")
}

let symlinkCase = try documents("symlink-case")
let outside = fixture.appendingPathComponent("outside.txt")
try Data("keep".utf8).write(to: outside)
try fm.createSymbolicLink(at: symlinkCase.appendingPathComponent("beetalk_session.db"), withDestinationURL: outside)
do {
    try MenuFileCleanup.removeFiles(in: symlinkCase)
    fatalError("A symlink target should have been rejected")
} catch {
    expect(fm.fileExists(atPath: outside.path), "Symlink destination was removed")
}
print("PASS: FF and FF MAX cleanup, missing files, unrelated files, other containers, directories and symlinks")
