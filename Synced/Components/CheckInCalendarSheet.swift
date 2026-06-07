import SwiftUI
import Supabase

struct CheckInCalendarSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var checkInDates: Set<Date> = []   // local startOfDay
    @State private var liftsThisMonth: Int = 0

    private let cellSize: CGFloat = 40

    private let today = Calendar.current.startOfDay(for: Date())
    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.top, 16)

                Spacer().frame(height: 24)

                titleBlock
                    .padding(.horizontal, Spacing.pageH)

                Spacer().frame(height: 28)

                weekdayHeader
                    .padding(.horizontal, Spacing.pageH)

                Spacer().frame(height: 12)

                calendarGrid
                    .padding(.horizontal, Spacing.pageH)

                Spacer().frame(height: 24)

                summaryCard
                    .padding(.horizontal, Spacing.pageH)

                Spacer()
            }
        }
        .task { await loadCheckIns() }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SYN.textFaint)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(monthYearString)
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)
            Text("Your check-in calendar")
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: today)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                Text(day)
                    .font(.synText(11, weight: .semibold))
                    .tracking(0.88)
                    .foregroundStyle(SYN.textFaint)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4),
                                 count: 7), spacing: 8) {
            ForEach(monthCells.indices, id: \.self) { idx in
                if let date = monthCells[idx] {
                    DayCell(
                        date: date,
                        isToday: calendar.isDate(date, inSameDayAs: today),
                        hasCheckIn: checkInDates.contains(date),
                        isFuture: date > today
                    )
                } else {
                    Color.clear.frame(height: cellSize + 8)
                }
            }
        }
    }

    private var summaryCard: some View {
        HStack {
            Text("Lifts this month")
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
            Spacer()
            Text("\(liftsThisMonth)")
                .font(.synMono(20, weight: .bold))
                .foregroundStyle(SYN.text)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Radius.card).fill(SYN.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(SYN.border, lineWidth: 1))
    }

    // Calendar math
    private var monthCells: [Date?] {
        guard let monthStart = calendar.date(from:
                calendar.dateComponents([.year,.month], from: today)) else { return [] }
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        let leadingBlanks = weekdayOfFirst - 1
        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        let dayCount = range.count
        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for d in 0..<dayCount {
            if let day = calendar.date(byAdding: .day, value: d, to: monthStart) {
                cells.append(calendar.startOfDay(for: day))
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private func loadCheckIns() async {
        guard let userID = supabase.auth.currentSession?.user.id else { return }
        guard let monthStart = calendar.date(from:
                calendar.dateComponents([.year,.month], from: today)) else { return }
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? today

        struct Row: Decodable { let created_at: Date }
        let iso = ISO8601DateFormatter()
        do {
            let rows: [Row] = try await supabase.from("pre_lift_checkins")
                .select("created_at")
                .eq("user_id", value: userID.uuidString)
                .gte("created_at", value: iso.string(from: monthStart))
                .lt("created_at", value: iso.string(from: nextMonth))
                .execute().value
            let days = Set(rows.map { calendar.startOfDay(for: $0.created_at) })
            await MainActor.run {
                checkInDates = days
                liftsThisMonth = rows.count
            }
        } catch {
            // silent
        }
    }
}

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let hasCheckIn: Bool
    let isFuture: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.synMono(14, weight: hasCheckIn ? .bold : .regular))
                .foregroundStyle(textColor)
            if hasCheckIn {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(SYN.cyan)
            } else {
                Color.clear.frame(height: 8)
            }
        }
        .frame(width: 40, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(hasCheckIn ? SYN.cyan.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? SYN.cyan : .clear, lineWidth: 1.5)
        )
    }

    private var textColor: Color {
        if isFuture { return SYN.textFaint }
        if hasCheckIn { return SYN.cyan }
        return SYN.text
    }
}
