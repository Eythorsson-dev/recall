import Testing
import Foundation
@testable import Core

@Test func studyDirectionDefaultsToNil() throws {
    let db = try DatabaseManager.inMemory()
    let repo = SettingsRepository(database: db)
    #expect(try repo.studyDirection() == nil)
}

@Test func studyDirectionRoundTrips() throws {
    let db = try DatabaseManager.inMemory()
    let repo = SettingsRepository(database: db)

    try repo.setStudyDirection(.sourceToTarget)
    #expect(try repo.studyDirection() == .sourceToTarget)

    try repo.setStudyDirection(.targetToSource)
    #expect(try repo.studyDirection() == .targetToSource)
}

@Test func studyDirectionClearedByNil() throws {
    let db = try DatabaseManager.inMemory()
    let repo = SettingsRepository(database: db)

    try repo.setStudyDirection(.sourceToTarget)
    try repo.setStudyDirection(nil)
    #expect(try repo.studyDirection() == nil)
}

@Test func studyModeDefaultsToReading() throws {
    let db = try DatabaseManager.inMemory()
    let repo = SettingsRepository(database: db)
    #expect(try repo.studyMode() == .reading)
}

@Test func studyModeRoundTrips() throws {
    let db = try DatabaseManager.inMemory()
    let repo = SettingsRepository(database: db)

    try repo.setStudyMode(.listeningWithText)
    #expect(try repo.studyMode() == .listeningWithText)

    try repo.setStudyMode(.listeningWithoutText)
    #expect(try repo.studyMode() == .listeningWithoutText)

    try repo.setStudyMode(.reading)
    #expect(try repo.studyMode() == .reading)
}

@Test func settingsOverwritePreviousValue() throws {
    let db = try DatabaseManager.inMemory()
    let repo = SettingsRepository(database: db)

    try repo.setStudyMode(.listeningWithText)
    try repo.setStudyMode(.reading)
    #expect(try repo.studyMode() == .reading)
}
