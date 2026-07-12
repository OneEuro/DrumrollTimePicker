import Cocoa

class DrumrollComponent: NSView {
    private let items: [String]
    private let itemHeight: CGFloat = 38
    private let visibleRowCount = 5

    private var scrollOffset: CGFloat = 0 {
        didSet { updateRows() }
    }

    private var rowLayers: [CATextLayer] = []
    private let selectionLayer = CAShapeLayer()
    private let gradientOverlay = CAGradientLayer()
    private var pendingItemIndex: Int?

    private var isDragging = false
    private var dragStartPoint: NSPoint = .zero
    private var dragStartOffset: CGFloat = 0
    private var velocity: CGFloat = 0
    private var lastDragPoints: [(Date, CGFloat)] = []
    private var momentumTimer: Timer?
    private var snapTimer: Timer?

    var onSelectedItemChanged: ((String?) -> Void)?

    var selectedIndex: Int {
        let centerContentY = scrollOffset + bounds.midY
        let idx = Int(round((centerContentY - itemHeight * 0.5) / itemHeight))
        return max(0, min(items.count - 1, idx))
    }

    func selectedItem() -> String? {
        guard items.indices.contains(selectedIndex) else { return nil }
        return items[selectedIndex]
    }

    func selectItem(_ value: String, animated: Bool = true) {
        guard let index = items.firstIndex(of: value) else { return }
        guard bounds.width > 0, bounds.height > 0 else {
            pendingItemIndex = index
            return
        }
        let targetOffset = CGFloat(index) * itemHeight + itemHeight * 0.5 - bounds.midY
        cancelAnimations()
        if animated {
            animateToOffset(targetOffset)
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            scrollOffset = clampOffset(targetOffset)
            CATransaction.commit()
            onSelectedItemChanged?(selectedItem())
        }
    }

    init(items: [String]) {
        self.items = items
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        self.items = []
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true

        selectionLayer.fillColor = NSColor.systemBlue.withAlphaComponent(0.12).cgColor
        selectionLayer.cornerRadius = 8
        layer?.addSublayer(selectionLayer)

        for _ in 0..<visibleRowCount {
            let textLayer = CATextLayer()
            textLayer.alignmentMode = .center
            textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            textLayer.foregroundColor = NSColor.labelColor.cgColor
            textLayer.font = NSFont.systemFont(ofSize: 18)
            textLayer.fontSize = 18
            layer?.addSublayer(textLayer)
            rowLayers.append(textLayer)
        }

        gradientOverlay.colors = [
            NSColor.windowBackgroundColor.cgColor,
            NSColor.clear.cgColor,
            NSColor.clear.cgColor,
            NSColor.windowBackgroundColor.cgColor,
        ]
        gradientOverlay.locations = [0, 0.25, 0.75, 1]
        gradientOverlay.startPoint = CGPoint(x: 0.5, y: 0)
        gradientOverlay.endPoint = CGPoint(x: 0.5, y: 1)
        layer?.addSublayer(gradientOverlay)

        updateRows()
    }

    override func layout() {
        super.layout()
        layer?.frame = bounds
        selectionLayer.frame = CGRect(
            x: 4,
            y: bounds.midY - itemHeight * 0.5,
            width: max(0, bounds.width - 8),
            height: itemHeight
        )
        gradientOverlay.frame = bounds

        if let pending = pendingItemIndex {
            pendingItemIndex = nil
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            scrollOffset = clampOffset(CGFloat(pending) * itemHeight + itemHeight * 0.5 - bounds.midY)
            CATransaction.commit()
        } else {
            updateRows()
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: itemHeight * CGFloat(visibleRowCount))
    }

    private func updateRows() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let centerContentY = scrollOffset + bounds.midY
        let halfVisible = visibleRowCount / 2
        let centerIdx = Int(round(centerContentY / itemHeight))

        let startIdx = centerIdx - halfVisible
        let endIdx = centerIdx + halfVisible

        for i in 0..<visibleRowCount {
            let itemIdx = startIdx + i
            let layer = rowLayers[i]

            if itemIdx >= 0, itemIdx < items.count {
                layer.isHidden = false
                layer.string = items[itemIdx]

                let viewY = CGFloat(itemIdx) * itemHeight - scrollOffset
                layer.frame = CGRect(
                    x: 0,
                    y: viewY,
                    width: bounds.width,
                    height: itemHeight
                )

                let distance = abs(viewY + itemHeight * 0.5 - bounds.midY) / (bounds.height * 0.5)
                let clampedDistance = min(distance, 1.0)

                var transform = CATransform3DIdentity
                transform.m34 = -1.0 / 500.0
                let angle = clampedDistance * CGFloat.pi / 7
                let sign: CGFloat = (viewY + itemHeight * 0.5 < bounds.midY) ? 1.0 : -1.0
                transform = CATransform3DRotate(transform, angle * sign, 1, 0, 0)

                let scale = max(0.65, 1.0 - clampedDistance * 0.4)
                transform = CATransform3DScale(transform, scale, scale, 1)

                layer.transform = transform
                layer.opacity = Float(max(0.2, 1.0 - clampedDistance * 0.85))
                layer.fontSize = max(12, 18 - clampedDistance * 8)
                layer.zPosition = (itemIdx == selectedIndex) ? 1 : 0
            } else {
                layer.isHidden = true
            }
        }

