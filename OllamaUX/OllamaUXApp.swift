//
//  OllamaUXApp.swift
//  OllamaUX
//
//  Created by Jack Rogers on 5/5/25.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct OllamaUIApp: App {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    updateAppearance()
                }
                .onChange(of: isDarkMode) {
                    updateAppearance()
                }
        }
        
        Settings {
            SettingsView()
        }
        
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "OllamaUX")") {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
            }
        }
    }
    
    func updateAppearance() {
        NSApp.appearance = isDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
    }
}
