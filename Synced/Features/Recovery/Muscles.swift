import Foundation

/// Individual muscles the app tracks for recovery. Finer than the six
/// `MuscleGroup` values stored in sessions.muscle_groups, which each roll up
/// several of these. Named TrainedMuscle because MuscleMap already exports a
/// public `Muscle` type and the Recovery view uses both.
enum TrainedMuscle: String, CaseIterable, Codable {
    case pecs
    case lats
    case traps
    case rhomboids
    case erectors
    case frontDelts
    case sideDelts
    case rearDelts
    case biceps
    case triceps
    case forearms
    case quads
    case hamstrings
    case glutes
    case calves
    case adductors
    case abs
    case obliques

    /// The broad group this muscle belongs to.
    var parentGroup: MuscleGroup {
        switch self {
        case .pecs:                                           return .chest
        case .lats, .traps, .rhomboids, .erectors:            return .back
        case .frontDelts, .sideDelts, .rearDelts:             return .shoulders
        case .biceps, .triceps, .forearms:                    return .arms
        case .quads, .hamstrings, .glutes, .calves, .adductors: return .legs
        case .abs, .obliques:                                 return .core
        }
    }

    /// Every muscle in a group; used when only the group is known.
    static func forParentGroup(_ group: MuscleGroup) -> [TrainedMuscle] {
        allCases.filter { $0.parentGroup == group }
    }
}
