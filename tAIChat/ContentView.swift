//
//  ContentView.swift
//  tAIChat
//
//  Created by Alex Malovanyy on 08.02.2025.
//

import SwiftUI
import AVFoundation

// MARK: - Models
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

struct Chat: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    let model: String
    let timestamp: Date
    
    init(title: String = "New Chat", model: String) {
        self.id = UUID()
        self.title = title
        self.messages = []
        self.model = model
        self.timestamp = Date()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }
}

struct AppSettings: Codable {
    var ollamaHost: String
    var fontSize: Int
    
    static let `default` = AppSettings(
        ollamaHost: "http://127.0.0.1:11434",
        fontSize: 13
    )
}

// MARK: - View Models
@MainActor
class ChatViewModel: ObservableObject {
    func updateSettings(_ newSettings: AppSettings) {
        self.settings = newSettings
        Task {
            await loadAvailableModels()
        }
    }
    @Published var chats: [Chat] = []
    @Published var selectedChat: Chat?
    @Published var availableModels: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var streamingResponse = ""
    
    private var settings: AppSettings
    private var streamTask: Task<Void, Never>?
    
    init(settings: AppSettings) {
        self.settings = settings
        Task {
            await loadAvailableModels()
            await loadSavedChats()
        }
    }
    
    func loadAvailableModels() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URL(string: "\(settings.ollamaHost)/api/tags")
            guard let url = url else { throw URLError(.badURL) }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
            availableModels = response.models.map { $0.name }
        } catch {
            errorMessage = "Failed to load models: \(error.localizedDescription)"
        }
    }
    
    private struct ModelsResponse: Codable {
        let models: [Model]
        
        struct Model: Codable {
            let name: String
        }
    }
    
    func createNewChat(model: String) {
        let newChat = Chat(model: model)
        chats.insert(newChat, at: 0)
        selectedChat = newChat
        saveChats()
    }
    
    private struct StreamResponse: Codable {
        let response: String
        let done: Bool
    }

    func sendMessage(_ content: String, in chat: Chat) async {
        guard var currentChat = chats.first(where: { chat.id == $0.id }) else { return }
        
        let userMessage = ChatMessage(content: content, isUser: true)
        currentChat.messages.append(userMessage)
        updateChat(currentChat)
        
        do {
            let url = URL(string: "\(settings.ollamaHost)/api/generate")
            guard let url = url else { throw URLError(.badURL) }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload: [String: Any] = [
                "model": chat.model,
                "prompt": content,
                "stream": true
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            streamingResponse = ""
            let (bytes, _) = try await URLSession.shared.bytes(for: request)
            
            streamTask = Task<Void, Never> {
                do {
                    var assistantMessage = ""
                    
                    for try await line in bytes.lines {
                        guard !Task.isCancelled else { break }
                        
                        if let data = line.data(using: .utf8),
                           let response = try? JSONDecoder().decode(StreamResponse.self, from: data) {
                            assistantMessage += response.response
                            streamingResponse = assistantMessage
                            
                            if response.done {
                                let message = ChatMessage(content: assistantMessage, isUser: false)
                                currentChat.messages.append(message)
                                updateChat(currentChat)
                                streamingResponse = ""
                            }
                        }
                    }
                } catch {
                    errorMessage = "Failed to process stream: \(error.localizedDescription)"
                }
            }
            
            await streamTask?.value
            
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
    }
    
    private func updateChat(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
            selectedChat = chat
            saveChats()
        }
    }
    
    private func loadSavedChats() async {
        if let data = UserDefaults.standard.data(forKey: "chats"),
           let savedChats = try? JSONDecoder().decode([Chat].self, from: data) {
            chats = savedChats
            selectedChat = chats.first
        }
    }
    
    private func saveChats() {
        if let encoded = try? JSONEncoder().encode(chats) {
            UserDefaults.standard.set(encoded, forKey: "chats")
        }
    }
    
    func deleteChat(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats.remove(at: index)
            if selectedChat?.id == chat.id {
                selectedChat = chats.first
            }
            saveChats()
        }
    }
    
    func renameChat(_ chat: Chat, newTitle: String) {
        if var chat = chats.first(where: { $0.id == chat.id }) {
            chat.title = newTitle
            updateChat(chat)
        }
    }
}

