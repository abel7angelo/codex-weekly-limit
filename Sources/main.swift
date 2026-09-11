import Cocoa

struct Window {
    let used: Double
    let reset: Date?

    var remaining: Int {
        Int((100 - min(100, max(0, used))).rounded())
    }

    init?(_ value: Any?) {
        guard let data = value as? [String: Any],
              let percent = numberValue(data["usedPercent"]),
              percent.isFinite else { return nil }

        used = percent
        reset = numberValue(data["resetsAt"]).map { Date(timeIntervalSince1970: $0) }
    }
}

let codexBundleIdentifier = "com.openai.codex"
let preferenceShowShort = "CodexWeeklyLimit.showShortInStatus"
let preferenceCompact = "CodexWeeklyLimit.compactStatus"
let preferenceRotate = "CodexWeeklyLimit.rotateStatus"
let menuWidth: CGFloat = 280

enum InterfaceLanguage: Equatable {
    case english
    case portugueseBrazil

    static var current: InterfaceLanguage {
        let configuredLanguage = UserDefaults.standard.array(forKey: "AppleLanguages")?.first as? String
        let preferredLanguage = (configuredLanguage ?? Locale.preferredLanguages.first ?? "")
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        return preferredLanguage.hasPrefix("pt-br") ? .portugueseBrazil : .english
    }
}

struct MenuCopy {
    let language: InterfaceLanguage

    static var current: MenuCopy {
        MenuCopy(language: .current)
    }

    var weeklyLimit: String { language == .portugueseBrazil ? "Limite semanal" : "Weekly limit" }
    var fiveHourWindow: String { language == .portugueseBrazil ? "Janela de 5 horas" : "5-hour window" }
    var remaining: String { language == .portugueseBrazil ? "restante" : "remaining" }
    var unavailable: String { language == .portugueseBrazil ? "indisponível" : "unavailable" }
    var unavailableLimit: String { language == .portugueseBrazil ? "Limite indisponível" : "Limit unavailable" }
    var notIncluded: String { language == .portugueseBrazil ? "não incluído" : "not included" }
    var notIncludedInPlan: String { language == .portugueseBrazil ? "Não incluído neste plano" : "Not included in this plan" }
    var showFiveHour: String { language == .portugueseBrazil ? "Exibir limite de 5 horas na barra" : "Show 5-hour limit in menu bar" }
    var alternate: String { language == .portugueseBrazil ? "Alternar a cada 30 segundos" : "Alternate every 30 seconds" }
    var startWithFiveHour: String { language == .portugueseBrazil ? "Começar pela janela de 5 horas" : "Start with the 5-hour window" }
    var compact: String { language == .portugueseBrazil ? "Modo compacto na barra" : "Compact mode in menu bar" }
    var automatic: String { language == .portugueseBrazil ? "Atualização automática a cada 5 min" : "Automatic update every 5 min" }
    var refresh: String { language == .portugueseBrazil ? "Atualizar agora" : "Refresh now" }
    var refreshing: String { language == .portugueseBrazil ? "Atualizando…" : "Refreshing…" }
    var openCodex: String { language == .portugueseBrazil ? "Abrir Codex / ChatGPT" : "Open Codex / ChatGPT" }
    var hideUntilCodexCloses: String { language == .portugueseBrazil ? "Ocultar até fechar o Codex" : "Hide until Codex closes" }
    var updatedPrefix: String { language == .portugueseBrazil ? "Atualizado em" : "Updated on" }
    var warningPrefix: String { language == .portugueseBrazil ? "Aviso" : "Warning" }
    var weeklyAbbreviation: String { language == .portugueseBrazil ? "S" : "W" }
    var dateFormat: String { language == .portugueseBrazil ? "dd/MM 'às' HH:mm" : "dd/MM 'at' HH:mm" }
    var localeIdentifier: String { language == .portugueseBrazil ? "pt_BR" : "en_US" }
    var now: String { language == .portugueseBrazil ? "agora" : "now" }
    var daySuffix: String { "d" }
    var hourSuffix: String { "h" }
    var minuteSuffix: String { "min" }

