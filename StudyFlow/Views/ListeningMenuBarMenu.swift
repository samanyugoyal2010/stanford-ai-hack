import SwiftUI

/// Compact menu attached to the listening-mode menu-bar icon.
struct ListeningMenuBarMenu: View {
    var container: AppDependencyContainer

    private var phase: VoiceAgentPhase {
        container.voiceAgent.phase
    }

    private var lastReply: String {
        container.voiceAgent.lastAgentReply
    }

    var body: some View {
        Group {
            Text(phase.rawValue)
            if !lastReply.isEmpty {
                Text(lastReply)
                    .lineLimit(2)
            }
            Divider()
            Button("Open StudyFlow") {
                container.sessionChrome.openMainWindow()
            }
            Button("Stop Listening") {
                Task {
                    await container.sessionChrome.stopListeningSession(
                        voiceAgent: container.voiceAgent,
                        observation: container.observationCoordinator
                    )
                }
            }
        }
        .onAppear {
            container.sessionChrome.openMainWindow()
        }
    }
}

enum ListeningMenuBarSymbol {
    static func systemName(for phase: VoiceAgentPhase) -> String {
        switch phase {
        case .idle:
            return "ear"
        case .listening:
            return "waveform"
        case .thinking:
            return "ellipsis.bubble"
        case .speaking:
            return "speaker.wave.2"
        }
    }
}
