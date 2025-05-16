//
//  ContentView.swift
//  OllamaUX
//
//  Created by Jack Rogers on 5/5/25.
//

import SwiftUI

var settingsWindow: NSWindow?

struct ContentView: View {
    @StateObject private var viewModel = OllamaViewModel()
    @StateObject private var ollamaManager = OllamaManager()
    
    @AppStorage("welcomeShown") private var welcomeShown: Bool = false
    @AppStorage("showGradients") private var showGradients: Bool = true
    
    @State private var prompt: String = ""
    @State private var selectedModel: String = "llama3.2:latest"
    @State private var planeAnimationState: PlaneAnimation = .initial
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = "Ollama Status"
    @State private var alertMessage: String = ""
    @State private var isStartingOllama: Bool = false
    @State private var hoverOverButtonScale: Double = 1
    @State private var hoverOverButtonGradient: Bool = false
    @State private var isSettingsPresented = false
    @State private var showNewUserView: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                HStack {
                    Text("Ollama Status:")
                    if isStartingOllama {
                        Text("Starting...")
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                    } else {
                        Text(ollamaManager.isOllamaRunning ? "Running" : "Stopped")
                            .foregroundColor(ollamaManager.isOllamaRunning ? .green : .red)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                
                Text("Ollama UI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack {
                    Spacer()
                    Button("Check Ollama") {
                        ollamaManager.checkOllamaStatus()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if !ollamaManager.isOllamaRunning {
                                showingAlert = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                    showingAlert = false
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isStartingOllama)
                }
            }
            
            HStack {
                Picker("Model:", selection: $selectedModel) {
                    ForEach(viewModel.availableModels, id: \.self) { model in
                        Text(model)
                    }
                }
                .frame(width: 200)
                
                Spacer()
                
                Button("Refresh Models") {
                    Task {
                        await viewModel.fetchAvailableModels()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            ZStack {
                VStack {
                    Image(systemName: ollamaManager.isOllamaRunning ? "bubble.left.and.text.bubble.right" : "bubble.left.and.bubble.right")
                        .font(.system(size: 46))
                        .padding(2)
                        .contentTransition(.symbolEffect(.replace))
                    Text(ollamaManager.isOllamaRunning ? "Ask \(Text("Ollama").fontWeight(.semibold)) a Question to Start Chatting!" : "Click 'Check \(Text("Ollama").fontWeight(.semibold))' to Start Chatting!")
                        .multilineTextAlignment(.center)
                        .frame(width: 175)
                        .animation(.easeInOut(duration: 0.3), value: ollamaManager.isOllamaRunning)
                        .transition(.blurReplace)
                }
                .foregroundColor(Color.gray)
                .animation(.easeInOut(duration: 0.3), value: viewModel.conversation.count)
                .opacity(viewModel.conversation.isEmpty ? 1 : 0)
                
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading) {
                            ForEach(viewModel.conversation, id: \.id) { message in
                                MessageView(message: message)
                            }
                            
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .animation(.easeInOut(duration: 0.3), value: viewModel.conversation.count)
                        .padding()
                        .onChange(of: viewModel.conversation.count) {
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color.gray.opacity(viewModel.conversation.isEmpty ? 0.0 : 0.1))
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.05),
                            .init(color: .black, location: 0.95),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                VStack {
                    Spacer()
                    VStack {
                        HStack {
                            Image(systemName: "network.slash")
                                .font(.system(size: 22))
                            Text("No Connection")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.bottom, 1)
                        Text("Can't connect to Ollama! Open Ollama on your Mac, then try again.")
                    }
                    .padding(.horizontal, 5)
                    .multilineTextAlignment(.center)
                    .frame(width: 240, height: 82)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(LinearGradient(gradient: Gradient(colors: [.green, .blue]),startPoint: .topLeading,endPoint: .bottomTrailing), lineWidth: 3)
                    )
                }
                .scaleEffect(showingAlert ? 1 : 0)
                .opacity(showingAlert ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1), value: showingAlert)
            }
            
            HStack {
                TextField("Ask Ollama...", text: $prompt)
                    .frame(height: 38)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 10)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                    .disabled(viewModel.isLoading)
                    .submitLabel(.send)
                    .onSubmit {
                        if !prompt.isEmpty && !viewModel.isLoading {
                            sendTextPrompt()
                        }
                    }
                
                Button(action: {
                    sendTextPrompt()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                            .frame(width: 62, height: 38)
                            .overlay(
                                Group {
                                    if hoverOverButtonGradient && showGradients {
                                        ButtonMeshGradient()
                                            .mask(RoundedRectangle(cornerRadius: 8))
                                            .transition(.opacity)
                                    }
                                }
                            )
                            .animation(.easeInOut(duration: 0.2), value: hoverOverButtonGradient)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(3)
                                .transition(.blurReplace)
                                .id("progress")
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 24))
                                .padding(3)
                                .scaleEffect(planeAnimationState.scale)
                                .scaleEffect(hoverOverButtonScale)
                                .offset(x: planeAnimationState.xOffset, y: planeAnimationState.yOffset)
                                .animation(.easeInOut(duration: 0.2), value: planeAnimationState)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .frame(width: 48, height: 38)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                }
                .cornerRadius(8)
                .onHover { hover in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoverOverButtonScale = hover ? 1.15 : 1.0
                        hoverOverButtonGradient = hover
                    }
                }
                .disabled(prompt.isEmpty || viewModel.isLoading || !ollamaManager.isOllamaRunning)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(minWidth: 475, minHeight: 500)
        .onAppear {
            if welcomeShown == false {
                showNewUserView.toggle()
                welcomeShown = true
            }
            ollamaManager.checkOllamaStatus()
            Task {
                await viewModel.fetchAvailableModels()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    openSettingsWindow {
                        SettingsView()
                    }
                }){
                   Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showNewUserView) {
            NewUserView()
        }
    }
    
    func openSettingsWindow<Content: View>(@ViewBuilder content: () -> Content) {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: content())

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 475),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.contentView = hostingController.view
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
            settingsWindow = nil
        }
    }
    
    func sendTextPrompt() {
        withAnimation(.easeOut(duration: 0.2)) {
            planeAnimationState = .up
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.15)) {
                planeAnimationState = .down
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            Task {
                await viewModel.sendPrompt(prompt: prompt, model: selectedModel)
                prompt = ""
                planeAnimationState = .initial
            }
        }
    }
    
    private func refreshModels() {
        if ollamaManager.isOllamaRunning {
            Task {
                await viewModel.fetchAvailableModels()
                if viewModel.availableModels.isEmpty {
                    await MainActor.run {
                        alertTitle = "No Models Found"
                        alertMessage = "No models were found. Please pull a model first using 'ollama pull llama3.2' in Terminal."
                        showingAlert = true
                    }
                }
            }
        } else {
            alertTitle = "Ollama Not Running"
            alertMessage = "Please start Ollama first"
            showingAlert = true
        }
    }
    
    private func sendPrompt() {
        if !prompt.isEmpty && ollamaManager.isOllamaRunning {
            Task {
                await viewModel.sendPrompt(prompt: prompt, model: selectedModel)
                prompt = ""
            }
        }
    }
}

