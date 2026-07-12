import Cocoa

class DrumrollTimePicker: NSView {
    private let hourPicker = DrumrollComponent(items: Array(0...23).map { String(format: "%02d", $0) }, unitText: "ч")
    private let minutePicker = DrumrollComponent(items: Array(0...59).map { String(format: "%02d", $0) }, unitText: "мин")
    private let secondPicker = DrumrollComponent(items: Array(0...59).map { String(format: "%02d", $0) }, unitText: "с")

    var showsSeconds: Bool = false {
        didSet {
            secondPicker.isHidden = !showsSeconds
            secondEqualWidthConstraint?.isActive = showsSeconds
        }
    }

    var isInfiniteScrollEnabled: Bool = true {
        didSet {
            hourPicker.isInfiniteScrollEnabled = isInfiniteScrollEnabled
            minutePicker.isInfiniteScrollEnabled = isInfiniteScrollEnabled
            secondPicker.isInfiniteScrollEnabled = isInfiniteScrollEnabled
        }
    }

    private var secondEqualWidthConstraint: NSLayoutConstraint?

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
        setupUI()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setupUI()
    }

    private func setupUI() {
        hourPicker.translatesAutoresizingMaskIntoConstraints = false
        minutePicker.translatesAutoresizingMaskIntoConstraints = false
        secondPicker.translatesAutoresizingMaskIntoConstraints = false

        for v in [hourPicker, minutePicker, secondPicker] as [NSView] {
            addSubview(v)
        }

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
            secondPicker.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
        ])

        let equalWidth = minutePicker.widthAnchor.constraint(equalTo: secondPicker.widthAnchor)
        secondEqualWidthConstraint = equalWidth

        let now = Date()
        let calendar = Calendar.current
        hourPicker.selectItem(String(format: "%02d", calendar.component(.hour, from: now)), animated: false)
        minutePicker.selectItem(String(format: "%02d", calendar.component(.minute, from: now)), animated: false)
        secondPicker.selectItem(String(format: "%02d", calendar.component(.second, from: now)), animated: false)

        secondPicker.isHidden = !showsSeconds
    }
}
