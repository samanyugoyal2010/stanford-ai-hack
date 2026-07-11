import AVFoundation
import Foundation
import Observation
import Speech

enum SpeechRecognitionError: Error, LocalizedError {
    case recognizerUnavailable
    case notAuthorized
    case engineFailed(String)

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is unavailable on this Mac."
        case .notAuthorized:
            return "Microphone or Speech Recognition permission was denied."
        case .engineFailed(let detail):
            return "Speech audio engine failed: \(detail)"
        }
    }
}

/// Live Apple Speech recognition with rolling transcripts and utterance streams.
@Observable
@MainActor
final class SpeechRecognitionManager: SpeechRecognizing {
    private(set) var status: ServiceStatus = .notStarted
    private var transcripts: [SpeechTranscript] = []

    private let audioConfigurator: AudioCaptureConfigurator
    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var isRunning = false

    private let finalStreamBox: StreamBox
    private let liveStreamBox: StreamBox

    var finalUtteranceStream: AsyncStream<SpeechTranscript> { finalStreamBox.stream }
    var liveTranscriptStream: AsyncStream<SpeechTranscript> { liveStreamBox.stream }

    private let maxTranscripts = 40

    init(audioConfigurator: AudioCaptureConfigurator = AudioCaptureConfigurator()) {
        self.audioConfigurator = audioConfigurator
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.finalStreamBox = StreamBox()
        self.liveStreamBox = StreamBox()
    }

    func start() async throws {
        guard !isRunning else { return }
        try await requestPermissions()
        _ = try await audioConfigurator.prepareSession()

        guard let recognizer, recognizer.isAvailable else {
            status = .failed("Speech recognizer unavailable")
            throw SpeechRecognitionError.recognizerUnavailable
        }

        transcripts = []
        try startRecognition(recognizer: recognizer)
        isRunning = true
        status = .running
        AppLogger.shared.info("SpeechRecognitionManager started", category: .speech)
    }

    func stop() async {
        isRunning = false
        stopRecognitionEngine()
        await audioConfigurator.tearDown()
        status = .stopped
        AppLogger.shared.info("SpeechRecognitionManager stopped", category: .speech)
    }

    func recentTranscripts() async -> [SpeechTranscript] {
        transcripts
    }

    // MARK: - Private

    private func requestPermissions() async throws {
        let speechStatus = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            throw SpeechRecognitionError.notAuthorized
        }

        let micGranted = await AVCaptureDevice.requestAccess(for: .audio)
        guard micGranted else {
            throw SpeechRecognitionError.notAuthorized
        }
    }

    private func startRecognition(recognizer: SFSpeechRecognizer) throws {
        stopRecognitionEngine()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        if #available(macOS 13.0, *) {
            request.addsPunctuation = true
        }
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            throw SpeechRecognitionError.engineFailed(error.localizedDescription)
        }

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognition(result: result, error: error)
            }
        }
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            let text = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty || result.isFinal else { return }

            if !text.isEmpty {
                let transcript = SpeechTranscript(
                    text: text,
                    isFinal: result.isFinal,
                    confidence: result.bestTranscription.segments.last?.confidence
                )
                appendTranscript(transcript)
                liveStreamBox.yield(transcript)

                if result.isFinal {
                    finalStreamBox.yield(transcript)
                }
            }

            if result.isFinal {
                restartRecognitionIfNeeded()
                return
            }
        }

        if error != nil, isRunning {
            AppLogger.shared.debug(
                "Speech recognition hiccup: \(error!.localizedDescription) — restarting",
                category: .speech
            )
            restartRecognitionIfNeeded()
        }
    }

    private func restartRecognitionIfNeeded() {
        guard isRunning, let recognizer else { return }
        try? startRecognition(recognizer: recognizer)
    }

    private func appendTranscript(_ transcript: SpeechTranscript) {
        if !transcript.isFinal, let last = transcripts.last, !last.isFinal {
            transcripts[transcripts.count - 1] = transcript
        } else {
            transcripts.append(transcript)
        }
        if transcripts.count > maxTranscripts {
            transcripts.removeFirst(transcripts.count - maxTranscripts)
        }
    }

    private func stopRecognitionEngine() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}

/// Holds an AsyncStream + continuation so consumers can subscribe before `start()`.
@MainActor
private final class StreamBox {
    let stream: AsyncStream<SpeechTranscript>
    private var continuation: AsyncStream<SpeechTranscript>.Continuation?

    init() {
        var cont: AsyncStream<SpeechTranscript>.Continuation?
        stream = AsyncStream { continuation in
            cont = continuation
        }
        continuation = cont
    }

    func yield(_ value: SpeechTranscript) {
        continuation?.yield(value)
    }
}
