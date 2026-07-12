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

    func applicationDidFinishLaunching(_ notification: Notification) {
           window = NSWindow(
               contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
               styleMask: [.titled, .closable, .resizable],
               backing: .buffered,
               defer: false
           )
           window.center()
           window.title = "Drumroll Time Picker"
           window.makeKeyAndOrderFront(nil)

           let picker = DrumrollTimePicker()
           picker.showsSeconds = true
           picker.translatesAutoresizingMaskIntoConstraints = false
           window.contentView?.addSubview(picker)

           guard let contentView = window.contentView else { return }
           NSLayoutConstraint.activate([
               picker.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
               picker.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
               picker.widthAnchor.constraint(equalToConstant: 300),
               picker.heightAnchor.constraint(equalToConstant: 190),
           ])
       }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }
}