        CATransaction.commit()
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        isDragging = true
        let point = convert(event.locationInWindow, from: nil)
        dragStartPoint = point
        dragStartOffset = scrollOffset
        velocity = 0
        lastDragPoints = [(Date(), point.y)]
        cancelAnimations()
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let point = convert(event.locationInWindow, from: nil)
        let delta = dragStartPoint.y - point.y
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        scrollOffset = clampOffset(dragStartOffset + delta)
        CATransaction.commit()

        let now = Date()
        lastDragPoints.append((now, point.y))
        if lastDragPoints.count > 10 {
            lastDragPoints.removeFirst()
        }
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false

        if lastDragPoints.count >= 2 {
            let first = lastDragPoints.first!
            let last = lastDragPoints.last!
            let dt = last.0.timeIntervalSince(first.0)
            if dt > 0 {
                velocity = (last.1 - first.1) / CGFloat(dt)
            }
        }

        if abs(velocity) > 50 {
            startMomentum()
        } else {
            snapToNearest()
        }
    }

    override func scrollWheel(with event: NSEvent) {
        cancelAnimations()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        scrollOffset = clampOffset(scrollOffset - event.scrollingDeltaY)
        CATransaction.commit()

        if event.momentumPhase == .ended || event.phase == .ended {
            snapToNearest()
        }
    }

    // MARK: - Momentum & Snap

    private func cancelAnimations() {
        momentumTimer?.invalidate()
        momentumTimer = nil
        snapTimer?.invalidate()
        snapTimer = nil
    }

    private func startMomentum() {
        cancelAnimations()
        let decay: CGFloat = 0.93
        let minVelocity: CGFloat = 5

        momentumTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.scrollOffset = self.clampOffset(self.scrollOffset + self.velocity * (1 / 60))
            CATransaction.commit()
            self.velocity *= decay

            if abs(self.velocity) < minVelocity {
                timer.invalidate()
                self.snapToNearest()
            }
        }
    }

    private func snapToNearest() {
        cancelAnimations()

        let targetIdx = selectedIndex
        let targetOffset = CGFloat(targetIdx) * itemHeight + itemHeight * 0.5 - bounds.midY
        let startOffset = scrollOffset
        let distance = targetOffset - startOffset

        guard abs(distance) > 0.5 else {
            onSelectedItemChanged?(selectedItem())
            return
        }

        let duration: TimeInterval = min(0.25, abs(Double(distance)) / 600)
        let startTime = CACurrentMediaTime()

        snapTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(1, elapsed / duration)
            let eased = easeOutCubic(progress)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.scrollOffset = self.clampOffset(startOffset + distance * CGFloat(eased))
            CATransaction.commit()

            if progress >= 1 {
                timer.invalidate()
                self.scrollOffset = self.clampOffset(targetOffset)
                self.onSelectedItemChanged?(self.selectedItem())
            }
        }
    }

    private func animateToOffset(_ targetOffset: CGFloat) {
        cancelAnimations()

        let startOffset = scrollOffset
        let distance = targetOffset - startOffset
        guard abs(distance) > 0.5 else { return }

        let duration: TimeInterval = min(0.3, abs(Double(distance)) / 500)
        let startTime = CACurrentMediaTime()

        snapTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(1, elapsed / duration)
            let eased = easeOutCubic(progress)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.scrollOffset = self.clampOffset(startOffset + distance * CGFloat(eased))
            CATransaction.commit()

            if progress >= 1 {
                timer.invalidate()
                self.scrollOffset = self.clampOffset(targetOffset)
                self.onSelectedItemChanged?(self.selectedItem())
            }
        }
    }

    // MARK: - Helpers

    private func clampOffset(_ offset: CGFloat) -> CGFloat {
        let minOffset = -(bounds.midY - itemHeight * 0.5)
        let maxOffset = CGFloat(items.count - 1) * itemHeight + itemHeight * 0.5 - bounds.midY
        return max(minOffset, min(maxOffset, offset))
    }

    private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        1 - pow(1 - t, 3)
    }
}
