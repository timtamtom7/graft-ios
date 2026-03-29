import SwiftUI
import AppKit

// MARK: - Menu Bar Controller

final class GraftMenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    var onLogSession: (() -> Void)?
    var currentStreak: Int = 0

    override init() {
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "book.closed.fill", accessibilityDescription: "Graft")
            button.image?.isTemplate = true
        }

        menu = NSMenu()
        menu?.delegate = self
        statusItem?.menu = menu

        rebuildMenu()
    }

    func rebuildMenu() {
        menu?.removeAllItems()

        // Header
        let titleItem = NSMenuItem(title: "📒 Graft", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu?.addItem(titleItem)

        menu?.addItem(NSMenuItem.separator())

        // Streak
        let streakItem = NSMenuItem(title: "🔥 \(currentStreak) day streak", action: nil, keyEquivalent: "")
        streakItem.isEnabled = false
        menu?.addItem(streakItem)

        menu?.addItem(NSMenuItem.separator())

        // Log Session
        let logItem = NSMenuItem(
            title: "Log Session...",
            action: #selector(logSessionClicked),
            keyEquivalent: "l"
        )
        logItem.keyEquivalentModifierMask = [.command]
        logItem.target = self
        menu?.addItem(logItem)

        // Open Graft
        let openItem = NSMenuItem(
            title: "Open Graft",
            action: #selector(openGraftClicked),
            keyEquivalent: "o"
        )
        openItem.keyEquivalentModifierMask = [.command]
        openItem.target = self
        menu?.addItem(openItem)

        menu?.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Graft",
            action: #selector(quitClicked),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu?.addItem(quitItem)
    }

    @objc private func logSessionClicked() {
        onLogSession?()
    }

    @objc private func openGraftClicked() {
        NSWorkspace.shared.launchApplication("GraftMac")
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }

    func updateStreak(_ streak: Int) {
        currentStreak = streak
        rebuildMenu()
    }

    @MainActor
    func updateStreakFromDatabase() {
        let skills = DatabaseService.shared.getAllSkills()
        guard let activeSkill = skills.first(where: { $0.isActive }) ?? skills.first,
              let skillId = activeSkill.id else {
            updateStreak(0)
            return
        }

        let sessions = DatabaseService.shared.getAllSessions(for: skillId)
        let streak = calculateStreak(sessions: sessions)
        updateStreak(streak)
    }

    private func calculateStreak(sessions: [Session]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sortedDates = sessions
            .map { calendar.startOfDay(for: $0.practicedAt) }
            .reduce(into: [Date]()) { if !$0.contains($1) { $0.append($1) } }
            .sorted(by: >)

        var streak = 0
        var checkDate = today
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
        }
        return streak
    }
}
