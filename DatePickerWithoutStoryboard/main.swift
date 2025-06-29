//
//  main.swift
//  DatePickerWithoutStoryboard
//
//  Created by Apple on 30.06.2025.
//

import Cocoa

// UIApplicationMain аналог iOS, но здесь NSApplicationMain не нужен
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