    func renewal(date: String, countdown: String) -> String {
        language == .portugueseBrazil
            ? "Renova em \(date) · faltam \(countdown)"
            : "Renews on \(date) · \(countdown) left"
    }

    func updated(date: String) -> String {
        "\(updatedPrefix) \(date)"
    }

    func warning(_ message: String) -> String {
        "\(warningPrefix): \(message)"
    }

    func statusTooltip(weekly: String, short: String, shortIncluded: Bool) -> String {
        guard shortIncluded else {
            return language == .portugueseBrazil
                ? "Codex: semanal \(weekly) · janela de 5 horas não incluída neste plano"
                : "Codex: weekly \(weekly) · 5-hour window not included in this plan"
        }
        return language == .portugueseBrazil
            ? "Codex: semanal \(weekly) · janela de 5 horas \(short)"
            : "Codex: weekly \(weekly) · 5-hour window \(short)"
    }

    var codexNotFound: String { language == .portugueseBrazil ? "Codex não foi encontrado neste Mac" : "Codex was not found on this Mac" }
    var failedToStart: String { language == .portugueseBrazil ? "Não foi possível iniciar a consulta local do Codex" : "Could not start the local Codex query" }
    var initializationFailed: String { language == .portugueseBrazil ? "O Codex não aceitou a consulta de limites" : "Codex did not accept the limits query" }
    var responseUnavailable: String { language == .portugueseBrazil ? "O Codex não retornou os limites" : "Codex did not return the limits" }
    var queryFailed: String { language == .portugueseBrazil ? "Não foi possível consultar os limites" : "Could not query limits" }
}

let menuCopy = MenuCopy.current

func numberValue(_ value: Any?) -> Double? {
    guard let number = value as? NSNumber else { return nil }
    let value = number.doubleValue
    return value.isFinite ? value : nil
}

func codexApplicationURL() -> URL? {
    NSWorkspace.shared.urlForApplication(withBundleIdentifier: codexBundleIdentifier)
}

enum LimitReadError: LocalizedError {
    case codexNotFound
    case failedToStart
    case initializationFailed
    case responseUnavailable

    var errorDescription: String? {
        let copy = menuCopy
        switch self {
        case .codexNotFound:
            return copy.codexNotFound
        case .failedToStart:
            return copy.failedToStart
        case .initializationFailed:
            return copy.initializationFailed
        case .responseUnavailable:
            return copy.responseUnavailable
        }
    }
}

func readLimits() throws -> [String: Any] {
    guard let applicationURL = codexApplicationURL() else {
        throw LimitReadError.codexNotFound
    }

    let process = Process()
    process.executableURL = applicationURL.appendingPathComponent("Contents/Resources/codex")
    process.arguments = ["app-server", "--stdio"]

    let input = Pipe()
    let output = Pipe()
    process.standardInput = input
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
    } catch {
        throw LimitReadError.failedToStart
    }

    let timeout = DispatchWorkItem {
        if process.isRunning { process.terminate() }
    }
    DispatchQueue.global().asyncAfter(deadline: .now() + 25, execute: timeout)

    defer {
        timeout.cancel()
        try? input.fileHandleForWriting.close()
        if process.isRunning { process.terminate() }
    }

    func send(_ message: [String: Any]) throws {
        var data = try JSONSerialization.data(withJSONObject: message)
        data.append(10)
        try input.fileHandleForWriting.write(contentsOf: data)
    }

    do {
        try send([
            "id": 1,
            "method": "initialize",
            "params": [
                "clientInfo": [
                    "name": "codex_weekly_menubar",
                    "version": "1.1.0"
                ]
            ]
        ])
    } catch {
        throw LimitReadError.failedToStart
    }

    var buffer = Data()
    while true {
        let chunk = output.fileHandleForReading.availableData
        if chunk.isEmpty { break }
        buffer.append(chunk)

        while let end = buffer.firstIndex(of: 10) {
            let line = buffer.subdata(in: 0..<end)
            buffer.removeSubrange(0...end)
            guard let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else { continue }

            if object["id"] as? Int == 1 {
                guard object["error"] == nil else { throw LimitReadError.initializationFailed }
                do {
                    try send(["method": "initialized"])
                    try send(["id": 2, "method": "account/rateLimits/read"])
                } catch {
                    throw LimitReadError.failedToStart
                }
            }

            if object["id"] as? Int == 2 {
                guard object["error"] == nil,
                      let result = object["result"] as? [String: Any] else {
                    throw LimitReadError.responseUnavailable
                }
                return result
            }
        }
    }

    throw LimitReadError.responseUnavailable
}