let colorOptions: [Color] = [
    Color.red.opacity(0.2),
    Color.orange.opacity(0.2),
    Color.yellow.opacity(0.2),
    Color.green.opacity(0.2),
    Color.blue.opacity(0.2),
    Color.purple.opacity(0.2)
]

struct MessageView: View {
    @AppStorage("chatUserColor") private var chatUserColor: Int = 3
    @AppStorage("chatOllamaColor") private var chatOllamaColor: Int = 4
    
    var selectedUserColor: Color {
        let userColorIndex: Int = chatUserColor-1
        if userColorIndex >= 0 && userColorIndex < colorOptions.count {
            return colorOptions[userColorIndex]
        } else {
            return .primary
        }
    }
    
    var selectedOllamaColor: Color {
        let ollamaColorIndex: Int = chatOllamaColor-1
        if ollamaColorIndex >= 0 && ollamaColorIndex < colorOptions.count {
            return colorOptions[ollamaColorIndex]
        } else {
            return .primary
        }
    }
    
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.role == .user ? "You:" : "Ollama:")
                .fontWeight(.bold)
            
            Text(message.content)
                .padding(10)
                .background(message.role == .user ? selectedUserColor : selectedOllamaColor)
                .cornerRadius(10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct NewUserView: View {
    @State private var readmeText: String = ""
    @Environment(\.dismiss) private var dismiss

    init() {
        _readmeText = State(initialValue: readReadmeFile(named: "READme"))
    }
    
    var body: some View {
        ScrollView {
            Image("AppIconEmbed")
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.bottom, -10)
            Text(.init(readmeText))
                .font(.body)
                .padding()
                .font(.system(.body, design: .monospaced))
        }
        .frame(width: 500, height: 350)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Dismiss") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Refresh") {
                    readmeText = readReadmeFile(named: "READme")
                }
                .opacity(readmeText.isEmpty ? 1 : 0)
            }
        }
    }
    
    func readReadmeFile(named name: String, withExtension ext: String = "md") -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let contents = try? String(contentsOf: url) else {
            return "Failed to load README."
        }
        return contents
    }
}

struct GenerateRequest: Codable {
    let model: String
    let prompt: String
}

struct StreamResponse: Codable {
    let response: String
}

struct ModelsResponse: Codable {
    let models: [ModelInfo]
}

struct ModelInfo: Codable {
    let name: String
}

struct Message: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
}

enum MessageRole {
    case user
    case assistant
}

enum PlaneAnimation: CaseIterable {
    case initial, up, down
    
    var yOffset: CGFloat {
        switch self {
        case .initial: 0
        case .up: -15
        case .down: 0
        }
    }
    
    var xOffset: CGFloat {
        switch self {
        case .initial: 0
        case .up: 15
        case .down: 0
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .initial: 1
        case .up: 1.2
        case .down:  1
        }
    }
}

#Preview {
    ContentView()
}
