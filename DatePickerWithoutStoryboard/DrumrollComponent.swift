import Cocoa

class DrumrollComponent: NSView {
    private let originalItems: [String]
    private let repeatedItems: [String]
    private let itemHeight: CGFloat = 38
    private let baseFontSize: CGFloat = 20
    private let maxAngle: CGFloat = .pi / 4
    private let textCenterOffset: CGFloat
    private let cylinderRadius: CGFloat
    private let cycleHeight: CGFloat

    private var scrollOffset: CGFloat = 0 {
        didSet { updatePositions() }
    }

    private var allLayers: [CATextLayer] = []
    private var initialSelectionDone = false
    private let selectionLayer = CAShapeLayer()
    private var pendingItemIndex: Int?

    private var isDragging = false
    private var dragStartPoint: NSPoint = .zero
    private var dragStartOffset: CGFloat = 0
    private var velocity: CGFloat = 0
    private var lastDragPoints: [(Date, CGFloat)] = []
    private var momentumTimer: Timer?
    private var snapTimer: Timer?

    var isInfiniteScrollEnabled: Bool = true {
        didSet {
            guard bounds.width > 0, bounds.height > 0 else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if isInfiniteScrollEnabled {
                wrapOffset()
            } else {
                scrollOffset = clampToMiddle(scrollOffset)
            }
            CATransaction.commit()
        }
    }

    var onSelectedItemChanged: ((String?) -> Void)?

    var selectedIndex: Int {
        let centerSurface = scrollOffset + bounds.midY
        let idx = Int(round((centerSurface - itemHeight * 0.5) / itemHeight))
        return max(0, min(repeatedItems.count - 1, idx))
    }

    func selectedItem() -> String? {
        let idx = selectedIndex % originalItems.count
        guard originalItems.indices.contains(idx) else { return nil }
        return originalItems[idx]
    }

    func selectItem(_ value: String, animated: Bool = true) {
        guard let originalIndex = originalItems.firstIndex(of: value) else { return }
        let index = originalIndex + originalItems.count
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
        self.originalItems = items
        self.repeatedItems = items.isEmpty ? [] : Array(repeating: items, count: 3).flatMap { $0 }
        let font = NSFont.systemFont(ofSize: 20)
        textCenterOffset = itemHeight * 0.5 - (font.ascender + font.descender) * 0.5
        cylinderRadius = (CGFloat(2) * 38) / sin(maxAngle)
        cycleHeight = CGFloat(items.count) * 38
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        self.originalItems = []
        self.repeatedItems = []
        let font = NSFont.systemFont(ofSize: 20)
        textCenterOffset = itemHeight * 0.5 - (font.ascender + font.descender) * 0.5
        cylinderRadius = (CGFloat(2) * 38) / sin(maxAngle)
        cycleHeight = 0
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        selectionLayer.fillColor = NSColor.white.withAlphaComponent(0.08).cgColor
        selectionLayer.cornerRadius = 8
        layer?.addSublayer(selectionLayer)

        for item in repeatedItems {
            let textLayer = CATextLayer()
            textLayer.alignmentMode = .center
            textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            textLayer.foregroundColor = NSColor.white.cgColor
            textLayer.font = NSFont.systemFont(ofSize: baseFontSize)
            textLayer.fontSize = baseFontSize
            textLayer.string = item
            layer?.addSublayer(textLayer)
            allLayers.append(textLayer)
        }

        updatePositions()
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

        if let pending = pendingItemIndex {
            pendingItemIndex = nil
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            scrollOffset = clampOffset(CGFloat(pending) * itemHeight + itemHeight * 0.5 - bounds.midY)
            CATransaction.commit()
            onSelectedItemChanged?(selectedItem())
        } else if !initialSelectionDone {
            initialSelectionDone = true
            let idx = repeatedItems.count / 2
            scrollOffset = clampOffset(CGFloat(idx) * itemHeight + itemHeight * 0.5 - bounds.midY)
        } else {
            updatePositions()
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: itemHeight * 5)
    }

