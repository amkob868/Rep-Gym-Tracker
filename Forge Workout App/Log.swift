import Foundation
import OSLog

/// Lightweight logging shim over the unified logging system (`OSLog`).
///
/// `debug` messages compile out of release builds; `error` messages are always
/// recorded. Using this instead of `print` keeps diagnostics out of production
/// output and makes them filterable in Console.app.
enum Log {
    nonisolated private static let subsystem = "com.alexkobinski.Forge-Workout-App"

    nonisolated static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        let text = message()
        Logger(subsystem: subsystem, category: "app").debug("\(text, privacy: .public)")
        #endif
    }

    nonisolated static func error(_ message: @autoclosure () -> String) {
        let text = message()
        Logger(subsystem: subsystem, category: "app").error("\(text, privacy: .public)")
    }
}
