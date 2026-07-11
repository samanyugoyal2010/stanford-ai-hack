import Foundation
import SwiftUI
import AppKit

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let text: String
    let timestamp = Date()

    enum Role { case user, assistant, system }
}

@MainActor
final class WorkspaceModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "I’m Lunar. Ask me anything, or upload a diagram and I’ll turn its structure into a rough 3D scene.")
    ]
    @Published var draft = ""
    @Published var isThinking = false
    @Published var isRecording = false
    @Published var ollamaState = OllamaState.checking
    @Published var sceneSpec = SceneSpec.default
    @Published var selectedImage: NSImage?
    @Published var errorMessage: String?

    let ollama = OllamaClient()
    let voice = VoiceAgent()

    enum OllamaState { case checking, online(String), offline
        var label: String { switch self { case .checking: "Checking Ollama"; case .online(let model): "Gemma online · \(model)"; case .offline: "Ollama offline" } }
        var color: Color { switch self { case .online: .green; case .checking: .orange; case .offline: .red } }
    }

    func checkConnection() async {
        do { let model = try await ollama.activeModel(); ollamaState = .online(model) }
        catch { ollamaState = .offline }
    }

    func send() {
        let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isThinking else { return }
        draft = ""; messages.append(ChatMessage(role: .user, text: prompt)); isThinking = true
        Task {
            do { let response = try await ollama.chat(prompt: prompt); messages.append(ChatMessage(role: .assistant, text: response)) }
            catch { messages.append(ChatMessage(role: .system, text: "I couldn’t reach Ollama. Start it with `ollama serve`, then try again.")) }
            isThinking = false
        }
    }

    func makeScene() {
        guard selectedImage != nil else { return }
        isThinking = true
        Task {
            do {
                let spec = try await ollama.inferScene(image: selectedImage, prompt: "Analyze this diagram as a coarse 3D scene. Return JSON with objects, each having name, primitive (box, sphere, cylinder, plane), position [x,y,z], scale [x,y,z], and color hex. Prefer a simple editable approximation.")
                sceneSpec = spec
                messages.append(ChatMessage(role: .assistant, text: "I made an editable 3D draft from the diagram. You can orbit it in the preview.") )
            } catch { sceneSpec = .default; errorMessage = "The model response was not usable, so Lunar created a starter scene instead." }
            isThinking = false
        }
    }
}
