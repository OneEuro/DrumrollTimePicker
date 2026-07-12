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
    var invertScrollToggle: NSButton!

    func applicationDidFinishLaunching(_ notification: Notification) {
           window = NSWindow(
               contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
               styleMask: [.titled, .closable, .resizable],
               backing: .buffered,
               defer: false
           )
           window.center()
           window.title = "Drumroll Time Picker"
           window.makeKeyAndOrderFront(nil)

           picker.showsSeconds = true
           picker.translatesAutoresizingMaskIntoConstraints = false

           infiniteScrollToggle = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleInfiniteScroll(_:)))
           infiniteScrollToggle.state = .on
           infiniteScrollToggle.translatesAutoresizingMaskIntoConstraints = false
           let infAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white]
           infiniteScrollToggle.attributedTitle = NSAttributedString(string: "Infinite Scroll", attributes: infAttrs)

           invertScrollToggle = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleInvertScroll(_:)))
           invertScrollToggle.state = .on
           invertScrollToggle.translatesAutoresizingMaskIntoConstraints = false
           let invAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white]
           invertScrollToggle.attributedTitle = NSAttributedString(string: "Invert Scroll Direction", attributes: invAttrs)
           picker.isScrollDirectionInverted = true

           guard let contentView = window.contentView else { return }
           contentView.wantsLayer = true
           contentView.layer?.backgroundColor = NSColor.black.cgColor
           contentView.addSubview(picker)
           contentView.addSubview(infiniteScrollToggle)
           contentView.addSubview(invertScrollToggle)

           NSLayoutConstraint.activate([
               picker.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
               picker.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
               picker.widthAnchor.constraint(equalToConstant: 370),
               picker.heightAnchor.constraint(equalToConstant: 190),

               infiniteScrollToggle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
               infiniteScrollToggle.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 8),

               invertScrollToggle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
               invertScrollToggle.topAnchor.constraint(equalTo: infiniteScrollToggle.bottomAnchor, constant: 4),
           ])
       }

    @objc private func toggleInfiniteScroll(_ sender: NSButton) {
        picker.isInfiniteScrollEnabled = sender.state == .on
    }

    @objc private func toggleInvertScroll(_ sender: NSButton) {
        picker.isScrollDirectionInverted = sender.state == .on
    }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }
}