func codexLimitBucket(_ result: [String: Any]) -> [String: Any] {
    if let buckets = result["rateLimitsByLimitId"] as? [String: Any],
       let codex = buckets["codex"] as? [String: Any] {
        return codex
    }
    return result["rateLimits"] as? [String: Any] ?? [:]
}

func limitWindow(in bucket: [String: Any], durationMinutes: Int) -> Window? {
    for value in bucket.values {
        guard let data = value as? [String: Any],
              let duration = numberValue(data["windowDurationMins"]),
              Int(duration) == durationMinutes else { continue }
        return Window(data)
    }
    return nil
}

private final class ProgressBarView: NSView {
    var remaining = 0 {
        didSet { needsDisplay = true }
    }

    var stale = false {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        let track = bounds.insetBy(dx: 0, dy: 1)
        guard track.width > 0, track.height > 0 else { return }

        NSColor.separatorColor.withAlphaComponent(0.35).setFill()
        NSBezierPath(roundedRect: track, xRadius: track.height / 2, yRadius: track.height / 2).fill()

        let fraction = CGFloat(min(100, max(0, remaining))) / 100
        let fill = NSRect(x: track.minX, y: track.minY, width: track.width * fraction, height: track.height)
        guard fill.width > 0 else { return }

        let color = stale
            ? NSColor.secondaryLabelColor
            : remaining <= 10 ? NSColor.systemRed : remaining <= 25 ? NSColor.systemOrange : NSColor.systemGreen
        color.setFill()
        NSBezierPath(roundedRect: fill, xRadius: track.height / 2, yRadius: track.height / 2).fill()
    }
}

private final class LimitCardView: NSView {
    private let copy: MenuCopy
    private let headingLabel: NSTextField
    private let percentLabel: NSTextField
    private let remainingLabel: NSTextField
    private let resetLabel: NSTextField
    private let progressBar = ProgressBarView(frame: .zero)

    init(title: String, copy: MenuCopy) {
        self.copy = copy
        headingLabel = NSTextField(labelWithString: title)
        percentLabel = NSTextField(labelWithString: "—")
        remainingLabel = NSTextField(labelWithString: copy.remaining)
        resetLabel = NSTextField(labelWithString: "")
        super.init(frame: NSRect(x: 0, y: 0, width: menuWidth, height: 78))

        headingLabel.font = NSFont.boldSystemFont(ofSize: 13)
        headingLabel.textColor = NSColor.secondaryLabelColor

        percentLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        percentLabel.textColor = NSColor.labelColor

        remainingLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        remainingLabel.textColor = NSColor.secondaryLabelColor
        remainingLabel.alignment = .right

        resetLabel.font = NSFont.systemFont(ofSize: 11.5)
        resetLabel.textColor = NSColor.secondaryLabelColor
        resetLabel.lineBreakMode = .byTruncatingTail

        addSubview(headingLabel)
        addSubview(percentLabel)
        addSubview(remainingLabel)
        addSubview(progressBar)
        addSubview(resetLabel)
        setAccessibilityLabel(title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }

    override func layout() {
        super.layout()
        let left: CGFloat = 14
        let right: CGFloat = 14
        let width = max(0, bounds.width - left - right)

        headingLabel.frame = NSRect(x: left, y: 4, width: width, height: 17)
        percentLabel.frame = NSRect(x: left, y: 21, width: 74, height: 23)
        remainingLabel.frame = NSRect(x: max(left, bounds.width - right - 84), y: 23, width: 84, height: 17)
        progressBar.frame = NSRect(x: left, y: 48, width: width, height: 5)
        resetLabel.frame = NSRect(x: left, y: 58, width: width, height: 17)
    }

    func update(title: String, window: Window?, stale: Bool, unavailableForPlan: Bool = false) {
        headingLabel.stringValue = title
        progressBar.stale = stale

        guard let window = window else {
            percentLabel.stringValue = "—"
            remainingLabel.stringValue = unavailableForPlan ? copy.notIncluded : copy.unavailable
            resetLabel.stringValue = unavailableForPlan ? copy.notIncludedInPlan : copy.unavailableLimit
            progressBar.remaining = 0
            progressBar.isHidden = unavailableForPlan
            setAccessibilityLabel("\(title): \(unavailableForPlan ? copy.notIncludedInPlan : copy.unavailableLimit)")
            return
        }

        percentLabel.stringValue = "\(window.remaining)%"
        remainingLabel.stringValue = copy.remaining
        progressBar.isHidden = false
        progressBar.remaining = window.remaining
        setAccessibilityLabel("\(title): \(window.remaining)% \(copy.remaining)")
    }

    func updateReset(_ text: String) {
        resetLabel.stringValue = text
    }
}

private final class MenuTextRowView: NSView {
    private let label: NSTextField

