import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @ObservedObject var model: WorkspaceModel
    @State private var showImporter = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack { Text("LUNAR").font(.system(size: 16, weight: .bold, design: .rounded)); Spacer(); Circle().fill(model.ollamaState.color).frame(width: 8, height: 8); Text(model.ollamaState.label).font(.caption).foregroundStyle(.secondary) }.padding(22)
                Divider()
                ScrollView { LazyVStack(alignment: .leading, spacing: 18) { ForEach(model.messages) { message in MessageBubble(message: message) }; if model.isThinking { ProgressView().controlSize(.small).padding(.horizontal, 20) } } .padding(.vertical, 22) }
                HStack(alignment: .bottom, spacing: 10) {
                    Button { toggleVoice() } label: { Image(systemName: model.isRecording ? "mic.fill" : "mic").frame(width: 34, height: 34) }.buttonStyle(.bordered).tint(model.isRecording ? .red : .secondary).help("Hold or click to record")
                    TextField("Talk to Lunar...", text: $model.draft, axis: .vertical).textFieldStyle(.plain).lineLimit(1...4).padding(12).background(Color(nsColor: .controlBackgroundColor)).clipShape(RoundedRectangle(cornerRadius: 12)).onSubmit { model.send() }
                    Button { model.send() } label: { Image(systemName: "arrow.up").fontWeight(.bold).frame(width: 38, height: 38) }.buttonStyle(.borderedProminent).clipShape(Circle())
                }.padding(18)
            }.frame(minWidth: 440, maxWidth: 560)
            Divider()
            VStack(spacing: 0) {
                HStack { Text("SCENE WORKSPACE").font(.caption.weight(.bold)).tracking(1.4); Spacer(); Button { showImporter = true } label: { Label("Upload diagram", systemImage: "plus") }.buttonStyle(.bordered) }.padding(22)
                ScenePreview(spec: model.sceneSpec).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black.opacity(0.08))
                HStack(spacing: 14) {
                    if let image = model.selectedImage { Image(nsImage: image).resizable().scaledToFill().frame(width: 54, height: 54).clipShape(RoundedRectangle(cornerRadius: 8)); Text("Diagram ready").font(.subheadline) } else { Image(systemName: "photo.badge.plus").font(.title2); Text("Upload a diagram to build a 3D draft").font(.subheadline).foregroundStyle(.secondary) }
                    Spacer(); Button { model.makeScene() } label: { Label("Generate 3D draft", systemImage: "cube.transparent") }.buttonStyle(.borderedProminent).disabled(model.selectedImage == nil || model.isThinking)
                }.padding(18).background(.regularMaterial)
            }.frame(maxWidth: .infinity)
        }.background(Color(nsColor: .windowBackgroundColor)).task { await model.checkConnection() }.fileImporter(isPresented: $showImporter, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result { model.selectedImage = NSImage(contentsOf: url) }
        }
    }

    private func toggleVoice() {
        if model.isRecording { model.voice.stop(); model.isRecording = false; model.draft = model.voice.transcript; model.send() }
        else { try? model.voice.start(); model.isRecording = true }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var body: some View { HStack(alignment: .top, spacing: 12) { Circle().fill(message.role == .user ? Color.accentColor : Color.orange).frame(width: 28, height: 28).overlay(Image(systemName: message.role == .user ? "person.fill" : "sparkles").font(.caption).foregroundStyle(.white)); Text(message.text).font(.body).textSelection(.enabled); Spacer() }.padding(.horizontal, 20) }
}
