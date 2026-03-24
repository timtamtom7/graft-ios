import SwiftUI

struct WeekDotsView: View {
    let sessions: [(date: Date, totalMinutes: Int)]

    private let dotSize: CGFloat = 14
    private let maxMinutes: CGFloat = 120

    var body: some View {
        HStack(spacing: 10) {
            ForEach(sessions.indices, id: \.self) { index in
                let session = sessions[index]
                let intensity = min(CGFloat(session.totalMinutes) / maxMinutes, 1.0)
                let isToday = Calendar.current.isDateInToday(session.date)

                VStack(spacing: 4) {
                    Circle()
                        .fill(intensity > 0 ? GraftColors.accent.opacity(0.3 + intensity * 0.7) : GraftColors.surfaceRaised)
                        .frame(width: dotSize + (intensity * 4), height: dotSize + (intensity * 4))
                        .overlay(
                            Circle()
                                .strokeBorder(isToday ? GraftColors.accent : Color.clear, lineWidth: 1.5)
                        )

                    Text(dayLabel(for: session.date))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(GraftColors.textSecondary)
                }
            }
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}
