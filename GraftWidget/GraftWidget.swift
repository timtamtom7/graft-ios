import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct GraftWidgetEntry: TimelineEntry {
    let date: Date
    let skillName: String
    let skillEmoji: String
    let weeklyMinutes: Int
    let streakDays: Int
    let practiceToday: Bool
}

// MARK: - Provider

struct GraftWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> GraftWidgetEntry {
        GraftWidgetEntry(
            date: Date(),
            skillName: "Guitar",
            skillEmoji: "🎸",
            weeklyMinutes: 120,
            streakDays: 5,
            practiceToday: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GraftWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GraftWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> GraftWidgetEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.graft.app")

        let skillName = sharedDefaults?.string(forKey: "widget_skill_name") ?? "Practice"
        let skillEmoji = sharedDefaults?.string(forKey: "widget_skill_emoji") ?? "🎯"
        let weeklyMinutes = sharedDefaults?.integer(forKey: "widget_weekly_minutes") ?? 0
        let streakDays = sharedDefaults?.integer(forKey: "widget_streak_days") ?? 0
        let practiceToday = sharedDefaults?.bool(forKey: "widget_practice_today") ?? false

        return GraftWidgetEntry(
            date: Date(),
            skillName: skillName,
            skillEmoji: skillEmoji,
            weeklyMinutes: weeklyMinutes,
            streakDays: streakDays,
            practiceToday: practiceToday
        )
    }
}

// MARK: - Widget Views

struct GraftWidgetEntryView: View {
    var entry: GraftWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.skillEmoji)
                    .font(.system(size: 20))
                Spacer()
                if entry.practiceToday {
                    Text("✓")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "4ade80"))
                }
            }

            Spacer()

            Text(formatMinutes(entry.weeklyMinutes))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Text("this week")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 11))
                Text("\(entry.streakDays) day streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(hex: "1e1e21"), Color(hex: "0d0d0e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var mediumWidget: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.skillEmoji)
                        .font(.system(size: 24))
                    Text(entry.skillName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Text(formatMinutes(entry.weeklyMinutes))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Text("this week")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                // Streak
                VStack(alignment: .trailing, spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 28))
                    Text("\(entry.streakDays)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "e879f9"))
                    Text("day streak")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if entry.practiceToday {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "4ade80"))
                        Text("Practiced today")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "4ade80"))
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(Color(hex: "e879f9"))
                        Text("Log session")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "e879f9"))
                    }
                }
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(hex: "1e1e21"), Color(hex: "0d0d0e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        }
        return "\(mins)m"
    }
}

// MARK: - Widget Configuration

struct GraftWidget: Widget {
    let kind: String = "GraftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GraftWidgetProvider()) { entry in
            GraftWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Graft")
        .description("Quick view of your weekly practice time and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Bundle

@main
struct GraftWidgetBundle: WidgetBundle {
    var body: some Widget {
        GraftWidget()
    }
}

// MARK: - Widget Data Updater

/// Call this from the main app to update widget data
struct GraftWidgetUpdater {
    static func updateWidgetData(
        skillName: String,
        skillEmoji: String,
        weeklyMinutes: Int,
        streakDays: Int,
        practicedToday: Bool
    ) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.graft.app")
        sharedDefaults?.set(skillName, forKey: "widget_skill_name")
        sharedDefaults?.set(skillEmoji, forKey: "widget_skill_emoji")
        sharedDefaults?.set(weeklyMinutes, forKey: "widget_weekly_minutes")
        sharedDefaults?.set(streakDays, forKey: "widget_streak_days")
        sharedDefaults?.set(practicedToday, forKey: "widget_practice_today")

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "GraftWidget")
    }
}
