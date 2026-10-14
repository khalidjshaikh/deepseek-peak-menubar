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
        let infoItem = NSMenuItem(title: "Peak: 01–04, 06–10 UTC (2×)", action: nil, keyEquivalent: "")
        infoItem.isEnabled = false
        menu.addItem(infoItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        statusItem.menu = menu

        update()
        timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }

    private func isPeakNow() -> Bool {
        let comps = utcCalendar.dateComponents([.hour, .minute], from: Date())
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let first = minutes >= 60 && minutes < 240   // 01:00–04:00
        let second = minutes >= 360 && minutes < 600  // 06:00–10:00
        return first || second
    }

    private func nextTransitionDescription() -> String {
        // nearest boundary among 01:00,04:00,06:00,10:00
        let comps = utcCalendar.dateComponents([.hour, .minute], from: Date())
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let boundaries = [60, 240, 360, 600, 60 + 1440, 240 + 1440, 360 + 1440, 600 + 1440]
        guard let next = boundaries.first(where: { $0 > minutes }) else { return "" }
        let delta = next - minutes
        let h = delta / 60
        let m = delta % 60
        let timeStr: String
        let mod = next % 1440
        let hh = mod / 60
        let mm = mod % 60
        timeStr = String(format: "%02d:%02d UTC", hh, mm)
        return "Changes in \(h)h \(m)m (at \(timeStr))"
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
