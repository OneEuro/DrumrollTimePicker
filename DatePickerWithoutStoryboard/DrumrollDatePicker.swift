//
//  DrumrollDatePicker.swift
//  DatePickerWithoutStoryboard
//
//  Created by Apple on 30.06.2025.
//

import Cocoa

class DrumrollDatePicker: NSView {
    private let dayPicker = DrumrollComponent(items: Array(1...31).map { String($0) })
      private let monthPicker = DrumrollComponent(items: DateFormatter().monthSymbols ?? [])
      private let yearPicker = DrumrollComponent(items: Array(1900...2100).map { String($0) })

      override init(frame frameRect: NSRect) {
          super.init(frame: frameRect)
          setupUI()
      }

      required init?(coder decoder: NSCoder) {
          super.init(coder: decoder)
          setupUI()
      }

      private func setupUI() {
          let stack = NSStackView()
          stack.orientation = .horizontal
          stack.spacing = 10
          stack.alignment = .centerY
          stack.distribution = .fillEqually
          stack.translatesAutoresizingMaskIntoConstraints = false

          stack.addArrangedSubview(dayPicker)
          stack.addArrangedSubview(monthPicker)
          stack.addArrangedSubview(yearPicker)

          self.addSubview(stack)

          NSLayoutConstraint.activate([
              stack.leadingAnchor.constraint(equalTo: self.leadingAnchor),
              stack.trailingAnchor.constraint(equalTo: self.trailingAnchor),
              stack.topAnchor.constraint(equalTo: self.topAnchor),
              stack.bottomAnchor.constraint(equalTo: self.bottomAnchor)
          ])

          // Overlay highlight
          let highlight = NSView()
          highlight.wantsLayer = true
          highlight.layer?.borderColor = NSColor.systemBlue.cgColor
          highlight.layer?.borderWidth = 2.0
          highlight.translatesAutoresizingMaskIntoConstraints = false
          self.addSubview(highlight)

          NSLayoutConstraint.activate([
              highlight.centerYAnchor.constraint(equalTo: self.centerYAnchor),
              highlight.leadingAnchor.constraint(equalTo: self.leadingAnchor),
              highlight.trailingAnchor.constraint(equalTo: self.trailingAnchor),
              highlight.heightAnchor.constraint(equalToConstant: 30)
          ])

          // Set default selection to today
          let now = Date()
          let calendar = Calendar.current
          dayPicker.selectItem(String(calendar.component(.day, from: now)), animated: false)
          monthPicker.selectItem(DateFormatter().monthSymbols[calendar.component(.month, from: now) - 1], animated: false)
          yearPicker.selectItem(String(calendar.component(.year, from: now)), animated: false)
      }

      func selectedDate() -> Date? {
          guard
              let dayStr = dayPicker.selectedItem(),
              let day = Int(dayStr),
              let monthStr = monthPicker.selectedItem(),
              let month = DateFormatter().monthSymbols.firstIndex(of: monthStr).map({ $0 + 1 }),
              let yearStr = yearPicker.selectedItem(),
              let year = Int(yearStr)
          else { return nil }

          var components = DateComponents()
          components.day = day
          components.month = month
          components.year = year

          return Calendar.current.date(from: components)
      }
}
