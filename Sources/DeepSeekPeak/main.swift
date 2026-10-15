import Cocoa

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var statusMenuItem: NSMenuItem!
    private var nextMenuItem: NSMenuItem!
    private let utcCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    // App version displayed in the UI
    private let appVersion: String = "1.0.9"

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.font = NSFont.systemFont(ofSize: 13, weight: .medium)

        let menu = NSMenu()
        let titleItem = NSMenuItem(title: "DeepSeek Peak Hours", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        statusMenuItem = NSMenuItem(title: "Status: —", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        nextMenuItem = NSMenuItem(title: "Next change: —", action: nil, keyEquivalent: "")
        nextMenuItem.isEnabled = false
        menu.addItem(nextMenuItem)
        menu.addItem(NSMenuItem.separator())
        let infoItem = NSMenuItem(title: "UTC Peak: Mon-Fri 01:00-04:00, 06:00-10:00 UTC (2×)", action: nil, keyEquivalent: "")
        infoItem.isEnabled = false
        menu.addItem(infoItem)
        // Version item
        let versionItem = NSMenuItem(title: "Version: v\(appVersion)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        menu.addItem(NSMenuItem.separator())
        // Separate CT info item
        let ctInfoItem = NSMenuItem(title: "CT Peak: 8:00-11:00 PM prev day, 1:00-5:00 AM CT (2×)", action: nil, keyEquivalent: "")
        ctInfoItem.isEnabled = false
        menu.addItem(ctInfoItem)
        // Build number item
        let buildItem = NSMenuItem(title: "Build: 1.0.4", action: nil, keyEquivalent: "")
        buildItem.isEnabled = false
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        statusItem.menu = menu

        update()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }

    private func isPeakNow() -> Bool {
        let comps = utcCalendar.dateComponents([.hour, .minute, .weekday], from: Date())
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let weekday = comps.weekday ?? 1
        // Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6, Sunday=7
        let isWeekday = weekday >= 1 && weekday <= 5
        let first = isWeekday && minutes >= 60 && minutes < 240   // 01:00–04:00
        let second = isWeekday && minutes >= 360 && minutes < 600  // 06:00–10:00
        return first || second
    }

    private func nextTransitionDescription() -> String {
        // nearest boundary among 01:00,04:00,06:00,10:00, considering weekday
        let comps = utcCalendar.dateComponents([.hour, .minute, .weekday], from: Date())
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let weekday = comps.weekday ?? 1
        let isWeekday = weekday >= 1 && weekday <= 5

        var nextMinutes: Int?
        var nextWeekday: Int?

        // Check today's boundaries first if it's a weekday
        if isWeekday {
            let boundaries = [60, 240, 360, 600]
            let next = boundaries.first(where: { $0 > minutes })
            if let next = next {
                nextMinutes = next
                nextWeekday = weekday
            } else {
                // No more boundaries today; find next weekday 01:00
                // (instead of hardcoding Monday)
            }
        }

        // If no today boundary found or it's weekend, find next weekday 01:00
        if nextMinutes == nil {
            // Find next weekday starting from tomorrow
            for i in 1...7 {
                let day = (weekday + i - 1) % 7 + 1  // next days, wrapping
                if day >= 1 && day <= 5 {
                    nextWeekday = day
                    nextMinutes = 60  // 01:00
                    break
                }
            }
        }

        guard let minutes = nextMinutes, let weekday = nextWeekday else { return "" }
        // Compute delta from now in seconds for h/m/s breakdown
        let nowComps = utcCalendar.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (nowComps.hour ?? 0) * 60 + (nowComps.minute ?? 0)
        let delta = minutes - nowMinutes
        let adjustedDelta = delta > 0 ? delta : delta + 1440
        // Break down adjustedDelta (in minutes) into h/m/s
        let deltaTotalSeconds = adjustedDelta * 60
        let h = deltaTotalSeconds / 3600
        let m = (deltaTotalSeconds / 60) % 60
        let deltaS = deltaTotalSeconds % 60
        let weekdayName: String
        switch weekday {
        case 1: weekdayName = "Mon"
        case 2: weekdayName = "Tue"
        case 3: weekdayName = "Wed"
        case 4: weekdayName = "Thu"
        case 5: weekdayName = "Fri"
        default: weekdayName = ""
        }
        // Show seconds as :00 since we only track minute granularity
        let totalSeconds = minutes * 60
        let nowSeconds = nowMinutes * 60
        let s = (totalSeconds - nowSeconds) % 60
        let timeStr: String
        timeStr = String(format: "%02d:%02d:%02d UTC", (minutes / 60) % 24, minutes % 60, s)
        return "Changes in \(h)h \(m)m \(deltaS)s (at \(timeStr)) on \(weekdayName)"
    }

    private func update() {
        let peak = isPeakNow()
        let emoji = peak ? "🔴" : "🟢"
        let label = peak ? "Peak 2×" : "Off-Peak"
        let color: NSColor = peak ? .systemRed : .systemGreen
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
        ]
        statusItem.button?.attributedTitle = NSAttributedString(string: "\(emoji) \(label)", attributes: attrs)
        statusItem.button?.toolTip = "DeepSeek: \(label)\n\(nextTransitionDescription())"
        statusMenuItem?.title = "Status: \(label)"
        nextMenuItem?.title = nextTransitionDescription()
    }

    @objc private func tick() {
        update()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