// MARK: - Views
struct ContentView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showModelSelection = true
    @AppStorage("settings") private var settingsData: Data = try! JSONEncoder().encode(AppSettings.default)
    
    @State private var chatToRename: Chat?
    @State private var newChatTitle = ""
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationSplitView {
            List(viewModel.chats, selection: $viewModel.selectedChat) { chat in
                NavigationLink(value: chat) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chat.title)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(chat.model)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    //.padding(.vertical, 4)
                    //.padding(.horizontal, 2)
                }
                .contextMenu {
                    Button(action: {
                        chatToRename = chat
                        newChatTitle = chat.title
                    }) {
                        Label("Rename", systemImage: "pencil")
                            .labelStyle(.titleAndIcon)
                    }
                    
                    Button(role: .destructive) {
                        chatToRename = chat
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button(action: { showModelSelection.toggle() }) {
                        Label("New Chat", systemImage: "square.and.pencil")
                            .foregroundColor(.primary)
                    }
                    .disabled(viewModel.availableModels.isEmpty)
                }
                
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: { showSettings.toggle() }) {
                        Label("Settings", systemImage: "gear")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onChange(of: viewModel.selectedChat) { oldChat, newChat in
                if let chat = newChat {
                    if let savedData = UserDefaults.standard.data(forKey: "chats"),
                       let savedChats = try? JSONDecoder().decode([Chat].self, from: savedData),
                       let savedChat = savedChats.first(where: { $0.id == chat.id }) {
                        viewModel.selectedChat = savedChat
                    }
                }
            }
        } detail: {
            if let selectedChat = viewModel.selectedChat {
                ChatView(chat: selectedChat)
            } else {
                Text("Select or create a chat")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: try! JSONDecoder().decode(AppSettings.self, from: settingsData)) { newSettings in
                if let encoded = try? JSONEncoder().encode(newSettings) {
                    settingsData = encoded
                    viewModel.updateSettings(newSettings)
                }
            }
        }
        .sheet(isPresented: $showModelSelection) {
            ModelSelectionView()
                .environmentObject(viewModel)
        }
        .alert("Rename Chat", isPresented: .init(
            get: { chatToRename != nil && !showDeleteConfirmation },
            set: { if !$0 { chatToRename = nil } }
        ), presenting: chatToRename) { chat in
            TextField("Chat Title", text: $newChatTitle)
            Button("Save") {
                viewModel.renameChat(chat, newTitle: newChatTitle)
                chatToRename = nil
            }
            Button("Cancel", role: .cancel) {
                chatToRename = nil
            }
        } message: { _ in
            Text("Enter a new title for this chat")
        }
        .alert("Delete Chat", isPresented: $showDeleteConfirmation, presenting: chatToRename) { chat in
            Button("Delete", role: .destructive) {
                viewModel.deleteChat(chat)
                chatToRename = nil
            }
            Button("Cancel", role: .cancel) {
                chatToRename = nil
            }
        } message: { chat in
            Text("Are you sure you want to delete '\(chat.title)'? This action cannot be undone.")
        }
        .onAppear {
            if let settings = try? JSONDecoder().decode(AppSettings.self, from: settingsData) {
                viewModel.updateSettings(settings)
            }
        }
    }
}