    init(text: String, font: NSFont, color: NSColor) {
        label = NSTextField(labelWithString: text)
        super.init(frame: NSRect(x: 0, y: 0, width: menuWidth, height: 24))

        label.font = font
        label.textColor = color
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        addSubview(label)

        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        update(text: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }

    override var fittingSize: NSSize {
        NSSize(width: menuWidth, height: 24)
    }

    override func layout() {
        super.layout()
        label.frame = NSRect(x: 14, y: 3, width: max(0, bounds.width - 28), height: 18)
    }

    func update(text: String) {
        label.stringValue = text
        label.toolTip = text.isEmpty ? nil : text
        setAccessibilityLabel(text)
    }
}

private final class GreenSwitch: NSControl, NSAccessibilitySwitch, NSAnimationDelegate {
    private var switchAccessibilityLabel = ""
    private var visualProgress: CGFloat = 0
    private var stateAnimation: NSAnimation?
    private var animationStart: CGFloat = 0
    private var animationEnd: CGFloat = 0

    var state: NSControl.StateValue = .off {
        didSet {
            needsDisplay = true
            if oldValue != state {
                NSAccessibility.post(element: self, notification: .valueChanged)
                animate(to: state == .off ? 0 : 1)
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilitySubrole(.switch)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSwitchAccessibilityLabel(_ label: String) {
        switchAccessibilityLabel = label
        setAccessibilityLabel(label)
    }

    override func accessibilityLabel() -> String? {
        switchAccessibilityLabel
    }

    func accessibilityValue() -> String? {
        state == .on ? "1" : "0"
    }

    private func toggle() {
        guard isEnabled else { return }
        state = state == .on ? .off : .on
        _ = sendAction(action, to: target)
    }

    override func mouseDown(with event: NSEvent) {
        toggle()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 49 || event.keyCode == 76 {
            toggle()
        } else {
            super.keyDown(with: event)
        }
    }

    override func accessibilityPerformPress() -> Bool {
        toggle()
        return true
    }

    private func animate(to target: CGFloat) {
        stateAnimation?.stop()
        animationStart = visualProgress
        animationEnd = target

        guard window != nil, abs(animationStart - animationEnd) > 0.001 else {
            visualProgress = target
            needsDisplay = true
            return
        }

        let animation = NSAnimation(duration: 0.16, animationCurve: .easeOut)
        animation.animationBlockingMode = .nonblocking
        animation.frameRate = 60
        animation.delegate = self
        stateAnimation = animation
        animation.start()
    }

    func animation(_ animation: NSAnimation, valueForProgress progress: Float) -> Float {
        guard stateAnimation === animation else { return Float(visualProgress) }
        visualProgress = animationStart + (animationEnd - animationStart) * CGFloat(progress)
        needsDisplay = true
        return Float(visualProgress)
    }

    func animationDidEnd(_ animation: NSAnimation) {
        guard stateAnimation === animation else { return }
        visualProgress = animationEnd
        stateAnimation = nil
        needsDisplay = true
    }

    func animationDidStop(_ animation: NSAnimation) {
        guard stateAnimation === animation else { return }
        visualProgress = animationEnd
        stateAnimation = nil
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let track = bounds.insetBy(dx: 1, dy: 2)
        guard track.width > track.height, track.height > 0 else { return }

        let progress = min(1, max(0, visualProgress))
        let offColor = NSColor.systemGray.withAlphaComponent(0.68)
        let trackColor = offColor.blended(withFraction: progress, of: NSColor.systemGreen)
            ?? (progress > 0.5 ? NSColor.systemGreen : offColor)
        trackColor.setFill()
        NSBezierPath(roundedRect: track, xRadius: track.height / 2, yRadius: track.height / 2).fill()

        let knobDiameter = max(1, track.height - 4)
        let offX = track.minX + 2
        let onX = track.maxX - knobDiameter - 2
        let knobX = offX + (onX - offX) * progress
        let knob = NSRect(
            x: knobX,
            y: track.midY - knobDiameter / 2,
            width: knobDiameter,
            height: knobDiameter
        )
        NSColor.white.setFill()
        NSBezierPath(ovalIn: knob).fill()
    }
}

private final class SwitchRowView: NSStackView {
    let titleLabel: NSTextField
    let toggle: GreenSwitch

    init(title: String, target: AnyObject, action: Selector) {
        titleLabel = NSTextField(labelWithString: title)
        let spacer = NSView(frame: .zero)
        toggle = GreenSwitch(frame: .zero)
        super.init(frame: NSRect(x: 0, y: 0, width: menuWidth, height: 24))

        orientation = .horizontal
        alignment = .centerY
        distribution = .fill
        spacing = 8
        edgeInsets = NSEdgeInsets(top: 1, left: 14, bottom: 1, right: 14)

        titleLabel.font = NSFont.systemFont(ofSize: 13)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        toggle.controlSize = .small
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.widthAnchor.constraint(equalToConstant: 32).isActive = true
        toggle.heightAnchor.constraint(equalToConstant: 18).isActive = true
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)
        toggle.target = target
        toggle.action = action
        toggle.setSwitchAccessibilityLabel(title)

        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addArrangedSubview(titleLabel)
        addArrangedSubview(spacer)
        addArrangedSubview(toggle)
    }

    func updateTitle(_ title: String) {
        titleLabel.stringValue = title
        toggle.setSwitchAccessibilityLabel(title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    private let weeklyCardItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let shortCardItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let showShortItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let rotateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let compactItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let updatedItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let errorItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let automaticItem = NSMenuItem(title: menuCopy.automatic, action: nil, keyEquivalent: "")
    private let refreshItem = NSMenuItem(title: menuCopy.refresh, action: #selector(refresh), keyEquivalent: "")
    private let openItem = NSMenuItem(title: menuCopy.openCodex, action: #selector(openCodex), keyEquivalent: "")
    private let hideItem = NSMenuItem(title: menuCopy.hideUntilCodexCloses, action: #selector(hideUntilCodexCloses), keyEquivalent: "")

    private var weeklyCard: LimitCardView!
    private var shortCard: LimitCardView!
    private var showShortRow: SwitchRowView!
    private var rotateRow: SwitchRowView!
    private var compactRow: SwitchRowView!
    private var updatedRow: MenuTextRowView!
    private var errorRow: MenuTextRowView!
    private var automaticRow: MenuTextRowView!

    private var result: [String: Any] = [:]
    private var shortLimitAvailable: Bool?
    private var updated: Date?
    private var failed = false
    private var errorMessage: String?
    private var loading = false
    private var refreshTimer: Timer?
    private var displayTimer: Timer?
    private var showShortInStatus = UserDefaults.standard.bool(forKey: preferenceShowShort)
    private var compactStatus = UserDefaults.standard.bool(forKey: preferenceCompact)
    private var rotateStatus = UserDefaults.standard.bool(forKey: preferenceRotate)
    private var rotatingShort = false

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: menuCopy.localeIdentifier)
        formatter.dateFormat = menuCopy.dateFormat
        return formatter
    }()

    private var suppressedIndicatorURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/CodexWeeklyLimit/indicator.disabled")
    }

    private func displayedShort(using short: Window?) -> Bool {
        guard short != nil else { return false }
        return rotateStatus ? rotatingShort : showShortInStatus
    }

    private func restartDisplayTimer() {
        displayTimer?.invalidate()
        let timer = Timer(timeInterval: 30, target: self, selector: #selector(redraw), userInfo: nil, repeats: true)
        displayTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func countdown(to date: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSinceNow.rounded()))
        if seconds == 0 { return menuCopy.now }

        let minutes = seconds / 60
        let days = minutes / 1440
        let hours = (minutes % 1440) / 60
        let remainingMinutes = minutes % 60

        if days > 0 {
            return hours > 0
                ? "\(days)\(menuCopy.daySuffix) \(hours)\(menuCopy.hourSuffix)"
                : "\(days)\(menuCopy.daySuffix)"
        }
        if hours > 0 {
            return remainingMinutes > 0
                ? "\(hours)\(menuCopy.hourSuffix) \(remainingMinutes)\(menuCopy.minuteSuffix)"
                : "\(hours)\(menuCopy.hourSuffix)"
        }
        return "\(max(1, remainingMinutes))\(menuCopy.minuteSuffix)"
    }

    private func configureMenu() {
        menu.autoenablesItems = false

        weeklyCard = LimitCardView(title: menuCopy.weeklyLimit, copy: menuCopy)
        shortCard = LimitCardView(title: menuCopy.fiveHourWindow, copy: menuCopy)
        showShortRow = SwitchRowView(
            title: menuCopy.showFiveHour,
            target: self,
            action: #selector(toggleShortStatusFromSwitch(_:))
        )
        rotateRow = SwitchRowView(
            title: menuCopy.alternate,
            target: self,
            action: #selector(toggleRotateStatusFromSwitch(_:))
        )
        compactRow = SwitchRowView(
            title: menuCopy.compact,
            target: self,
            action: #selector(toggleCompactStatusFromSwitch(_:))
        )
        updatedRow = MenuTextRowView(
            text: "",
            font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            color: NSColor.tertiaryLabelColor
        )
        errorRow = MenuTextRowView(
            text: "",
            font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            color: NSColor.systemOrange
        )
        automaticRow = MenuTextRowView(
            text: automaticItem.title,
            font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            color: NSColor.tertiaryLabelColor
        )

        weeklyCardItem.view = weeklyCard
        shortCardItem.view = shortCard
        showShortItem.view = showShortRow
        rotateItem.view = rotateRow
        compactItem.view = compactRow
        updatedItem.view = updatedRow
        errorItem.view = errorRow
        automaticItem.view = automaticRow
        refreshItem.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: refreshItem.title)
        openItem.image = NSImage(systemSymbolName: "arrow.up.right.square", accessibilityDescription: openItem.title)
        hideItem.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: hideItem.title)
        for item in [refreshItem, openItem, hideItem] {
            item.image?.size = NSSize(width: 13, height: 13)
            item.image?.isTemplate = true
        }
        menu.addItem(weeklyCardItem)
        menu.addItem(.separator())
        menu.addItem(shortCardItem)
        menu.addItem(.separator())
        menu.addItem(showShortItem)
        menu.addItem(rotateItem)
        menu.addItem(compactItem)
        menu.addItem(.separator())
        menu.addItem(updatedItem)
        menu.addItem(errorItem)
        menu.addItem(automaticItem)
        menu.addItem(refreshItem)
        menu.addItem(openItem)
        menu.addItem(.separator())
        menu.addItem(hideItem)

        refreshItem.target = self
        openItem.target = self
        hideItem.target = self
        status.menu = menu
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenu()
        rotatingShort = showShortInStatus
        draw()
        refresh()

        refreshTimer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        restartDisplayTimer()
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refresh), name: NSWorkspace.didWakeNotification, object: nil)
    }

