//
//  Settings.swift
//  OllamaUX
//
//  Created by Jack Rogers on 5/7/25.
//

import Foundation
import SwiftUI

enum SettingsAnimTab: Hashable {
    case general, advanced, about
}

struct SettingsView: View {
    @State private var selectedTab: SettingsAnimTab = .general
    @Namespace private var animation

    var body: some View {
        VStack {
            VStack {
                Picker("", selection: $selectedTab) {
                    Label("General", systemImage: "gear").tag(SettingsAnimTab.general)
                    Label("Advanced", systemImage: "star").tag(SettingsAnimTab.advanced)
                    Label("About", systemImage: "info.circle").tag(SettingsAnimTab.about)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
            }
            .background(Color.gray.opacity(0.1))

            ZStack {
                if selectedTab == .general {
                    GeneralSettingsView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .matchedGeometryEffect(id: "tab", in: animation)
                } else if selectedTab == .advanced {
                    AdvancedSettingsView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .matchedGeometryEffect(id: "tab", in: animation)
                } else if selectedTab == .about {
                    AboutSettingsView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .matchedGeometryEffect(id: "tab", in: animation)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            .scenePadding()
        }
        .frame(width: 400, height: 475)
    }
}

struct GeneralSettingsView: View {
    private var selectedSettingsTab = SettingsTab.general
    @AppStorage("chatUserColor") private var chatUserColor: Int = 3
    @AppStorage("chatOllamaColor") private var chatOllamaColor: Int = 4
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        Form {
            Section(header: HStack { Text("Appearance"); Spacer(); Image(systemName: "sparkles") }) {
                Section(header: Text("Chat Colors")) {
                    Picker("User Color", selection: $chatUserColor) {
                        Text("Red").tag(1)
                        Text("Orange").tag(2)
                        Text("Yellow").tag(3)
                        Text("Green").tag(4)
                        Text("Blue").tag(5)
                        Text("Purple").tag(6)
                    }
                    
                    Picker("Ollama Color", selection: $chatOllamaColor) {
                        Text("Red").tag(1)
                        Text("Orange").tag(2)
                        Text("Yellow").tag(3)
                        Text("Green").tag(4)
                        Text("Blue").tag(5)
                        Text("Purple").tag(6)
                    }
                }
                
                Section(header: Text("Theme")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
            }
        }
        .formStyle(GroupedFormStyle())
    }
}

struct AdvancedSettingsView: View {
    private var selectedSettingsTab = SettingsTab.advanced
    @AppStorage("showGradients") private var showGradients: Bool = true
    @State private var showGradientsAlert: Bool = false
    @AppStorage("showAnimations") private var showAnimations: Bool = true
    @State private var showAnimationsAlert: Bool = false
    
    var body: some View {
        Form {
            Section(header: HStack { Text("Performance"); Spacer(); Image(systemName: "gauge.with.dots.needle.67percent") }) {
                HStack {
                    Text("Show Mesh Gradients")
                    Image(systemName: "info.circle")
                        .onTapGesture {
                            showGradientsAlert.toggle()
                        }
                    Spacer()
                    Toggle("", isOn: $showGradients)
                }
                HStack {
                    Text("Show Animations")
                    Image(systemName: "info.circle")
                        .onTapGesture {
                            showAnimationsAlert.toggle()
                        }
                    Spacer()
                    Toggle("", isOn: $showAnimations)
                }
            }
        }
        .formStyle(GroupedFormStyle())
        .alert("If your Mac is old, turning off mesh gradients may improve performance as they take lots of memory.", isPresented: $showGradientsAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("If your Mac is old, turning off animations may improve performance. (Later Release)", isPresented: $showAnimationsAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

struct AboutSettingsView: View {
    @StateObject private var ollamaManager = OllamaManager()
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                Image("AppIconEmbed")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .padding(.bottom, -10)
                Text("About OllamaUI")
                    .font(.title)
                    .fontWeight(.bold)
                Text("\(Text("OllamaUI is in no way associated with Ollama.").fontWeight(.semibold)) It is an open source app for displaying Ollama's output in a more user friendly way inside of MacOS.")
                    .multilineTextAlignment(.center)
                    .frame(width: 325)
                
                Divider()
                    .frame(width: 335)
                
                Text("Created by Jack Rogers 2025 | Contact via GitHub")
                Text("GitHub Repo: https://github.com/jacklr6/OllamaUX")
                
                Divider()
                    .frame(width: 335)
                
                Text("OllamaUI Version: \(appVersion) (Build \(buildNumber))")
                Text("Bundle Identifier: \(bundleIdentifier)")
                Text("Architecture: \(arch)")
                Text("Build Date: \(buildDate)")
                HStack {
                    Text("Ollama Connection Status:")
                    Text(ollamaManager.isOllamaRunning ? "Running" : "Stopped")
                        .foregroundColor(ollamaManager.isOllamaRunning ? .green : .red)
                }
            }
            .fontDesign(.rounded)
        }
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
    
    #if DEBUG
    let buildDate = "Debug Build"
    #else
    let buildDate = Bundle.main.infoDictionary?["BuildDate"] as? String ?? "Unknown"
    #endif
    
    #if arch(x86_64)
    let arch = "Intel (x86_64) *how you this old?!*"
    #elseif arch(arm64)
    let arch = Text("Apple Silicon \(Image(systemName: "apple.logo")) (arm64)")
    #else
    let arch = "Unknown *hackintosh?!*"
    #endif
}

enum SettingsTab: Int {
    case general
    case advanced
    case about
}

#Preview {
    SettingsView()
}
