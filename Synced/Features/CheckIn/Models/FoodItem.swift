import Foundation

struct FoodItem: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var carbsG: Int? = nil
}
