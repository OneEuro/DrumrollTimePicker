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
               contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
               styleMask: [.titled, .closable, .resizable],
               backing: .buffered,
               defer: false
           )
           window.center()
           window.title = "Drumroll Date Picker"
           window.makeKeyAndOrderFront(nil)

           let picker = DrumrollDatePicker(frame: NSRect(x: 50, y: 100, width: 300, height: 100))
           window.contentView?.addSubview(picker)
       }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }
}

