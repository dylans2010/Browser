//
//  BrowserApp.swift
//  Browser
//
//  Created by timi2506 on 06.12.2024.
//

import SwiftUI

@main
struct BrowserApp: App {
    @StateObject private var aiConfig = AIConfiguration()
    @StateObject private var notesManager = NotesManager()
    @StateObject private var ttsManager = TTSManager()
    @StateObject private var historyManager = HistoryManager()

    var body: some Scene {
        WindowGroup {
            BrowserView()
                .environmentObject(aiConfig)
                .environmentObject(notesManager)
                .environmentObject(ttsManager)
                .environmentObject(historyManager)
        }
#if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(aiConfig)
        }
#endif
    }
}
