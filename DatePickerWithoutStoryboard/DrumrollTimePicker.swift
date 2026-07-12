import Cocoa

class PassthroughView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}

class DrumrollTimePicker: NSView {
    private let hourPicker = DrumrollComponent(items: Array(0...23).map { String(format: "%02d", $0) }, unitText: "ч")
    private let minutePicker = DrumrollComponent(items: Array(0...59).map { String(format: "%02d", $0) }, unitText: "мин")
    private let secondPicker = DrumrollComponent(items: Array(0...59).map { String(format: "%02d", $0) }, unitText: "с")
    private let selectionOverlay = PassthroughView()

    var showsSeconds: Bool = false {
        didSet {
            secondPicker.isHidden = !showsSeconds
        }
    }

    var isInfiniteScrollEnabled: Bool = true {
        didSet {
            hourPicker.isInfiniteScrollEnabled = isInfiniteScrollEnabled
            minutePicker.isInfiniteScrollEnabled = isInfiniteScrollEnabled
            secondPicker.isInfiniteScrollEnabled = isInfiniteScrollEnabled
        }
    }

    private var _isScrollDirectionInverted: Bool = false
    var isScrollDirectionInverted: Bool {
        get { _isScrollDirectionInverted }
        set {
            _isScrollDirectionInverted = newValue
            hourPicker.isScrollDirectionInverted = newValue
            minutePicker.isScrollDirectionInverted = newValue
            secondPicker.isScrollDirectionInverted = newValue
        }
    }

    var selectedTime: (hour: Int, minute: Int, second: Int)? {
        guard
            let hourStr = hourPicker.selectedItem(),
            let hour = Int(hourStr),
            let minuteStr = minutePicker.selectedItem(),
            let minute = Int(minuteStr)
        else { return nil }

        let second: Int
        if showsSeconds, let secStr = secondPicker.selectedItem(), let sec = Int(secStr) {
            second = sec
        } else {
            second = 0
        }
        return (hour, minute, second)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
        setupUI()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        wantsLayer = true
        layer?.masksToBounds = false
        setupUI()
    }

    private func setupUI() {
        hourPicker.translatesAutoresizingMaskIntoConstraints = false
        minutePicker.translatesAutoresizingMaskIntoConstraints = false
        secondPicker.translatesAutoresizingMaskIntoConstraints = false

        for v in [hourPicker, minutePicker, secondPicker] as [NSView] {
            addSubview(v)
        }

        selectionOverlay.wantsLayer = true
        selectionOverlay.layer?.backgroundColor = .clear
        addSubview(selectionOverlay, positioned: .above, relativeTo: nil)

        NSLayoutConstraint.activate([
            hourPicker.leadingAnchor.constraint(equalTo: leadingAnchor),
            hourPicker.topAnchor.constraint(equalTo: topAnchor),
            hourPicker.bottomAnchor.constraint(equalTo: bottomAnchor),

            minutePicker.leadingAnchor.constraint(equalTo: hourPicker.trailingAnchor, constant: 8),
            minutePicker.topAnchor.constraint(equalTo: topAnchor),
            minutePicker.bottomAnchor.constraint(equalTo: bottomAnchor),
            minutePicker.widthAnchor.constraint(equalTo: hourPicker.widthAnchor),

            secondPicker.leadingAnchor.constraint(equalTo: minutePicker.trailingAnchor, constant: 8),
            secondPicker.topAnchor.constraint(equalTo: topAnchor),
            secondPicker.bottomAnchor.constraint(equalTo: bottomAnchor),
            secondPicker.widthAnchor.constraint(equalTo: hourPicker.widthAnchor),
            secondPicker.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        let now = Date()
        let calendar = Calendar.current
        hourPicker.selectItem(String(format: "%02d", calendar.component(.hour, from: now)), animated: false)
        minutePicker.selectItem(String(format: "%02d", calendar.component(.minute, from: now)), animated: false)
        secondPicker.selectItem(String(format: "%02d", calendar.component(.second, from: now)), animated: false)

        secondPicker.isHidden = !showsSeconds
    }

    override func layout() {
        super.layout()
        selectionOverlay.frame = bounds
        let centerY = bounds.midY + hourPicker.textCenterOffset
        let bar = CALayer()
        bar.backgroundColor = NSColor.systemIndigo.withAlphaComponent(0.2).cgColor
        bar.cornerRadius = 16
        bar.frame = CGRect(
            x: 4,
            y: centerY - 13,
            width: max(0, bounds.width - 8),
            height: 34
        )
        selectionOverlay.layer?.sublayers = nil
        selectionOverlay.layer?.addSublayer(bar)
    }

}
