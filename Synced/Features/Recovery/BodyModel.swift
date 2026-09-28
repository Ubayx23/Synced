import Foundation

/// Which body the Recovery map draws. Chosen at sign up and stored on the
/// device; raw values match MuscleMap's BodyGender.
enum BodyModel: String, CaseIterable, Identifiable {
    case male, female

    static let storageKey = "bodyModel"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        }
    }
}