    private func draw() {
        let bucket = codexLimitBucket(result)
        let weekly = limitWindow(in: bucket, durationMinutes: 10080)
        let short = limitWindow(in: bucket, durationMinutes: 300)
        let displayingShort = displayedShort(using: short)
        let shortUnavailableForPlan = shortLimitAvailable == false
        let displayed = displayingShort ? short : weekly
        let weeklyStale = failed || weekly?.reset.map { $0 <= Date() } == true
        let shortStale = failed || short?.reset.map { $0 <= Date() } == true
        let displayedStale = displayingShort ? shortStale : weeklyStale
        let weeklyLabel = weekly.map { "\($0.remaining)%" } ?? "—"
        let shortLabel = short.map { "\($0.remaining)%" } ?? "—"
        let selectedLabel = displayingShort ? "5h \(shortLabel)" : weeklyLabel
        let statusLabel = compactStatus
            ? (displayingShort ? "5h \(shortLabel)" : "\(menuCopy.weeklyAbbreviation) \(weeklyLabel)")
            : "Codex \(selectedLabel)"

        status.button?.title = " \(statusLabel)\(displayedStale ? " !" : "")"
        status.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let icon = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            let path = NSBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            path.lineWidth = 2
            NSColor.labelColor.withAlphaComponent(0.25).setStroke()
            path.stroke()

            if let displayed = displayed {
                let arc = NSBezierPath()
                arc.lineWidth = 2.5
                arc.appendArc(
                    withCenter: NSPoint(x: 9, y: 9),
                    radius: 7,
                    startAngle: 90,
                    endAngle: 90 - CGFloat(displayed.remaining) * 3.6,
                    clockwise: true
                )
                (displayedStale ? NSColor.secondaryLabelColor : displayed.remaining <= 10 ? NSColor.systemRed : displayed.remaining <= 25 ? NSColor.systemOrange : NSColor.systemGreen).setStroke()
                arc.stroke()
            }
            return true
        }
        status.button?.image = icon
        status.button?.toolTip = menuCopy.statusTooltip(
            weekly: weeklyLabel,
            short: shortLabel,
            shortIncluded: !shortUnavailableForPlan
        )

