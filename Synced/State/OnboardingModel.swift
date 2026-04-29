import SwiftUI
import Observation

enum Goal: String, CaseIterable, Identifiable {
    case buildMuscle    = "Build Muscle"
    case getStronger    = "Get Stronger"
    case cutWeight      = "Cut Weight"
    case stayConsistent = "Stay Consistent"
    var id: String { rawValue }
}

enum Tier: String, CaseIterable, Identifiable {
    case cooked, active, dialed, lockedIn, synced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cooked:   return "Cooked"
        case .active:   return "Active"
        case .dialed:   return "Dialed"
        case .lockedIn: return "Locked In"
        case .synced:   return "Synced"
        }
    }

    var color: Color {
        switch self {
        case .cooked:   return SYN.textFaint
        case .active:   return .white
        case .dialed:   return SYN.green
        case .lockedIn: return SYN.cyan
        case .synced:   return SYN.cyan
        }
    }

    var iconSystemName: String {
        switch self {
        case .cooked:   return "arrow.down"
        case .active:   return "arrow.up"
        case .dialed:   return "bolt.fill"
        case .lockedIn: return "scope"
        case .synced:   return "infinity"
        }
    }

    var range: ClosedRange<Int> {
        switch self {
        case .cooked:   return 0...39
        case .active:   return 40...59
        case .dialed:   return 60...74
        case .lockedIn: return 75...89
        case .synced:   return 90...100
        }
    }

    /// Tier above this one, or `nil` if already at the top.
    var next: Tier? {
        switch self {
        case .cooked:   return .active
        case .active:   return .dialed
        case .dialed:   return .lockedIn
        case .lockedIn: return .synced
        case .synced:   return nil
        }
    }

    var tagline: String {
        switch self {
        case .cooked:   return "Reset incoming. Rest is the rep."
        case .active:   return "You're in motion. Keep stacking days."
        case .dialed:   return "Inputs and outputs are aligned."
        case .lockedIn: return "Recovery, intent, output, locked."
        case .synced:   return "Mind, body, schedule, perfectly synced."
        }
    }
}

@Observable
final class OnboardingModel {
    var firstName: String = ""
    var age: Int = 20
    var goal: Goal? = nil
    var daysPerWeek: Int = 4
    var sleepHours: Double = 7.5

    func reset() {
        firstName = ""
        age = 20
        goal = nil
        daysPerWeek = 4
        sleepHours = 7.5
    }
}