struct ChatView: View {
    let chat: Chat
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if let chat = viewModel.selectedChat {
                            ForEach(chat.messages) { message in
                                MessageView(message: message)
                                    .id(message.id)
                            }
                            
                            if !viewModel.streamingResponse.isEmpty {
                                MessageView(message: ChatMessage(content: viewModel.streamingResponse, isUser: false))
                                    .id("streaming")
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentMargins(.top, 20, for: .scrollContent)
                    .contentMargins(.bottom, 20, for: .scrollContent)
                    .onChange(of: viewModel.selectedChat?.messages.count) { oldCount, newCount in
                        if let lastMessage = viewModel.selectedChat?.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.streamingResponse) { oldResponse, newResponse in
                        if !viewModel.streamingResponse.isEmpty {
                            withAnimation {
                                proxy.scrollTo("streaming", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            HStack {
                TextEditor(text: $messageText)
                    .font(.system(size: CGFloat(try! JSONDecoder().decode(AppSettings.self, from: UserDefaults.standard.data(forKey: "settings") ?? Data()).fontSize)))
                    .frame(height: min(100, max(36, CGFloat(messageText.components(separatedBy: "\n").count * 20))))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    .onSubmit {
                        if !messageText.isEmpty {
                            sendMessage()
                        }
                    }
                    .onKeyPress(.return) {
                        if NSEvent.modifierFlags.contains(.shift) {
                            messageText.append("\n")
                            return .handled
                        }
                        if !messageText.isEmpty {
                            sendMessage()
                            return .handled
                        }
                        return .ignored
                    }
                
                Button(action: startDictation) {
                    Image(systemName: "mic.circle.fill")
                        .font(.title)
                        .imageScale(.large)
                        .foregroundColor(.blue)
                }
                .help("Start Dictation")
                
                Button(action: sendMessage) {
                    Image(systemName: viewModel.streamingResponse.isEmpty ? "arrow.up.circle.fill" : "stop.circle.fill")
                        .font(.title)
                        .imageScale(.large)
                }
                .disabled(messageText.isEmpty || !viewModel.streamingResponse.isEmpty)
            }
            .padding()
        }
    }
    
    func sendMessage() {
        guard let chat = viewModel.selectedChat else { return }
        let text = messageText
        messageText = ""
        
        Task {
            await viewModel.sendMessage(text, in: chat)
        }
    }
    
    func startDictation() {
        NSApp.sendAction(Selector(("startDictation:")), to: nil, from: nil)
    }
}

struct MarkdownText: View {
    let text: String
    let fontSize: CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct MessageView: View {
    let message: ChatMessage
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                Image(systemName: "brain")
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            
            let fontSize = CGFloat(try! JSONDecoder().decode(AppSettings.self, from: UserDefaults.standard.data(forKey: "settings") ?? Data()).fontSize)
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                MarkdownText(text: message.content, fontSize: fontSize)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isUser ? Color.blue.opacity(0.15) : Color(.windowBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            .contextMenu {
                Menu {
                    Button(action: {
                        let utterance = AVSpeechUtterance(string: message.content)
                        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                        speechSynthesizer.speak(utterance)
                    }) {
                        Label("Start Speaking", systemImage: "speaker.wave.2")
                            .labelStyle(.titleAndIcon)
                    }
                    
                    Button(action: {
                        speechSynthesizer.stopSpeaking(at: .immediate)
                    }) {
                        Label("Stop Speaking", systemImage: "speaker.slash")
                            .labelStyle(.titleAndIcon)
                    }
                } label: {
                    Label("Speech", systemImage: "waveform")
                        .labelStyle(.titleAndIcon)
                }
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message.content, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .labelStyle(.titleAndIcon)
                }
                .keyboardShortcut("c", modifiers: .command)
            }
            
            if message.isUser {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
            } else {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
    }
}

struct MessageInputView: View {
    @State private var messageText = ""
    
    var body: some View {
        HStack {
            TextField("Type your message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(messageText.isEmpty)
        }
        .padding()
    }
    
    private func sendMessage() {
        // TODO: Implement message sending
        messageText = ""
    }
}
