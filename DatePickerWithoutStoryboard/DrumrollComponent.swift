//
//  DrumrollComponent.swift
//  DatePickerWithoutStoryboard
//
//  Created by Apple on 30.06.2025.
//

import Cocoa

class DrumrollComponent: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private let scrollView = NSScrollView()
      private let tableView = NSTableView()
      private let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("column"))
      private let items: [String]
      private var selectedRow: Int = 0

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
          scrollView.translatesAutoresizingMaskIntoConstraints = false
          scrollView.hasVerticalScroller = false
          scrollView.borderType = .noBorder
          scrollView.drawsBackground = false

          tableView.headerView = nil
          tableView.addTableColumn(column)
          tableView.delegate = self
          tableView.dataSource = self
          tableView.intercellSpacing = NSSize(width: 0, height: 5)
          tableView.selectionHighlightStyle = .none
          tableView.rowHeight = 30

          scrollView.documentView = tableView
          addSubview(scrollView)

          scrollView.contentView.postsBoundsChangedNotifications = true
          NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange), name: NSView.boundsDidChangeNotification, object: scrollView.contentView)

          tableView.reloadData()
      }

      override func layout() {
          super.layout()
          scrollView.frame = bounds
          column.width = bounds.width
      }

      func numberOfRows(in tableView: NSTableView) -> Int {
          return items.count
      }

      func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
          let label = NSTextField(labelWithString: items[row])
          label.alignment = .center
          label.font = NSFont.systemFont(ofSize: 18)
          return label
      }

      func selectItem(_ value: String, animated: Bool = true) {
          if let index = items.firstIndex(of: value) {
              selectedRow = index
              scrollToRow(index, animated: animated)
          }
      }

      func selectedItem() -> String? {
          return items[safe: selectedRow]
      }

      private func scrollToRow(_ row: Int, animated: Bool) {
          let rowHeight = tableView.rowHeight + tableView.intercellSpacing.height
          let y = CGFloat(row) * rowHeight - scrollView.contentView.bounds.height / 2 + rowHeight / 2
          let point = NSPoint(x: 0, y: y)

          if animated {
              NSAnimationContext.runAnimationGroup({ context in
                  context.duration = 0.3
                  scrollView.contentView.animator().setBoundsOrigin(point)
              }, completionHandler: nil)
          } else {
              scrollView.contentView.setBoundsOrigin(point)
          }
      }

      @objc private func boundsDidChange() {
          let center = scrollView.contentView.bounds.midY
          let rowHeight = tableView.rowHeight + tableView.intercellSpacing.height
          let centerRow = Int((center + scrollView.contentView.bounds.origin.y) / rowHeight)
          if centerRow != selectedRow && centerRow < items.count && centerRow >= 0 {
              selectedRow = centerRow
          }
      }
  }

  extension Array {
      subscript(safe index: Int) -> Element? {
          return indices.contains(index) ? self[index] : nil
      }
}
