import Foundation
import Observation

/// Phase of the live voice tutoring loop (shown on the Dashboard).
enum VoiceAgentPhase: String, Sendable, Equatable {
    case idle = "Idle"
    case listening = "Listening"
    case thinking = "Thinking"
    case speaking = "Speaking"
}

/// Turn-taking coordinator: listen → stream Socratic Gemma → speak sentence chunks, with barge-in.
@Observable
@MainActor
final class VoiceAgentCoordinator {
    private let speech: SpeechRecognitionManager
    private let voice: VoiceOutputManager
    private let ai: GemmaService
    private let contextBuilder: ContextBuilder
    private let observation: ObservationSessionCoordinator
    private let database: SQLiteStore

    private(set) var isRunning = false
    private(set) var phase: VoiceAgentPhase = .idle
    private(set) var lastUserUtterance: String = ""
    private(set) var lastAgentReply: String = ""
    private(set) var lastError: String?

    private var loopTask: Task<Void, Never>?
    private var bargeInTask: Task<Void, Never>?
    private var generationTask: Task<Void, Never>?
    private var conversationHistory: [(role: String, text: String)] = []

    private let minUtteranceCharacters = 3
    private let maxHistoryTurns = 6

    init(
        speech: SpeechRecognitionManager,
        voice: VoiceOutputManager,
        ai: GemmaService,
        contextBuilder: ContextBuilder,
        observation: ObservationSessionCoordinator,
        database: SQLiteStore
    ) {
        self.speech = speech
        self.voice = voice
        self.ai = ai
        self.contextBuilder = contextBuilder
        self.observation = observation
        self.database = database
    }

    func start() async throws {
        guard !isRunning else { return }
        lastError = nil
        conversationHistory = []
        lastUserUtterance = ""
        lastAgentReply = ""

        try await contextBuilder.start()
        try await voice.start()
        try await ai.start()
        try await speech.start()

        isRunning = true
        phase = .listening
        AppLogger.shared.info("VoiceAgentCoordinator started", category: .app)

        loopTask = Task { [weak self] in
            await self?.runListenLoop()
        }
        bargeInTask = Task { [weak self] in
            await self?.runBargeInMonitor()
        }
    }

    func stop() async {
        isRunning = false
        generationTask?.cancel()
        generationTask = nil
        loopTask?.cancel()
        loopTask = nil
        bargeInTask?.cancel()
        bargeInTask = nil

        voice.interrupt()
        await speech.stop()
        await ai.stop()
        await voice.stop()
        await contextBuilder.stop()

        phase = .idle
        AppLogger.shared.info("VoiceAgentCoordinator stopped", category: .app)
    }

    // MARK: - Loops

    private func runListenLoop() async {
        for await transcript in speech.finalUtteranceStream {
            guard isRunning, !Task.isCancelled else { break }
            let text = transcript.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.count >= minUtteranceCharacters else { continue }

            // Ignore echo of our own last reply when possible.
            if !lastAgentReply.isEmpty, text.localizedCaseInsensitiveContains(String(lastAgentReply.prefix(24))) {
                continue
            }

            await handleUserUtterance(text)
        }
    }

    private func runBargeInMonitor() async {
        for await transcript in speech.liveTranscriptStream {
            guard isRunning, !Task.isCancelled else { break }
            guard phase == .speaking || phase == .thinking else { continue }
            let text = transcript.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let wordCount = text.split(whereSeparator: \.isWhitespace).count
            guard wordCount >= 3 else { continue }

            AppLogger.shared.debug("Barge-in detected: \(text.prefix(40))", category: .voice)
            generationTask?.cancel()
            voice.interrupt()
            phase = .listening
        }
    }

    private func handleUserUtterance(_ text: String) async {
        generationTask?.cancel()
        voice.interrupt()

        lastUserUtterance = text
        appendHistory(role: "student", text: text)
        phase = .thinking

        let recent = await speech.recentTranscripts()
        let screen = observation.latestScreenText
        let context = await contextBuilder.buildContext(screenText: screen, speech: recent)
        let ideal = try? database.loadLearnerProfile()?.ideal
        let history = conversationHistory

        generationTask = Task { [weak self] in
            await self?.streamAndSpeak(
                context: context,
                ideal: ideal,
                history: history
            )
        }
        await generationTask?.value
    }

    private func streamAndSpeak(
        context: StudyContext,
        ideal: IdealLearnerProfile?,
        history: [(role: String, text: String)]
    ) async {
        var buffer = ""
        var spoken = ""
        phase = .thinking

        do {
            let stream = ai.streamGuidance(
                context: context,
                insights: [],
                memories: [],
                conversationHistory: history,
                idealProfile: ideal
            )

            for try await chunk in stream {
                guard !Task.isCancelled, isRunning else { break }
                buffer += chunk

                while let sentence = Self.popSentence(from: &buffer) {
                    guard !Task.isCancelled, isRunning else { return }
                    phase = .speaking
                    spoken += (spoken.isEmpty ? "" : " ") + sentence
                    lastAgentReply = spoken
                    try await voice.speak(sentence)
                    if Task.isCancelled || !isRunning { return }
                }
            }

            let remainder = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !remainder.isEmpty, !Task.isCancelled, isRunning {
                phase = .speaking
                spoken += (spoken.isEmpty ? "" : " ") + remainder
                lastAgentReply = spoken
                try await voice.speak(remainder)
            }

            if !spoken.isEmpty {
                appendHistory(role: "coach", text: spoken)
            }
        } catch is CancellationError {
            // Barge-in or stop.
        } catch {
            lastError = error.localizedDescription
            AppLogger.shared.error("Voice agent generation failed: \(error.localizedDescription)", category: .ai)
        }

        if isRunning {
            phase = .listening
        }
    }

    private func appendHistory(role: String, text: String) {
        conversationHistory.append((role: role, text: text))
        if conversationHistory.count > maxHistoryTurns {
            conversationHistory.removeFirst(conversationHistory.count - maxHistoryTurns)
        }
    }

    /// Pulls the next complete sentence from a streaming buffer.
    private static func popSentence(from buffer: inout String) -> String? {
        guard let idx = buffer.firstIndex(where: { ".!?".contains($0) }) else {
            return nil
        }
        let end = buffer.index(after: idx)
        let sentence = String(buffer[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        buffer = String(buffer[end...])
        return sentence.isEmpty ? nil : sentence
    }
}
