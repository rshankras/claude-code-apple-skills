// DEFAULT ARCHITECTURE — value-moment-first onboarding.
//
// Reach rate, not flow completion, is the north star (onboarding-patterns.md
// Lesson 8) — this works even with zero analytics SDK installed.

import Foundation
import OSLog

/// Local-only instrumentation — a handful of `UserDefaults` timestamps +
/// `OSLog` lines, readable by the developer (Console.app / `defaults read`
/// on a TestFlight device) with zero analytics SDK required. Every write is
/// idempotent (first stamp wins), so a re-entrant path (a relaunch
/// restarting onboarding, a stray duplicate call) never overwrites real data
/// with a later, less meaningful timestamp.
///
/// Wire the same call sites into a real analytics provider once one exists
/// (e.g. an installed `generators/analytics-setup` output) — the local
/// markers and an analytics event are not mutually exclusive.
enum OnboardingInstrumentation {

    /// Which branch the user took at the screen-1 fork — `.skipped` covers
    /// the escape hatch, which never actually chooses `.readyNow`/`.later`.
    enum Branch: String {
        case readyNow
        case later
        case skipped
    }

    private enum Keys {
        static let startedAt = "onboarding.startedAt"
        static let branch = "onboarding.branch"
        static let valueMomentAt = "onboarding.valueMomentAt"
        static let completedAt = "onboarding.completedAt"
    }

    private static let log = Logger(subsystem: "com.yourapp", category: "Onboarding")

    /// Stamped once, the moment `OnboardingStore` is constructed — i.e. the
    /// user actually saw screen 1.
    static func recordStarted(now: Date, defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: Keys.startedAt) == nil else { return }
        defaults.set(now.timeIntervalSince1970, forKey: Keys.startedAt)
        log.info("onboarding started")
    }

    /// Which fork the user picked (or the escape hatch). Overwritten freely
    /// — unlike the timestamps, this is a CURRENT-STATE label, not a
    /// "first time" marker.
    static func recordBranch(_ branch: Branch, defaults: UserDefaults = .standard) {
        defaults.set(branch.rawValue, forKey: Keys.branch)
        log.info("onboarding branch = \(branch.rawValue, privacy: .public)")
    }

    static func recordedBranch(defaults: UserDefaults = .standard) -> Branch? {
        defaults.string(forKey: Keys.branch).flatMap(Branch.init(rawValue:))
    }

    /// The value-moment marker — the product's north star for this flow.
    /// First stamp wins: a second value moment in a later session never
    /// re-stamps a value the user already reached once. Stamp this from
    /// BOTH branches' actual value-moment call sites (the ready-now hand-off
    /// return, and wherever the "later" branch's deferred value moment is
    /// eventually reached in the real app).
    static func recordValueMomentIfNeeded(now: Date, defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: Keys.valueMomentAt) == nil else { return }
        defaults.set(now.timeIntervalSince1970, forKey: Keys.valueMomentAt)
        log.info("onboarding value moment reached")
    }

    static func recordCompleted(now: Date, defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: Keys.completedAt) == nil else { return }
        defaults.set(now.timeIntervalSince1970, forKey: Keys.completedAt)
        log.info("onboarding completed")
    }

    /// Per-device debug signal, not a fleet-wide reach rate — aggregate this
    /// against whatever your app already has (a backend, an analytics
    /// provider) for the real percentage. Still strictly more than "no
    /// measurement at all," which is the actual failure mode this guards
    /// against.
    static func reachedValueMoment(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: Keys.valueMomentAt) != nil
    }

    #if DEBUG
    /// Test-only reset — clears every key in a given suite so tests never
    /// leak state between cases when a test deliberately reuses `.standard`
    /// (most should inject their own suite instead).
    static func resetForTesting(defaults: UserDefaults) {
        for key in [Keys.startedAt, Keys.branch, Keys.valueMomentAt, Keys.completedAt] {
            defaults.removeObject(forKey: key)
        }
    }
    #endif
}