        weeklyCard.update(title: menuCopy.weeklyLimit, window: weekly, stale: weeklyStale)
        weeklyCard.updateReset(weekly?.reset.map { menuCopy.renewal(date: formatter.string(from: $0), countdown: countdown(to: $0)) } ?? menuCopy.unavailableLimit)
        shortCard.update(title: menuCopy.fiveHourWindow, window: short, stale: shortStale, unavailableForPlan: shortUnavailableForPlan)
        shortCard.updateReset(short?.reset.map { menuCopy.renewal(date: formatter.string(from: $0), countdown: countdown(to: $0)) } ?? (shortUnavailableForPlan ? menuCopy.notIncludedInPlan : menuCopy.unavailableLimit))

        showShortRow.updateTitle(rotateStatus ? menuCopy.startWithFiveHour : menuCopy.showFiveHour)
        showShortRow.toggle.state = showShortInStatus ? .on : .off
        rotateRow.toggle.state = rotateStatus ? .on : .off
        compactRow.toggle.state = compactStatus ? .on : .off
        showShortItem.isHidden = shortUnavailableForPlan
        rotateItem.isHidden = shortUnavailableForPlan
        let updatedText = updated.map { menuCopy.updated(date: formatter.string(from: $0)) } ?? ""
        updatedRow.update(text: updatedText)
        updatedItem.title = updatedText.isEmpty ? menuCopy.updatedPrefix : updatedText
        updatedItem.isHidden = updated == nil
        let errorText = errorMessage.map { menuCopy.warning($0) } ?? ""
        errorRow.update(text: errorText)
        errorItem.title = menuCopy.warningPrefix
        errorItem.isHidden = errorMessage == nil
        refreshItem.title = loading ? menuCopy.refreshing : menuCopy.refresh
        refreshItem.isEnabled = !loading
    }

