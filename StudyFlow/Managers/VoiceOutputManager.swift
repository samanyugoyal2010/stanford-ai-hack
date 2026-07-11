import AVFoundation
import Foundation
import Observation

/// Speaks AI guidance with AVSpeechSynthesizer and supports barge-in interrupt.
@Observable
@MainActor
final class VoiceOutputManager: NSObject, VoiceSpeaking {
    private(set) var status: ServiceStatus = .notStarted
    private(set) var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var speakContinuation: CheckedContinuation<Void, Error>?
    private var preferredVoice: AVSpeechSynthesisVoice?

    override init() {
        super.init()
        synthesizer.delegate = self
        preferredVoice = Self.pickVoice()
    }

    func start() async throws {
        status = .idle
        AppLogger.shared.info("VoiceOutputManager started", category: .voice)
    }

    func stop() async {
        interrupt()
        status = .stopped
        AppLogger.shared.info("VoiceOutputManager stopped", category: .voice)
    }

    func speak(_ text: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Finish any in-flight speak await before starting a new utterance.
        if let pending = speakContinuation {
            speakContinuation = nil
            pending.resume()
        }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = preferredVoice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.08
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0

        status = .running
        isSpeaking = true

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            speakContinuation = cont
            synthesizer.speak(utterance)
        }
    }

    func interrupt() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        finishSpeak()
    }

    private func finishSpeak() {
        isSpeaking = false
        if status == .running {
            status = .idle
        }
        guard let cont = speakContinuation else { return }
        speakContinuation = nil
        cont.resume()
    }

    private static func pickVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        if let enhanced = voices.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        return AVSpeechSynthesisVoice(language: "en-US") ?? voices.first
    }
}

extension VoiceOutputManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.finishSpeak()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.finishSpeak()
        }
    }
}
