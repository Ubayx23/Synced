import Foundation

/// A catalogued lift and the muscles it trains. Primary is what the movement
/// targets; secondary is what it meaningfully works but does not target.
/// A muscle is never in both.
struct CatalogExercise {
    let name: String
    let primary: [TrainedMuscle]
    let secondary: [TrainedMuscle]

    var allMuscles: [TrainedMuscle] { primary + secondary }
}

/// Static, compile-time catalog of common lifts and climbing supplementary
/// work. Recovery uses it to mark specific muscles; exercises not listed
/// fall back to their muscle group tag or the session's muscle groups.
enum ExerciseCatalog {

    /// Case-insensitive and tolerant of spacing, hyphens, and apostrophes:
    /// "Pull-Up", "pull up", and "  pullup" style differences all resolve.
    /// A plural like "Pull-ups" or "Dips" falls back to its singular.
    static func find(_ name: String) -> CatalogExercise? {
        let key = normalize(name)
        if let entry = entries[key] { return entry }
        guard key.count > 1, key.hasSuffix("s") else { return nil }
        return entries[String(key.dropLast())]
    }

    static func normalize(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\u{2019}", with: "")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// Keyed by normalized name. Built from `list`, where one entry can have
    /// several common spellings.
    static let entries: [String: CatalogExercise] = {
        var out: [String: CatalogExercise] = [:]
        for (names, primary, secondary) in list {
            let entry = CatalogExercise(name: names[0], primary: primary, secondary: secondary)
            for name in names { out[normalize(name)] = entry }
        }
        return out
    }()

    private typealias Row = (names: [String], primary: [TrainedMuscle], secondary: [TrainedMuscle])

    private static let list: [Row] = [
        // Chest
        (["bench press", "barbell bench press", "flat bench press"], [.pecs], [.triceps, .frontDelts]),
        (["incline bench press", "incline barbell bench press"], [.pecs, .frontDelts], [.triceps]),
        (["decline bench press"], [.pecs], [.triceps]),
        (["dumbbell bench press", "dumbbell press", "db bench press"], [.pecs], [.triceps, .frontDelts]),
        (["incline dumbbell press", "incline dumbbell bench press"], [.pecs, .frontDelts], [.triceps]),
        (["dumbbell fly", "dumbbell flye", "chest fly"], [.pecs], [.frontDelts]),
        (["cable fly", "cable flye", "cable crossover"], [.pecs], [.frontDelts]),
        (["pec deck", "machine fly"], [.pecs], [.frontDelts]),
        (["push up", "pushup"], [.pecs], [.triceps, .frontDelts]),
        (["chest dip"], [.pecs, .triceps], [.frontDelts]),
        (["chest press", "machine chest press", "chest press machine"], [.pecs], [.triceps, .frontDelts]),

        // Back
        (["pull up", "pullup"], [.lats], [.biceps, .rhomboids, .rearDelts]),
        (["chin up", "chinup"], [.lats, .biceps], [.rhomboids, .rearDelts]),
        (["lat pulldown", "lat pull down", "pulldown"], [.lats], [.biceps, .rearDelts]),
        (["wide grip lat pulldown", "wide grip pulldown"], [.lats], [.biceps, .rearDelts]),
        (["close grip lat pulldown", "close grip pulldown"], [.lats], [.biceps]),
        (["seated row", "seated cable row", "cable row"], [.lats, .rhomboids], [.biceps, .rearDelts]),
        (["barbell row", "bent over row", "bent over barbell row"], [.lats, .rhomboids], [.biceps, .rearDelts, .erectors]),
        (["dumbbell row", "one arm dumbbell row", "single arm dumbbell row", "bent over dumbbell row"], [.lats], [.rhomboids, .biceps]),
        (["t bar row"], [.lats, .rhomboids], [.biceps, .erectors]),
        (["chest supported row", "chest supported dumbbell row"], [.rhomboids, .lats], [.rearDelts, .biceps]),
        (["pendlay row"], [.lats, .rhomboids], [.erectors, .biceps]),
        (["inverted row", "bodyweight row"], [.lats, .rhomboids], [.biceps, .rearDelts]),
        (["straight arm pulldown", "straight arm lat pulldown"], [.lats], [.triceps]),
        (["face pull"], [.rearDelts], [.rhomboids, .traps]),
        (["shrug", "barbell shrug", "dumbbell shrug"], [.traps], [.forearms]),
        (["deadlift", "conventional deadlift", "barbell deadlift"], [.hamstrings, .glutes, .erectors], [.traps, .forearms, .quads]),
        (["romanian deadlift", "rdl", "dumbbell romanian deadlift"], [.hamstrings, .glutes], [.erectors]),
        (["stiff leg deadlift", "stiff legged deadlift"], [.hamstrings], [.glutes, .erectors]),
        (["sumo deadlift"], [.glutes, .quads, .adductors], [.hamstrings, .erectors]),
        (["rack pull"], [.erectors, .traps], [.glutes, .hamstrings, .forearms]),
        (["good morning"], [.hamstrings, .erectors], [.glutes]),
        (["back extension", "hyperextension"], [.erectors], [.glutes, .hamstrings]),

        // Shoulders
        (["overhead press", "ohp", "military press", "barbell overhead press", "standing overhead press"], [.frontDelts, .sideDelts], [.triceps, .pecs]),
        (["dumbbell shoulder press", "seated dumbbell press", "dumbbell overhead press"], [.frontDelts, .sideDelts], [.triceps]),
        (["machine shoulder press", "shoulder press"], [.frontDelts, .sideDelts], [.triceps]),
        (["arnold press"], [.frontDelts, .sideDelts], [.triceps]),
        (["push press"], [.frontDelts, .sideDelts], [.triceps, .quads]),
        (["landmine press"], [.frontDelts, .pecs], [.triceps]),
        (["lateral raise", "dumbbell lateral raise", "side raise"], [.sideDelts], [.traps]),
        (["cable lateral raise"], [.sideDelts], [.traps]),
        (["front raise", "dumbbell front raise"], [.frontDelts], [.sideDelts]),
        (["rear delt fly", "reverse fly", "bent over reverse fly"], [.rearDelts], [.rhomboids]),
        (["cable rear delt fly", "cable reverse fly"], [.rearDelts], [.rhomboids]),
        (["reverse pec deck"], [.rearDelts], [.rhomboids]),
        (["upright row"], [.sideDelts, .traps], [.biceps]),

        // Biceps
        (["barbell curl", "bicep curl", "biceps curl", "curl"], [.biceps], [.forearms]),
        (["dumbbell curl", "dumbbell bicep curl"], [.biceps], [.forearms]),
        (["hammer curl", "dumbbell hammer curl"], [.biceps, .forearms], []),
        (["preacher curl"], [.biceps], []),
        (["cable curl"], [.biceps], [.forearms]),
        (["incline dumbbell curl", "incline curl"], [.biceps], []),
        (["concentration curl"], [.biceps], []),
        (["ez bar curl"], [.biceps], [.forearms]),
        (["spider curl"], [.biceps], []),

        // Triceps
        (["tricep pushdown", "triceps pushdown", "rope pushdown", "cable pushdown"], [.triceps], []),
        (["overhead tricep extension", "overhead triceps extension", "dumbbell overhead extension"], [.triceps], []),
        (["cable overhead extension", "cable overhead tricep extension"], [.triceps], []),
        (["skull crusher", "lying tricep extension"], [.triceps], []),
        (["close grip bench press"], [.triceps, .pecs], [.frontDelts]),
        (["dip", "tricep dip", "triceps dip", "parallel bar dip"], [.triceps], [.pecs, .frontDelts]),
        (["bench dip"], [.triceps], [.frontDelts]),
        (["tricep kickback", "triceps kickback"], [.triceps], []),
        (["diamond push up"], [.triceps, .pecs], [.frontDelts]),

        // Legs
        (["back squat", "squat", "barbell squat"], [.quads, .glutes], [.hamstrings, .erectors, .abs]),
        (["front squat"], [.quads], [.glutes, .abs, .erectors]),
        (["goblet squat"], [.quads, .glutes], [.abs]),
        (["hack squat"], [.quads], [.glutes]),
        (["leg press"], [.quads, .glutes], [.hamstrings]),
        (["lunge", "walking lunge", "dumbbell lunge", "reverse lunge"], [.quads, .glutes], [.hamstrings, .adductors]),
        (["bulgarian split squat", "split squat"], [.quads, .glutes], [.hamstrings, .adductors]),
        (["step up", "dumbbell step up"], [.quads, .glutes], [.hamstrings]),
        (["pistol squat"], [.quads, .glutes], [.abs]),
        (["leg extension"], [.quads], []),
        (["leg curl", "lying leg curl", "seated leg curl", "hamstring curl"], [.hamstrings], [.calves]),
        (["nordic curl", "nordic hamstring curl"], [.hamstrings], [.glutes]),
        (["hip thrust", "barbell hip thrust"], [.glutes], [.hamstrings]),
        (["glute bridge"], [.glutes], [.hamstrings]),
        (["cable pull through"], [.glutes, .hamstrings], []),
        (["kettlebell swing"], [.glutes, .hamstrings], [.erectors]),
        (["calf raise", "standing calf raise"], [.calves], []),
        (["seated calf raise"], [.calves], []),
        (["hip adduction", "adductor machine"], [.adductors], []),
        (["hip abduction", "abductor machine"], [.glutes], []),

        // Core
        (["plank"], [.abs], [.obliques]),
        (["side plank"], [.obliques], [.abs]),
        (["sit up", "situp"], [.abs], []),
        (["crunch"], [.abs], []),
        (["cable crunch"], [.abs], []),
        (["hanging leg raise"], [.abs], [.obliques, .forearms]),
        (["hanging knee raise"], [.abs], [.forearms]),
        (["toes to bar"], [.abs], [.lats, .forearms]),
        (["russian twist"], [.obliques], [.abs]),
        (["ab wheel", "ab wheel rollout", "ab rollout"], [.abs], [.obliques]),
        (["dead bug"], [.abs], []),
        (["pallof press"], [.obliques], [.abs]),
        (["l sit"], [.abs], [.triceps]),

        // Forearms and grip
        (["wrist curl"], [.forearms], []),
        (["reverse wrist curl"], [.forearms], []),
        (["farmers carry", "farmers walk", "farmer carry"], [.forearms, .traps], [.abs]),
        (["dead hang"], [.forearms], [.lats]),
        (["plate pinch"], [.forearms], []),
        (["rice bucket"], [.forearms], []),

        // Climbing supplementary
        (["hangboard", "hangboarding", "fingerboard", "max hang", "max hangs"], [.forearms], [.lats]),
        (["campus board", "campusing", "campus"], [.forearms, .lats], [.biceps]),
        (["weighted pull up", "weighted pullup"], [.lats], [.biceps, .rhomboids, .rearDelts]),
        (["weighted chin up", "weighted chinup"], [.lats, .biceps], [.rhomboids, .rearDelts]),
        (["one arm hang", "one arm dead hang"], [.forearms], [.lats]),
        (["no hang device", "no hang", "no hangs"], [.forearms], []),
        (["trx row", "ring row"], [.rhomboids, .lats], [.biceps, .rearDelts]),
        (["lock off", "lock offs"], [.biceps, .lats], [.forearms]),
        (["front lever"], [.lats, .abs], [.rhomboids]),
        (["typewriter pull up", "typewriter pullup"], [.lats], [.biceps]),
        (["archer pull up", "archer pullup"], [.lats], [.biceps, .rhomboids]),
        (["muscle up", "muscleup"], [.lats, .triceps], [.biceps, .pecs, .frontDelts]),
        (["hollow hold", "hollow body hold", "hollow body"], [.abs], [.obliques]),
        (["pike push up", "pike pushup"], [.frontDelts, .sideDelts], [.triceps]),
    ]
}