    @objc private func toggleShortStatusFromSwitch(_ sender: GreenSwitch) {
        showShortInStatus = sender.state == .on
        UserDefaults.standard.set(showShortInStatus, forKey: preferenceShowShort)
        if rotateStatus {
            rotatingShort = showShortInStatus
            restartDisplayTimer()
        }
        DispatchQueue.main.async { self.draw() }
    }

    @objc private func toggleRotateStatusFromSwitch(_ sender: GreenSwitch) {
        rotateStatus = sender.state == .on
        UserDefaults.standard.set(rotateStatus, forKey: preferenceRotate)
        rotatingShort = showShortInStatus
        restartDisplayTimer()
        DispatchQueue.main.async { self.draw() }
    }

    @objc private func toggleCompactStatusFromSwitch(_ sender: GreenSwitch) {
        compactStatus = sender.state == .on
        UserDefaults.standard.set(compactStatus, forKey: preferenceCompact)
        DispatchQueue.main.async { self.draw() }
    }

    @objc private func redraw() {
        if rotateStatus && shortLimitAvailable != false { rotatingShort.toggle() }
        draw()
    }

    @objc private func refresh() {
        guard !loading else { return }
        loading = true
        draw()

        DispatchQueue.global(qos: .utility).async {
            let fetched: [String: Any]?
            let message: String?
            do {
                fetched = try readLimits()
                message = nil
            } catch {
                fetched = nil
                message = (error as? LocalizedError)?.errorDescription ?? menuCopy.queryFailed
            }

            DispatchQueue.main.async {
                self.loading = false
                self.failed = fetched == nil
                self.errorMessage = message
                if let fetched = fetched {
                    self.result = fetched
                    self.updated = Date()
                    let fetchedBucket = codexLimitBucket(fetched)
                    self.shortLimitAvailable = limitWindow(in: fetchedBucket, durationMinutes: 300) != nil
                }
                self.draw()
            }
        }
    }

