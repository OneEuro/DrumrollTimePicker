import Cocoa

class PassthroughView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}

public class DrumrollTimePicker: NSView {
    private let hourPicker = DrumrollComponent(items: Array(0...23).map { String(format: "%02d", $0) }, unitText: "ч")
    private let minutePicker = DrumrollComponent(items: Array(0...59).map { String(format: "%02d", $0) }, unitText: "мин")
    private let secondPicker = DrumrollComponent(items: Array(0...59).map { String(format: "%02d", $0) }, unitText: "с")
    private let selectionOverlay = PassthroughView()
    private let selectionBar = CALayer()
    private var minuteLeadingConstraint: NSLayoutConstraint?
    private var secondLeadingConstraint: NSLayoutConstraint?

    public var showsSeconds: Bool = false {
        didSet {
            secondPicker.isHidden = !showsSeconds
        }
    }

    public var isInfiniteScrollEnabled: Bool = true {
        didSet {
            hourPicker.isInfiniteScrollEnabled = isInfiniteScrollEnabled
            minutePicker.isInfiniteScrollEnabled = isInfiniteScrollEnabled
            secondPicker.isInfiniteScrollEnabled = isInfiniteScrollEnabled
        }
    }

    private var _isScrollDirectionInverted: Bool = false
    public var isScrollDirectionInverted: Bool {
        get { _isScrollDirectionInverted }
        set {
            _isScrollDirectionInverted = newValue
            hourPicker.isScrollDirectionInverted = newValue
            minutePicker.isScrollDirectionInverted = newValue
            secondPicker.isScrollDirectionInverted = newValue
        }
    }

    public var selectedTime: (hour: Int, minute: Int, second: Int)? {
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

    // MARK: - Customization Properties

    public var textColor: NSColor = .white {
        didSet { applyToAll { $0.textColor = textColor } }
    }

    public var componentBackgroundColor: NSColor? = .black {
        didSet { applyToAll { $0.componentBackgroundColor = componentBackgroundColor } }
    }

    public var font: NSFont = .systemFont(ofSize: 20) {
        didSet { applyToAll { $0.font = font } }
    }

    public var selectionColor: NSColor = NSColor.systemIndigo.withAlphaComponent(0.2) {
        didSet { selectionBar.backgroundColor = selectionColor.cgColor }
    }

    public var itemSpacing: CGFloat = 8 {
        didSet {
            minuteLeadingConstraint?.constant = itemSpacing
            secondLeadingConstraint?.constant = itemSpacing
        }
    }

    private func applyToAll(_ block: (DrumrollComponent) -> Void) {
        block(hourPicker)
        block(minutePicker)
        block(secondPicker)
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
        setupUI()
    }

    public required init?(coder decoder: NSCoder) {
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
        selectionOverlay.layer?.addSublayer(selectionBar)
        addSubview(selectionOverlay, positioned: .above, relativeTo: nil)

        let minuteLeading = minutePicker.leadingAnchor.constraint(equalTo: hourPicker.trailingAnchor, constant: itemSpacing)
        let secondLeading = secondPicker.leadingAnchor.constraint(equalTo: minutePicker.trailingAnchor, constant: itemSpacing)

        minuteLeadingConstraint = minuteLeading
        secondLeadingConstraint = secondLeading

        NSLayoutConstraint.activate([
            hourPicker.leadingAnchor.constraint(equalTo: leadingAnchor),
            hourPicker.topAnchor.constraint(equalTo: topAnchor),
            hourPicker.bottomAnchor.constraint(equalTo: bottomAnchor),

            minuteLeading,
            minutePicker.topAnchor.constraint(equalTo: topAnchor),
            minutePicker.bottomAnchor.constraint(equalTo: bottomAnchor),
            minutePicker.widthAnchor.constraint(equalTo: hourPicker.widthAnchor),

            secondLeading,
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

    public override func layout() {
        super.layout()
        selectionOverlay.frame = bounds
        let centerY = bounds.midY + hourPicker.textCenterOffset
        let barHeight = max(1, hourPicker.itemHeight - 4)
        selectionBar.backgroundColor = selectionColor.cgColor
        selectionBar.cornerRadius = 16
        selectionBar.frame = CGRect(
            x: 4,
            y: centerY - barHeight * 0.5 + 4,
            width: max(0, bounds.width - 8),
            height: barHeight
        )
    }
}
