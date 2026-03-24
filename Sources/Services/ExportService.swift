import Foundation
import UIKit
import PDFKit

@MainActor
final class ExportService {
    static let shared = ExportService()

    private init() {}

    // MARK: - CSV Export

    func exportCSV(skills: [Skill]) -> URL? {
        var csvContent = "Skill,Emoji,Date,Duration (min),Feel (1-5),Notes,Timer-based\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        for skill in skills {
            guard let skillId = skill.id else { continue }
            let sessions = DatabaseService.shared.getAllSessions(for: skillId)

            for session in sessions {
                let date = dateFormatter.string(from: session.practicedAt)
                let notes = (session.notes ?? "").replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ")
                let timerBased = session is TimerSession ? "Yes" : "No"
                csvContent += "\(skill.name),\(skill.emoji),\(date),\(session.durationMinutes),\(session.feelRating),\(notes),\(timerBased)\n"
            }
        }

        let fileName = "graft_export_\(formatDateForFilename(Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("CSV export error: \(error)")
            return nil
        }
    }

    func exportCSVForSkill(_ skill: Skill) -> URL? {
        guard let skillId = skill.id else { return nil }

        var csvContent = "Date,Duration (min),Feel (1-5),Notes,Timer-based\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        let sessions = DatabaseService.shared.getAllSessions(for: skillId)
        for session in sessions {
            let date = dateFormatter.string(from: session.practicedAt)
            let notes = (session.notes ?? "").replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ")
            let timerBased = session is TimerSession ? "Yes" : "No"
            csvContent += "\(date),\(session.durationMinutes),\(session.feelRating),\(notes),\(timerBased)\n"
        }

        let fileName = "\(skill.name.lowercased().replacingOccurrences(of: " ", with: "_"))_export_\(formatDateForFilename(Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("CSV export error: \(error)")
            return nil
        }
    }

    // MARK: - Practice Report (Text)

    func generatePracticeReport(for skill: Skill) -> String {
        guard let skillId = skill.id else { return "No skill selected." }

        let sessions = DatabaseService.shared.getAllSessions(for: skillId)
        let records = DatabaseService.shared.getPersonalRecords()

        let calendar = Calendar.current
        let now = Date()

        // Week stats
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let weekSessions = DatabaseService.shared.getWeeklySessions(for: skillId, weekStart: weekStart)
        let weekTotal = weekSessions.reduce(0) { $0 + $1.totalMinutes }

        // Month stats
        let monthTotal = DatabaseService.shared.getMonthlyTotalMinutes(for: skillId, month: now)
        let monthDays = DatabaseService.shared.getPracticeDaysCount(for: skillId, month: now)

        // Streak calculation
        var streak = 0
        var checkDate = now
        while true {
            let daySessions = DatabaseService.shared.getSessions(for: skillId, on: checkDate)
            if daySessions.isEmpty { break }
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        var report = """
        ═══════════════════════════════════
        PRACTICE REPORT — \(skill.emoji) \(skill.name.uppercased())
        Generated \(formatDateForReport(now))
        ═══════════════════════════════════

        WEEKLY SUMMARY
        ───────────────────────────────────
        Total time:      \(formatMinutes(weekTotal))
        Sessions:        \(sessions.filter { calendar.isDate($0.practicedAt, equalTo: now, toGranularity: .weekOfYear) }.count)
        Practice days:   \(weekSessions.filter { $0.totalMinutes > 0 }.count)/7

        MONTHLY SUMMARY
        ───────────────────────────────────
        Total time:      \(formatMinutes(monthTotal))
        Practice days:  \(monthDays)

        LIFETIME STATS
        ───────────────────────────────────
        Total sessions:  \(sessions.count)
        Total time:      \(formatMinutes(records.totalLifetimeMinutes))
        Longest streak:  \(records.longestStreakDays) days
        Longest session: \(formatMinutes(records.longestSessionMinutes))

        CURRENT STREAK
        ───────────────────────────────────
        \(streak) day\(streak == 1 ? "" : "s") in a row!

        FEEL BREAKDOWN
        ───────────────────────────────────
        """

        if !sessions.isEmpty {
            let feelCounts = (1...5).map { feel in
                sessions.filter { $0.feelRating == feel }.count
            }
            let avgFeel = Double(sessions.reduce(0) { $0 + $1.feelRating }) / Double(sessions.count)
            report += "Average feel:  \(String(format: "%.1f", avgFeel))/5\n"
            for (i, count) in feelCounts.enumerated() {
                if count > 0 {
                    let bar = String(repeating: "●", count: min(count, 20))
                    report += "  \(i+1)⭐: \(bar) \(count)\n"
                }
            }
        } else {
            report += "No sessions recorded yet.\n"
        }

        report += "\n═══════════════════════════════════\n"
        report += "Generated by Graft — Put in the work.\n"

        return report
    }

    // MARK: - PDF Export

    func exportPDF(for skill: Skill) -> URL? {
        guard let skillId = skill.id else { return nil }

        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let pdfMetaData = [
            kCGPDFContextCreator: "Graft",
            kCGPDFContextAuthor: "Graft Practice Tracker",
            kCGPDFContextTitle: "Practice Log - \(skill.name)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let sessions = DatabaseService.shared.getAllSessions(for: skillId)
        let records = DatabaseService.shared.getPersonalRecords()

        let calendar = Calendar.current
        let now = Date()
        let monthTotal = DatabaseService.shared.getMonthlyTotalMinutes(for: skillId, month: now)
        let monthDays = DatabaseService.shared.getPracticeDaysCount(for: skillId, month: now)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let weekSessions = DatabaseService.shared.getWeeklySessions(for: skillId, weekStart: weekStart)
        let weekTotal = weekSessions.reduce(0) { $0 + $1.totalMinutes }

        // Streak
        var streak = 0
        var checkDate = now
        while true {
            let daySessions = DatabaseService.shared.getSessions(for: skillId, on: checkDate)
            if daySessions.isEmpty { break }
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let data = renderer.pdfData { context in
            context.beginPage()

            var y: CGFloat = margin

            // Header
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let title = "\(skill.emoji) \(skill.name) — Practice Log"
            let titleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttr)
            y += 36

            let subtitleFont = UIFont.systemFont(ofSize: 12)
            let subtitleAttr: [NSAttributedString.Key: Any] = [.font: subtitleFont, .foregroundColor: UIColor.darkGray]
            let subtitle = "Generated \(formatDateForReport(now))"
            subtitle.draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttr)
            y += 30

            // Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: y))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            UIColor.lightGray.setStroke()
            dividerPath.stroke()
            y += 20

            // Stats section
            let sectionFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
            let sectionAttr: [NSAttributedString.Key: Any] = [.font: sectionFont, .foregroundColor: UIColor.black]
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let bodyAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]

            let statPairs: [(String, String)] = [
                ("This Week", formatMinutes(weekTotal)),
                ("This Month", formatMinutes(monthTotal)),
                ("Total Sessions", "\(sessions.count)"),
                ("Practice Days (Month)", "\(monthDays)"),
                ("Longest Streak", "\(records.longestStreakDays) days"),
                ("Total Lifetime", formatMinutes(records.totalLifetimeMinutes)),
            ]

            for (label, value) in statPairs {
                label.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttr)
                value.draw(at: CGPoint(x: margin + 150, y: y), withAttributes: bodyAttr)
                y += 22
            }

            y += 20

            // Sessions table
            "Recent Sessions".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttr)
            y += 24

            // Table header
            let headerFont = UIFont.systemFont(ofSize: 10, weight: .medium)
            let headerAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.gray]
            let cols: [(String, CGFloat)] = [("Date", margin), ("Duration", margin + 120), ("Feel", margin + 200), ("Notes", margin + 260)]
            for (header, x) in cols {
                header.draw(at: CGPoint(x: x, y: y), withAttributes: headerAttr)
            }
            y += 18

            let rowFont = UIFont.systemFont(ofSize: 10)
            let rowAttr: [NSAttributedString.Key: Any] = [.font: rowFont, .foregroundColor: UIColor.black]

            let recentSessions = Array(sessions.prefix(30))
            for session in recentSessions {
                if y > pageHeight - margin - 30 {
                    context.beginPage()
                    y = margin
                }

                dateFormatter.string(from: session.practicedAt).draw(at: CGPoint(x: margin, y: y), withAttributes: rowAttr)
                formatMinutes(session.durationMinutes).draw(at: CGPoint(x: margin + 120, y: y), withAttributes: rowAttr)
                String(repeating: "⭐", count: session.feelRating).draw(at: CGPoint(x: margin + 200, y: y), withAttributes: rowAttr)

                let notes = (session.notes ?? "").prefix(40)
                String(notes).draw(at: CGPoint(x: margin + 260, y: y), withAttributes: rowAttr)

                y += 18
            }

            // Footer on last page
            y = pageHeight - margin
            let footerFont = UIFont.systemFont(ofSize: 9)
            let footerAttr: [NSAttributedString.Key: Any] = [.font: footerFont, .foregroundColor: UIColor.gray]
            "Generated by Graft — Put in the work.".draw(at: CGPoint(x: margin, y: y), withAttributes: footerAttr)
        }

        let fileName = "\(skill.name.lowercased().replacingOccurrences(of: " ", with: "_"))_practice_log_\(formatDateForFilename(Date())).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("PDF export error: \(error)")
            return nil
        }
    }

    // MARK: - Share Image Generation

    func generateShareImage(
        skills: [Skill],
        weeklyMinutes: Int,
        streakDays: Int,
        topSkill: Skill?
    ) -> UIImage? {
        let size = CGSize(width: 1080, height: 1350)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let context = ctx.cgContext

            // Background
            let bgColor = UIColor(red: 0.051, green: 0.051, blue: 0.055, alpha: 1.0)
            context.setFillColor(bgColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            // Gradient accent at top
            let accentColor = UIColor(red: 0.906, green: 0.475, blue: 0.976, alpha: 1.0)
            let mutedColor = UIColor(red: 0.659, green: 0.333, blue: 0.969, alpha: 1.0)

            let gradientColors = [accentColor.cgColor, mutedColor.cgColor, UIColor.clear.cgColor]
            let gradientLocations: [CGFloat] = [0.0, 0.5, 1.0]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: gradientLocations) {
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: size.width * 0.3, y: 0),
                    end: CGPoint(x: size.width * 0.7, y: size.height * 0.4),
                    options: []
                )
            }

            // Graft logo text
            let logoFont = UIFont.systemFont(ofSize: 48, weight: .bold)
            let logoAttr: [NSAttributedString.Key: Any] = [.font: logoFont, .foregroundColor: UIColor.white]
            "Graft".draw(at: CGPoint(x: 80, y: 80), withAttributes: logoAttr)

            let taglineFont = UIFont.systemFont(ofSize: 20)
            let taglineAttr: [NSAttributedString.Key: Any] = [.font: taglineFont, .foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            "Put in the work.".draw(at: CGPoint(x: 80, y: 135), withAttributes: taglineAttr)

            // Main stat
            let statFont = UIFont.systemFont(ofSize: 160, weight: .bold)
            let statAttr: [NSAttributedString.Key: Any] = [.font: statFont, .foregroundColor: UIColor.white]
            let timeStr = formatMinutes(weeklyMinutes)
            let statX = size.width / 2 - timeStr.size(withAttributes: statAttr).width / 2
            timeStr.draw(at: CGPoint(x: statX, y: 260), withAttributes: statAttr)

            let unitFont = UIFont.systemFont(ofSize: 28, weight: .medium)
            let unitAttr: [NSAttributedString.Key: Any] = [.font: unitFont, .foregroundColor: UIColor.white.withAlphaComponent(0.7)]
            "this week".draw(at: CGPoint(x: 80, y: 440), withAttributes: unitAttr)

            // Streak
            let streakFont = UIFont.systemFont(ofSize: 48, weight: .bold)
            let streakAttr: [NSAttributedString.Key: Any] = [.font: streakFont, .foregroundColor: accentColor]
            let streakText = "🔥 \(streakDays)-day streak"
            let streakX = size.width / 2 - streakText.size(withAttributes: streakAttr).width / 2
            streakText.draw(at: CGPoint(x: streakX, y: 520), withAttributes: streakAttr)

            // Skills section
            let skillsY: CGFloat = 660

            // Divider
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.1).cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 80, y: skillsY))
            context.addLine(to: CGPoint(x: size.width - 80, y: skillsY))
            context.strokePath()

            let skillsLabelFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
            let skillsLabelAttr: [NSAttributedString.Key: Any] = [.font: skillsLabelFont, .foregroundColor: UIColor.white.withAlphaComponent(0.5)]
            "MY SKILLS".draw(at: CGPoint(x: 80, y: skillsY + 20), withAttributes: skillsLabelAttr)

            var skillY: CGFloat = skillsY + 60
            let skillFont = UIFont.systemFont(ofSize: 36, weight: .semibold)
            let skillMinutesFont = UIFont.systemFont(ofSize: 24)

            let calendar = Calendar.current
            let now = Date()

            for skill in skills.prefix(5) {
                guard let skillId = skill.id else { continue }
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
                let weekSessions = DatabaseService.shared.getWeeklySessions(for: skillId, weekStart: weekStart)
                let total = weekSessions.reduce(0) { $0 + $1.totalMinutes }

                let skillAttr: [NSAttributedString.Key: Any] = [.font: skillFont, .foregroundColor: UIColor.white]
                "\(skill.emoji) \(skill.name)".draw(at: CGPoint(x: 80, y: skillY), withAttributes: skillAttr)

                let minutesAttr: [NSAttributedString.Key: Any] = [.font: skillMinutesFont, .foregroundColor: accentColor]
                let minutesText = formatMinutes(total)
                let minutesX = size.width - 80 - minutesText.size(withAttributes: minutesAttr).width
                minutesText.draw(at: CGPoint(x: minutesX, y: skillY + 4), withAttributes: minutesAttr)

                skillY += 70
            }

            // Footer
            let footerFont = UIFont.systemFont(ofSize: 16)
            let footerAttr: [NSAttributedString.Key: Any] = [.font: footerFont, .foregroundColor: UIColor.white.withAlphaComponent(0.3)]
            "graft.app".draw(at: CGPoint(x: size.width / 2 - "graft.app".size(withAttributes: footerAttr).width / 2, y: size.height - 80), withAttributes: footerAttr)
        }
    }

    // MARK: - Helpers

    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatDateForReport(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    func formatMinutes(_ minutes: Int) -> String {
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
