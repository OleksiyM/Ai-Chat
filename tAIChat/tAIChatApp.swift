//
//  tAIChatApp.swift
//  tAIChat
//
//  Created by Alex Malovanyy on 08.02.2025.
//

import SwiftUI

@main
struct tAIChatApp: App {
    @StateObject private var viewModel = ChatViewModel(settings: AppSettings.default)
    @State private var showSettings = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .sheet(isPresented: $showSettings) {
                    SettingsView(settings: try! JSONDecoder().decode(AppSettings.self, from: UserDefaults.standard.data(forKey: "settings") ?? Data())) { newSettings in
                        if let encoded = try? JSONEncoder().encode(newSettings) {
                            UserDefaults.standard.set(encoded, forKey: "settings")
                            viewModel.updateSettings(newSettings)
                        }
                    }
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Settings...") {
                    showSettings.toggle()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        MenuBarExtra("Settings", systemImage: "gear") {
            Button("Settings") {
                showSettings.toggle()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
