import Cocoa

class DrumrollTimePicker: NSView {
    private let hourPicker = DrumrollComponent(items: Array(0...23).map { String(format: "%02d", $0) })
    private let minutePicker = DrumrollComponent(items: Array(0...59).map { String(format: "%02d", $0) })
    private let secondPicker = DrumrollComponent(items: Array(0...59).map { String(format: "%02d", $0) })

    private var hourMinuteSeparator: NSTextField!
    private var minuteSecondSeparator: NSTextField!
    private let hourLabel = NSTextField(labelWithString: "ч")
    private let minuteLabel = NSTextField(labelWithString: "мин")
    private let secondLabel = NSTextField(labelWithString: "с")

    var showsSeconds: Bool = false {
        didSet {
            secondPicker.isHidden = !showsSeconds
            minuteSecondSeparator.isHidden = !showsSeconds
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
        hourMinuteSeparator = makeSeparator()
        minuteSecondSeparator = makeSeparator()

        hourPicker.translatesAutoresizingMaskIntoConstraints = false
        minutePicker.translatesAutoresizingMaskIntoConstraints = false
        secondPicker.translatesAutoresizingMaskIntoConstraints = false
        hourMinuteSeparator.translatesAutoresizingMaskIntoConstraints = false
        minuteSecondSeparator.translatesAutoresizingMaskIntoConstraints = false
        hourLabel.translatesAutoresizingMaskIntoConstraints = false
        minuteLabel.translatesAutoresizingMaskIntoConstraints = false
        secondLabel.translatesAutoresizingMaskIntoConstraints = false

        for v in [hourPicker, hourMinuteSeparator!, minutePicker, minuteSecondSeparator!, secondPicker,
                  hourLabel, minuteLabel, secondLabel] as [NSView] {
            addSubview(v)
        }

        configureUnitLabel(hourLabel)
        configureUnitLabel(minuteLabel)
        configureUnitLabel(secondLabel)

        NSLayoutConstraint.activate([
            hourPicker.leadingAnchor.constraint(equalTo: leadingAnchor),
            hourPicker.topAnchor.constraint(equalTo: topAnchor),
            hourPicker.bottomAnchor.constraint(equalTo: bottomAnchor),

            hourLabel.leadingAnchor.constraint(equalTo: hourPicker.trailingAnchor, constant: 4),
            hourLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            hourMinuteSeparator.leadingAnchor.constraint(equalTo: hourLabel.trailingAnchor, constant: 4),
            hourMinuteSeparator.centerYAnchor.constraint(equalTo: centerYAnchor),
            hourMinuteSeparator.widthAnchor.constraint(equalToConstant: 20),

            minutePicker.leadingAnchor.constraint(equalTo: hourMinuteSeparator.trailingAnchor, constant: 2),
            minutePicker.topAnchor.constraint(equalTo: topAnchor),
            minutePicker.bottomAnchor.constraint(equalTo: bottomAnchor),
            minutePicker.widthAnchor.constraint(equalTo: hourPicker.widthAnchor),

            minuteLabel.leadingAnchor.constraint(equalTo: minutePicker.trailingAnchor, constant: 4),
            minuteLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            minuteSecondSeparator.leadingAnchor.constraint(equalTo: minuteLabel.trailingAnchor, constant: 4),
            minuteSecondSeparator.centerYAnchor.constraint(equalTo: centerYAnchor),
            minuteSecondSeparator.widthAnchor.constraint(equalToConstant: 20),

            secondPicker.leadingAnchor.constraint(equalTo: minuteSecondSeparator.trailingAnchor, constant: 2),
            secondPicker.topAnchor.constraint(equalTo: topAnchor),
            secondPicker.bottomAnchor.constraint(equalTo: bottomAnchor),

            secondLabel.leadingAnchor.constraint(equalTo: secondPicker.trailingAnchor, constant: 4),
            secondLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            secondLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        let equalWidth = minutePicker.widthAnchor.constraint(equalTo: secondPicker.widthAnchor)
        secondEqualWidthConstraint = equalWidth

        let now = Date()
        let calendar = Calendar.current
        hourPicker.selectItem(String(format: "%02d", calendar.component(.hour, from: now)), animated: false)
        minutePicker.selectItem(String(format: "%02d", calendar.component(.minute, from: now)), animated: false)
        secondPicker.selectItem(String(format: "%02d", calendar.component(.second, from: now)), animated: false)

        secondPicker.isHidden = !showsSeconds
        minuteSecondSeparator.isHidden = !showsSeconds
    }

    private func configureUnitLabel(_ label: NSTextField) {
        label.font = NSFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.alignment = .left
    }

    private func makeSeparator() -> NSTextField {
        let label = NSTextField(labelWithString: ":")
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        return label
    }
}
