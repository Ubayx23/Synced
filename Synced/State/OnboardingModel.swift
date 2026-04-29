import SwiftUI
import Observation

enum Goal: String, CaseIterable, Identifiable {
    case buildMuscle    = "Build muscle"
    case loseFat        = "Lose fat"
    case getStronger    = "Get stronger"
    case improveEndurance = "Improve endurance"
    case stayHealthy    = "Stay healthy"
    var id: String { rawValue }
}

enum DiagnosticOption: String, CaseIterable, Identifiable {
    case unpredictableEnergy   = "My energy is unpredictable"
    case poorRecovery          = "I never feel fully recovered"
    case plateauedProgress     = "I'm stuck on a plateau"
    case dontKnowWhatWorks     = "I don't know what's actually working"
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

    /// Spec colors per chat1.md. `synced` is rendered with a gradient at the call site.
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
        case .cooked:   return 0...19
        case .active:   return 20...49
        case .dialed:   return 50...79
        case .lockedIn: return 80...94
        case .synced:   return 95...100
        }
    }

    var tagline: String {
        switch self {
        case .cooked:   return "Reset incoming. Rest is the rep."
        case .active:   return "You're in motion. Keep stacking days."
        case .dialed:   return "Inputs and outputs are aligned."
        case .lockedIn: return "Recovery, intent, output — locked."
        case .synced:   return "Mind, body, schedule — perfectly synced."
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
    var diagnostic: DiagnosticOption? = nil
    var tier: Tier = .active
    var previewTier: Tier? = nil

    func reset() {
        firstName = ""
        age = 20
        goal = nil
        daysPerWeek = 4
        sleepHours = 7.5
        diagnostic = nil
        tier = .active
        previewTier = nil
    }

    /// Toy scoring; real version is server-driven.
    func computeTier() {
        var score = 30
        score += min(20, daysPerWeek * 3)
        score += Int((sleepHours - 6) * 4)
        if goal != nil { score += 5 }
        if diagnostic != nil { score += 5 }
        let clamped = max(0, min(100, score))
        tier = Tier.allCases.first { $0.range.contains(clamped) } ?? .active
    }

    var resolvedTier: Tier { previewTier ?? tier }
}
