import SwiftUI

struct ModelSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var selectedModel: String?
    @AppStorage("settings") private var settingsData: Data = try! JSONEncoder().encode(AppSettings.default)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create new Chat")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Available Models")
                    .font(.headline)
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.availableModels, id: \.self) { model in
                            HStack(spacing: 12) {
                                Image(systemName: "cube")
                                    .frame(width: 24)
                                    .foregroundColor(.secondary)
                                
                                Text(model)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedModel == model {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedModel == model ? Color.accentColor.opacity(0.1) : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedModel = model
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                
                Button("Create") {
                    if let model = selectedModel {
                        viewModel.createNewChat(model: model)
                        dismiss()
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(selectedModel == nil)
            }
        }
        .padding()
        .frame(width: 400)
        .fixedSize(horizontal: true, vertical: true)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

#Preview {
    ModelSelectionView()
        .environmentObject(ChatViewModel(settings: AppSettings.default))
}