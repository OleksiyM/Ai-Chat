import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let settings: AppSettings
    let onSave: (AppSettings) -> Void
    
    @State private var ollamaHost: String
    @State private var fontSize: Int
    
    init(settings: AppSettings, onSave: @escaping (AppSettings) -> Void) {
        self.settings = settings
        self.onSave = onSave
        _ollamaHost = State(initialValue: settings.ollamaHost)
        _fontSize = State(initialValue: settings.fontSize)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                ScrollView {
                    Form {
                        Section(header: Text("Server").font(.headline)) {
                            TextField("Ollama Host", text: $ollamaHost)
                                .textFieldStyle(.roundedBorder)
                                .padding(.vertical, 4)
                        }
                        
                        Section(header: Text("Appearance").font(.headline)) {
                            Stepper("Font Size: \(fontSize)pt", value: $fontSize, in: 8...24)
                                .padding(.vertical, 4)
                        }
                    }
                    .formStyle(.grouped)
                }
                .scrollIndicators(.visible)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.bordered)
                
                Button("Save") {
                    onSave(AppSettings(ollamaHost: ollamaHost, fontSize: fontSize))
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 370)
    }
}

#Preview {
    SettingsView(settings: AppSettings.default) { _ in }
}