    @objc private func openCodex() {
        if let applicationURL = codexApplicationURL() {
            NSWorkspace.shared.open(applicationURL)
        }
    }

    @objc private func hideUntilCodexCloses() {
        let directory = suppressedIndicatorURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? Data("hidden\n".utf8).write(to: suppressedIndicatorURL, options: .atomic)
        NSApplication.shared.terminate(nil)
    }

}

if CommandLine.arguments.contains("--check") {
    assert(Window(["usedPercent": 57.0])?.remaining == 43)
    assert(Window(["usedPercent": 110.0])?.remaining == 0)
    assert(Window([:]) == nil)
    assert(MenuCopy(language: .english).weeklyLimit == "Weekly limit")
    assert(MenuCopy(language: .portugueseBrazil).weeklyLimit == "Limite semanal")
    assert(MenuCopy(language: .english).weeklyAbbreviation == "W")
    assert(MenuCopy(language: .portugueseBrazil).weeklyAbbreviation == "S")

    let checkBucket: [String: Any] = [
        "weekly": ["windowDurationMins": 10080.0, "usedPercent": 10.0],
        "short": ["windowDurationMins": 300.0, "usedPercent": 20.0]
    ]
    assert(limitWindow(in: checkBucket, durationMinutes: 300)?.remaining == 80)
    assert(limitWindow(in: checkBucket, durationMinutes: 1440) == nil)

    let result = try readLimits()
    let bucket = codexLimitBucket(result)
    guard let weekly = limitWindow(in: bucket, durationMinutes: 10080) else {
        fatalError("\(menuCopy.weeklyLimit) \(menuCopy.unavailable)")
    }
    let short = limitWindow(in: bucket, durationMinutes: 300)
    print("\(menuCopy.weeklyLimit): \(weekly.remaining)% \(menuCopy.remaining); reset: \(weekly.reset?.description ?? menuCopy.unavailable)")
    if let short {
        print("\(menuCopy.fiveHourWindow): \(short.remaining)% \(menuCopy.remaining)")
    } else {
        print("\(menuCopy.fiveHourWindow): \(menuCopy.unavailable)")
    }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
