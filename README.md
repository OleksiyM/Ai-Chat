# tAIChat

A blazing-fast macOS chat application that seamlessly integrates with Ollama for local AI model interactions. Built with SwiftUI, tAIChat combines powerful features with an elegant, native macOS experience.

## Features

### 🌓 Adaptive Theme
- Automatically adapts to your system's appearance (light/dark mode)
- Native macOS design language for a seamless experience

### 🎙️ Voice Integration
- Voice-to-text transcription using built-in macOS dictation
- Text-to-speech capability for AI responses using system voices

### ⚡️ Performance
- Streaming responses for instant feedback
- Efficient message handling and storage
- Smooth scrolling and animations

### 💬 Chat Management
- Create multiple chat sessions
- Choose from available Ollama models
- Rename and delete conversations
- Persistent chat history

### ⚙️ Customization
- Adjustable font size
- Configurable Ollama host settings
- Keyboard shortcuts for common actions

## Requirements

- macOS (Latest version recommended)
- [Ollama](https://ollama.ai) installed and running locally
- Available AI models pulled through Ollama

## Installation

1. Download the latest release
2. Move tAIChat to your Applications folder
3. Ensure Ollama is installed and running (`http://127.0.0.1:11434` by default)
4. Launch tAIChat

## Usage

### Getting Started
1. Launch the application
2. Click the "New Chat" button
3. Select an AI model from the available options
4. Start chatting!

### Voice Features
- Click the microphone icon or use system dictation shortcut to transcribe voice to text
- Use the context menu on any message to have it read aloud

### Keyboard Shortcuts
- `⌘ + ,` - Open Settings
- `⇧ + ↵` - Add new line in message
- `↵` - Send message

### Chat Management
- Right-click on any chat in the sidebar to rename or delete
- Messages are automatically saved and persisted between sessions

## Technical Details

### Architecture
- Built with SwiftUI and modern Swift concurrency
- MVVM architecture for clean separation of concerns
- Efficient state management using @StateObject and @Published

### Data Flow
- Streaming response handling for real-time updates
- Persistent storage using UserDefaults for settings and chat history
- Asynchronous network operations for smooth UI experience

### Security
- Sandboxed application
- Network access limited to client operations
- Read-only access to user-selected files

## Planned Features

### 🎨 Enhanced Formatting
- Rich text editing in chat messages
- Markdown support for message formatting
- Code block syntax highlighting
- LaTeX math equation rendering

### 🎯 Model Fine-tuning
- Adjustable temperature and top-p parameters
- Custom system prompts configuration
- Context window size control
- Token limit customization

### 🚀 Advanced Features
- File attachment support
- Chat export functionality
- Conversation branching
- Custom model hosting integration
- Chat templates and saved prompts

## Support

For issues, questions, or contributions, please visit the project repository.

## License

This project is available under the MIT License. See the LICENSE file for more info.