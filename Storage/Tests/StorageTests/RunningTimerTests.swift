import XCTest
import Foundation
import Storage

final class RunningTimerTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_000_000)

    func testTimerCountsDownAgainstWallClock() {
        let timer = RunningTimer.timer(remaining: 300, startedAt: now.addingTimeInterval(-100))
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.liveValue(now: now), 200)
        XCTAssertEqual(timer.endTime, now.addingTimeInterval(200))
    }

    func testPauseFreezesRemainingAndPreventsExpiry() {
        var timer = RunningTimer.timer(remaining: 300, startedAt: now.addingTimeInterval(-100))
        timer = timer.pausing(now: now)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.liveValue(now: now.addingTimeInterval(60)), 200)
        XCTAssertNil(timer.endTime)
    }

    func testResumeKeepsRemainingAndContinues() {
        var timer = RunningTimer.timer(remaining: 300, startedAt: now.addingTimeInterval(-100))
        timer = timer.pausing(now: now)
        timer = timer.resuming(now: now.addingTimeInterval(50))
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.liveValue(now: now.addingTimeInterval(100)), 150)
        XCTAssertEqual(timer.endTime, now.addingTimeInterval(250))
    }

    func testStopwatchAccumulatesAcrossPause() {
        var stopwatch = RunningTimer.stopwatch(elapsed: 0, startedAt: now.addingTimeInterval(-90))
        XCTAssertEqual(stopwatch.liveValue(now: now), 90)
        stopwatch = stopwatch.pausing(now: now)
        XCTAssertEqual(stopwatch.liveValue(now: now.addingTimeInterval(30)), 90)
        stopwatch = stopwatch.resuming(now: now.addingTimeInterval(10))
        XCTAssertEqual(stopwatch.liveValue(now: now.addingTimeInterval(25)), 105)
    }

    func testCodableRoundTrip() throws {
        let timer = RunningTimer.timer(remaining: 300, startedAt: now)
        let data = try JSONEncoder().encode(timer)
        let decoded = try JSONDecoder().decode(RunningTimer.self, from: data)
        XCTAssertEqual(decoded, timer)
    }
}