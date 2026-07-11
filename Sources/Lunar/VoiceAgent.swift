import Foundation
import AVFoundation

@MainActor
final class VoiceAgent: NSObject, ObservableObject {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    @Published var transcript = ""

    func start() throws {
        SFSpeechRecognizer.requestAuthorization { _ in }
        transcript = ""; request = SFSpeechAudioBufferRecognitionRequest(); guard let request else { return }
        let input = audioEngine.inputNode; input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in request.append(buffer) }
        audioEngine.prepare(); try audioEngine.start(); task = recognizer?.recognitionTask(with: request) { [weak self] result, _ in self?.transcript = result?.bestTranscription.formattedString ?? "" }
    }
    func stop() { audioEngine.stop(); audioEngine.inputNode.removeTap(onBus: 0); request?.endAudio(); task?.cancel() }
}
