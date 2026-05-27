import SwiftUI

struct SessionRecord: Identifiable {
    let id: String
    let createdAt: Date
    let muscleGroups: [String]
    let lastTrainedGap: String?
    let sleepHours: Double?
    let mealItems: [FoodItem]
    let mealTime: Date?
    let liftTime: Date?
    let hydration: String?
    let preWorkout: String?
    let preWorkoutBrand: String?
    let preWorkoutCaffeineMg: Int?
    let sessionRating: Int?
    let performanceVsExpectation: String?
    let sessionDuration: String?
    let notes: String?
}

struct SessionDetailView: View {
    let session: SessionRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    topBar

                    titleBlock

                    if hasRecovery   { recoveryCard }
                    if hasSleep      { sleepCard }
                    if hasFood       { foodCard }
                    if hasLift       { liftCard }
                    if hasReadiness  { readinessCard }
                    sessionCard

                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, Spacing.pageH)
            }
        }
    }

    // MARK: - Top bar + title

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SYN.textFaint)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.createdAt, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)
            Text(session.createdAt, format: .dateTime.hour().minute())
                .font(.synText(13))
                .foregroundStyle(SYN.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Section gating

    private var hasRecovery: Bool {
        !session.muscleGroups.isEmpty || (session.lastTrainedGap?.isEmpty == false)
    }
    private var hasSleep: Bool { session.sleepHours != nil }
    private var hasFood: Bool { !session.mealItems.isEmpty || session.mealTime != nil }
    private var hasLift: Bool { session.liftTime != nil }
    private var hasReadiness: Bool {
        (session.hydration?.isEmpty == false)
        || (session.preWorkout?.isEmpty == false)
        || (session.preWorkoutBrand?.isEmpty == false)
        || ((session.preWorkoutCaffeineMg ?? 0) > 0)
    }

    // MARK: - Recovery

    private var recoveryCard: some View {
        sectionCard {
            EyebrowText(text: "Recovery")
                .foregroundStyle(SYN.textFaint)

            if !session.muscleGroups.isEmpty {
                Spacer().frame(height: 12)
                muscleChips
            }

            if let gap = session.lastTrainedGap, !gap.isEmpty {
                Spacer().frame(height: 12)
                Text("Last trained: \(gap)")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textDim)
            }
        }
    }

    private var muscleChips: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80, maximum: 200), spacing: 6, alignment: .leading)],
            alignment: .leading,
            spacing: 6
        ) {
            ForEach(session.muscleGroups, id: \.self) { name in
                Text(name)
                    .font(.synText(13))
                    .foregroundStyle(SYN.text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(SYN.surfaceHi)
                    )
            }
        }
    }

    // MARK: - Sleep

    private var sleepCard: some View {
        sectionCard {
            EyebrowText(text: "Sleep")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 12)

            Text(String(format: "%.1fh", session.sleepHours ?? 0))
                .font(.synMono(28, weight: .bold))
                .foregroundStyle(SYN.text)
        }
    }

    // MARK: - Food

    private var foodCard: some View {
        sectionCard {
            EyebrowText(text: "Food")
                .foregroundStyle(SYN.textFaint)

            if !session.mealItems.isEmpty {
                Spacer().frame(height: 12)
                VStack(spacing: 8) {
                    ForEach(session.mealItems) { item in
                        HStack {
                            Text(item.name)
                                .font(.synText(15))
                                .foregroundStyle(SYN.text)
                            Spacer()
                            if let carbs = item.carbsG {
                                Text("\(carbs)g")
                                    .font(.synMono(13))
                                    .foregroundStyle(SYN.textDim)
                            }
                        }
                    }
                }
            }

            if let mealTime = session.mealTime {
                Spacer().frame(height: 12)
                Text("Eaten at \(mealTime, format: .dateTime.hour().minute())")
                    .font(.synText(12))
                    .foregroundStyle(SYN.textFaint)
            }
        }
    }

    // MARK: - Lift

    private var liftCard: some View {
        sectionCard {
            EyebrowText(text: "Lift")
                .foregroundStyle(SYN.textFaint)

            if let liftTime = session.liftTime {
                Spacer().frame(height: 12)
                Text("Lifted at \(liftTime, format: .dateTime.hour().minute())")
                    .font(.synText(15))
                    .foregroundStyle(SYN.text)
            }

            if let mealTime = session.mealTime,
               let liftTime = session.liftTime,
               liftTime > mealTime {
                let totalMins = Int(liftTime.timeIntervalSince(mealTime) / 60)
                let h = totalMins / 60
                let m = totalMins % 60
                Spacer().frame(height: 8)
                Text("Gap: \(h)h \(m)m")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            }
        }
    }

    // MARK: - Readiness

    private var readinessCard: some View {
        sectionCard {
            EyebrowText(text: "Readiness")
                .foregroundStyle(SYN.textFaint)

            if let hydration = session.hydration, !hydration.isEmpty {
                Spacer().frame(height: 12)
                Text("Hydration: \(hydration)")
                    .font(.synText(15))
                    .foregroundStyle(SYN.text)
            }

            if let preWorkout = session.preWorkout, !preWorkout.isEmpty {
                Spacer().frame(height: 8)
                Text("Pre-workout: \(preWorkout)")
                    .font(.synText(15))
                    .foregroundStyle(SYN.text)
            }

            if let brand = session.preWorkoutBrand, !brand.isEmpty {
                Spacer().frame(height: 8)
                Text("Brand: \(brand)")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textDim)
            }

            if let mg = session.preWorkoutCaffeineMg, mg > 0 {
                Spacer().frame(height: 8)
                Text("Caffeine: \(mg)mg")
                    .font(.synMono(14))
                    .foregroundStyle(SYN.textDim)
            }
        }
    }

    // MARK: - Session

    private var sessionCard: some View {
        sectionCard {
            EyebrowText(text: "Session")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 12)

            if let rating = session.sessionRating {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(colorForRating(Double(rating)))
                            .frame(width: 48, height: 48)
                        Text("\(rating)")
                            .font(.synMono(20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }

                if let perf = session.performanceVsExpectation, !perf.isEmpty {
                    Spacer().frame(height: 12)
                    Text("Performance: \(perf)")
                        .font(.synText(14))
                        .foregroundStyle(SYN.textDim)
                }

                if let duration = session.sessionDuration, !duration.isEmpty {
                    Spacer().frame(height: 8)
                    Text("Duration: \(duration)")
                        .font(.synText(14))
                        .foregroundStyle(SYN.textDim)
                }

                if let notes = session.notes, !notes.isEmpty {
                    Spacer().frame(height: 12)
                    Text(notes)
                        .font(.synText(15))
                        .foregroundStyle(SYN.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Session not logged yet")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textFaint)
            }
        }
    }

    // MARK: - Card chrome

    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(SYN.border, lineWidth: 1)
        )
    }

    private func colorForRating(_ rating: Double) -> Color {
        switch rating {
        case 5: return SYN.cyan
        case 4: return SYN.green
        case 3: return SYN.text
        case 2: return SYN.amber
        default: return SYN.red
        }
    }
}
