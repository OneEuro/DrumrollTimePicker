import Cocoa

public class DrumrollComponent: NSView {
    private let originalItems: [String]
    private let repeatedItems: [String]
    public let itemHeight: CGFloat
    public let maxAngle: CGFloat
    private let cylinderRadius: CGFloat
    private let cycleHeight: CGFloat

    public var font: NSFont {
        didSet { rebuildLayers() }
    }

    public var textColor: NSColor = .white {
        didSet { updatePositions() }
    }

    public var componentBackgroundColor: NSColor? {
        didSet {
            layer?.backgroundColor = componentBackgroundColor?.cgColor
        }
    }

    public var textCenterOffset: CGFloat {
        itemHeight * 0.5 - (font.ascender + font.descender) * 0.5
    }

    private var scrollOffset: CGFloat = 0 {
        didSet { updatePositions() }
    }

    private var allLayers: [CATextLayer] = []
    private let unitLayer: CATextLayer?
    private var initialSelectionDone = false
    private var pendingItemIndex: Int?

    private var isDragging = false
    private var dragStartPoint: NSPoint = .zero
    private var dragStartOffset: CGFloat = 0
    private var velocity: CGFloat = 0
    private var lastDragPoints: [(Date, CGFloat)] = []
    private var momentumTimer: Timer?
    private var snapTimer: Timer?
    private var pendingSnapTimer: Timer?

    public var isInfiniteScrollEnabled: Bool = true {
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

    public var isScrollDirectionInverted: Bool = false

    public var onSelectedItemChanged: ((String?) -> Void)?

    public var selectedIndex: Int {
        let centerSurface = scrollOffset + bounds.midY
        let idx = Int(round((centerSurface - itemHeight * 0.5) / itemHeight))
        return max(0, min(repeatedItems.count - 1, idx))
    }

    public func selectedItem() -> String? {
        let idx = selectedIndex % originalItems.count
        guard originalItems.indices.contains(idx) else { return nil }
        return originalItems[idx]
    }

    public func selectItem(_ value: String, animated: Bool = true) {
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

    public init(items: [String], unitText: String? = nil,
                itemHeight: CGFloat = 38, maxAngle: CGFloat = .pi / 3,
                font: NSFont = .systemFont(ofSize: 20)) {
        self.originalItems = items
        self.repeatedItems = items.isEmpty ? [] : Array(repeating: items, count: 3).flatMap { $0 }
        self.itemHeight = itemHeight
        self.maxAngle = maxAngle
        self.font = font
        cylinderRadius = (2 * itemHeight) / sin(maxAngle)
        cycleHeight = CGFloat(items.count) * itemHeight

        if let text = unitText {
            let layer = CATextLayer()
            layer.alignmentMode = .left
            layer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            layer.foregroundColor = NSColor.white.cgColor
            layer.font = font
            layer.fontSize = font.pointSize
            layer.string = text
            unitLayer = layer
        } else {
            unitLayer = nil
        }

        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        self.originalItems = []
        self.repeatedItems = []
        self.itemHeight = 38
        self.maxAngle = .pi / 3
        self.font = .systemFont(ofSize: 20)
        cylinderRadius = (2 * 38) / sin(.pi / 3)
        cycleHeight = 0
        unitLayer = nil
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = componentBackgroundColor?.cgColor ?? NSColor.black.cgColor

        for item in repeatedItems {
            let textLayer = CATextLayer()
            textLayer.alignmentMode = .center
            textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            textLayer.foregroundColor = textColor.cgColor
            textLayer.font = font
            textLayer.fontSize = font.pointSize
            textLayer.string = item
            layer?.addSublayer(textLayer)
            allLayers.append(textLayer)
        }

        if let unitLayer {
            layer?.addSublayer(unitLayer)
        }

        updatePositions()
    }

    private func rebuildLayers() {
        for l in allLayers {
            l.removeFromSuperlayer()
        }
        allLayers.removeAll()
        unitLayer?.removeFromSuperlayer()

        for item in repeatedItems {
            let textLayer = CATextLayer()
            textLayer.alignmentMode = .center
            textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            textLayer.foregroundColor = textColor.cgColor
            textLayer.font = font
            textLayer.fontSize = font.pointSize
            textLayer.string = item
            layer?.addSublayer(textLayer)
            allLayers.append(textLayer)
        }

        if let unitLayer {
            layer?.addSublayer(unitLayer)
            unitLayer.font = font
            unitLayer.fontSize = font.pointSize
        }

        updatePositions()
    }

    override public func layout() {
        super.layout()
        layer?.frame = bounds

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

    override public var intrinsicContentSize: NSSize {
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
            layer.foregroundColor = textColor.cgColor
        }

        if let unitLayer {
            unitLayer.font = font
            unitLayer.fontSize = font.pointSize
            unitLayer.bounds = CGRect(x: 0, y: 0, width: 48, height: itemHeight)
            unitLayer.position = CGPoint(x: bounds.width * 0.5 + 42, y: bounds.midY + textCenterOffset)
            unitLayer.zPosition = 0
            unitLayer.isHidden = false
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

    override public func mouseDown(with event: NSEvent) {
        isDragging = true
        let point = convert(event.locationInWindow, from: nil)
        dragStartPoint = point
        dragStartOffset = scrollOffset
        velocity = 0
        lastDragPoints = [(Date(), point.y)]
        cancelAnimations()
    }

    override public func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let point = convert(event.locationInWindow, from: nil)
        let delta = dragStartPoint.y - point.y
        scrollOffset = dragStartOffset + (isScrollDirectionInverted ? -delta : delta)
        if isInfiniteScrollEnabled {
            wrapOffset()
        } else {
            scrollOffset = clampToMiddle(scrollOffset)
        }

        let now = Date()
        lastDragPoints.append((now, point.y))
        if lastDragPoints.count > 10 {
            lastDragPoints.removeFirst()
        }
    }

    override public func mouseUp(with event: NSEvent) {
        isDragging = false

        if lastDragPoints.count >= 2 {
            let count = min(lastDragPoints.count, 4)
            let first = lastDragPoints[lastDragPoints.count - count]
            let last = lastDragPoints.last!
            let dt = last.0.timeIntervalSince(first.0)
            if dt > 0 {
                velocity = (last.1 - first.1) / CGFloat(dt)
                if isScrollDirectionInverted {
                    velocity = -velocity
                }
            }
        }

        if abs(velocity) > 30 {
            startMomentum()
        } else {
            snapToNearest()
        }
    }

    override public func scrollWheel(with event: NSEvent) {
        cancelAnimations()
        if isScrollDirectionInverted {
            scrollOffset += event.scrollingDeltaY
        } else {
            scrollOffset -= event.scrollingDeltaY
        }
        if isInfiniteScrollEnabled {
            wrapOffset()
        } else {
            scrollOffset = clampToMiddle(scrollOffset)
        }

        pendingSnapTimer?.invalidate()
        if event.momentumPhase == .ended || event.phase == .ended {
            snapToNearest()
        } else {
            pendingSnapTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
                self?.snapToNearest()
            }
        }
    }

    // MARK: - Momentum & Snap

    private func cancelAnimations() {
        momentumTimer?.invalidate()
        momentumTimer = nil
        snapTimer?.invalidate()
        snapTimer = nil
        pendingSnapTimer?.invalidate()
        pendingSnapTimer = nil
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