    private func updatePositions() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let viewCenterY = bounds.midY
        let centerSurface = scrollOffset + viewCenterY

        for (i, layer) in allLayers.enumerated() {
            let itemCenter = CGFloat(i) * itemHeight + itemHeight * 0.5
            let surfaceDist = itemCenter - centerSurface
            let angle = surfaceDist / cylinderRadius

            guard abs(angle) <= maxAngle else {
                layer.isHidden = true
                continue
            }

            layer.isHidden = false

            let projectedY = cylinderRadius * sin(angle)
            let screenCenterY = viewCenterY - projectedY
            let zDepth = cylinderRadius * (1 - cos(angle))

            layer.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: itemHeight)
            layer.position = CGPoint(x: bounds.width * 0.5, y: screenCenterY + textCenterOffset)

            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 500.0
            transform = CATransform3DRotate(transform, angle, 1, 0, 0)

            let combinedScale = min(1.0, 500.0 / (500.0 + zDepth))
            transform = CATransform3DScale(transform, combinedScale, combinedScale, 1)

            layer.transform = transform
            layer.zPosition = -zDepth

            let t = abs(angle) / maxAngle
            layer.opacity = Float(max(0, 1.0 - pow(t, 3)))
            let brightness = max(0.25, 1.0 - pow(t, 3) * 0.75)
            layer.foregroundColor = NSColor(white: brightness, alpha: 1.0).cgColor
        }

        CATransaction.commit()
    }

    // MARK: - Infinite Wrap

    private func wrapOffset() {
        let count = originalItems.count
        guard count > 0, cycleHeight > 0 else { return }
        let rawCenter = scrollOffset + bounds.midY
        var wrapped = rawCenter.truncatingRemainder(dividingBy: cycleHeight)
        if wrapped < 0 { wrapped += cycleHeight }
        let middleStart = CGFloat(count) * itemHeight
        scrollOffset = wrapped + middleStart - bounds.midY
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
        scrollOffset = dragStartOffset + (dragStartPoint.y - point.y)
        if isInfiniteScrollEnabled {
            wrapOffset()
        } else {
            scrollOffset = clampToMiddle(scrollOffset)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updatePositions()
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
        scrollOffset -= event.scrollingDeltaY
        if isInfiniteScrollEnabled {
            wrapOffset()
        } else {
            scrollOffset = clampToMiddle(scrollOffset)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updatePositions()
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
            self.scrollOffset += self.velocity * (1 / 60)
            if self.isInfiniteScrollEnabled {
                self.wrapOffset()
            } else {
                self.scrollOffset = self.clampToMiddle(self.scrollOffset)
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.updatePositions()
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
            self.updatePositions()
            CATransaction.commit()

            if progress >= 1 {
                timer.invalidate()
                self.scrollOffset = self.clampOffset(targetOffset)
                self.updatePositions()
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
            self.updatePositions()
            CATransaction.commit()

            if progress >= 1 {
                timer.invalidate()
                self.scrollOffset = self.clampOffset(targetOffset)
                self.updatePositions()
                self.onSelectedItemChanged?(self.selectedItem())
            }
        }
    }

    // MARK: - Helpers

    private func clampOffset(_ offset: CGFloat) -> CGFloat {
        guard !repeatedItems.isEmpty else { return offset }
        let minOffset = -(bounds.midY - itemHeight * 0.5)
        let maxOffset = CGFloat(repeatedItems.count - 1) * itemHeight + itemHeight * 0.5 - bounds.midY
        return max(minOffset, min(maxOffset, offset))
    }

    private func clampToMiddle(_ offset: CGFloat) -> CGFloat {
        let count = originalItems.count
        guard count > 0 else { return offset }
        let minOffset = CGFloat(count) * itemHeight + itemHeight * 0.5 - bounds.midY
        let maxOffset = CGFloat(count * 2 - 1) * itemHeight + itemHeight * 0.5 - bounds.midY
        return max(minOffset, min(maxOffset, offset))
    }

    private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        1 - pow(1 - t, 3)
    }
}
