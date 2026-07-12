//
//  AppDelegate.swift
//  DatePickerWithoutStoryboard
//
//  Created by Apple on 30.06.2025.
//

import Cocoa

//@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let picker = DrumrollTimePicker()
    var infiniteScrollToggle: NSButton!

    func applicationDidFinishLaunching(_ notification: Notification) {
           window = NSWindow(
               contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
               styleMask: [.titled, .closable, .resizable],
               backing: .buffered,
               defer: false
           )
           window.center()
           window.title = "Drumroll Time Picker"
           window.makeKeyAndOrderFront(nil)

           picker.showsSeconds = true
           picker.translatesAutoresizingMaskIntoConstraints = false

           infiniteScrollToggle = NSButton(checkboxWithTitle: "Infinite Scroll", target: self, action: #selector(toggleInfiniteScroll(_:)))
           infiniteScrollToggle.state = .on
           infiniteScrollToggle.translatesAutoresizingMaskIntoConstraints = false

           guard let contentView = window.contentView else { return }
           contentView.addSubview(picker)
           contentView.addSubview(infiniteScrollToggle)

           NSLayoutConstraint.activate([
               picker.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
               picker.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
               picker.widthAnchor.constraint(equalToConstant: 300),
               picker.heightAnchor.constraint(equalToConstant: 190),

               infiniteScrollToggle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
               infiniteScrollToggle.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 8),
           ])
       }

    @objc private func toggleInfiniteScroll(_ sender: NSButton) {
        picker.isInfiniteScrollEnabled = sender.state == .on
    }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }
}

