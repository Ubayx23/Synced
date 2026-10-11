import Foundation
import Observation
import OSLog
import Supabase

/// Exercises the user hid, stored on the account in
/// profiles.hidden_exercises as exerciseMatchKeys. Hidden exercises drop out
/// of Improving, the Lifts list, and Log sheet suggestions; their history
/// is untouched. Logging one again brings it back.
@MainActor
@Observable
final class HiddenExercises {
    static let shared = HiddenExercises()

    private(set) var keys: Set<String> = []
    private var loadedFor: UUID?

    private static let log = Logger(subsystem: "page.synced.app", category: "HiddenExercises")

    func contains(_ name: String) -> Bool { keys.contains(name.exerciseMatchKey) }

    /// Reads the account's list. On the first load per device, moves the old
    /// per-device UserDefaults list into it and then removes that store.
    func load() async {
        guard let userID = try? await supabase.auth.session.user.id else { return }
        struct Row: Decodable { let hidden_exercises: [String] }
        do {
            let row: Row = try await supabase
                .from("profiles")
                .select("hidden_exercises")
                .eq("id", value: userID.uuidString)
                .single()
                .execute()
                .value
            var merged = Set(row.hidden_exercises)
            let legacyKey = "hiddenExerciseSuggestions.\(userID.uuidString)"
            if let legacy = UserDefaults.standard.stringArray(forKey: legacyKey) {
                let before = merged
                merged.formUnion(legacy.map(\.exerciseMatchKey))
                if merged != before { try await Self.write(merged, userID: userID) }
                // Only after the account has it.
                UserDefaults.standard.removeObject(forKey: legacyKey)
            }
            keys = merged
            loadedFor = userID
        } catch is CancellationError {
        } catch {
            Self.log.error("Hidden exercises load failed: \(String(describing: error), privacy: .public)")
        }
    }

    func hide(_ name: String) async throws {
        try await save(keys.union([name.exerciseMatchKey]))
    }

    func unhide(_ names: [String]) async throws {
        let next = keys.subtracting(names.map(\.exerciseMatchKey))
        guard next != keys else { return }
        try await save(next)
    }

    /// Updates at once and rolls back if the write fails.
    private func save(_ next: Set<String>) async throws {
        let userID = try await supabase.auth.session.user.id
        if loadedFor != userID {
            await load()
        }
        let previous = keys
        keys = next
        do {
            try await Self.write(next, userID: userID)
        } catch {
            keys = previous
            throw error
        }
    }

    private static func write(_ keys: Set<String>, userID: UUID) async throws {
        try await supabase
            .from("profiles")
            .update(["hidden_exercises": keys.sorted()])
            .eq("id", value: userID.uuidString)
            .execute()
    }
}
